import CSDL2

struct Anim {
    let start: Seconds
    let duration: Seconds

    init(start: Seconds, duration: Seconds) {
        self.start = start
        self.duration = duration
    }

    func pos(_ time: Seconds) -> Float {
        let elapsed = time - start
        return Float(elapsed / duration)
    }
}

enum BallState {
    case empty
    case next
    case normal
    case spawning
    case clearing
    case selected

    func anim(start: Seconds) -> Anim {
        switch self {
            case empty: return Anim(start: start, duration: 0)
            case next: return Anim(start: start, duration: 1)
            case normal: return Anim(start: start, duration: 1)
            case spawning: return Anim(start: start, duration: 0.5)
            case clearing: return Anim(start: start, duration: 0.3)
            case selected: return Anim(start: start, duration: 1.0)
        }
    }
}

struct Box {
    var type: BallType = .blue
    var state: BallState = .empty
    var nextState: BallState? = nil
    var anim: Anim = Anim(start: 0, duration: 0)

    mutating func setState(_ newState: BallState, _ time: Seconds, next: BallState?) {
        state = newState
        anim = newState.anim(start: time)
        nextState = next
    }

    mutating func update(time: Seconds) {
        if anim.pos(time) > 1.0 {
            if let next = nextState {
                state = next
                nextState = nil
                anim = state.anim(start: time)
            }
            else {
                anim = Anim(start: time, duration: anim.duration)
            }
        }
    }

    var isEmpty: Bool {
        return state != .normal && state != .spawning
    }
}

extension BallType {
    var spriteName: String {
        return self.toString + ".png"
    }
}

class GameView {
    private let _board: BoardView
    private let _background: SpriteView
    private let _score: TextView

    init(canvas: Canvas) {
        let boxSize = Vector(50, 50)
        let boardFrameSize = Vector(30, 30)
        let gridSize = Cell(9, 9)
        _board = BoardView(pos: boardFrameSize + Vector(0, 0), boxSize: boxSize)
        let rect = Rect(size: gridSize.toVector(cellSize: boxSize) + boardFrameSize * 2 + Vector(0, 50))
        _background = SpriteView(spriteName: "board.png", rect: rect)
        let font = canvas.loadFont(family: "GoodDog.otf", size: 50, color: Color(100, 100, 150))
        _score = TextView(font: font, str: "", pos: Vector(215, 489))
    }

    func render(to canvas: Canvas, time: Seconds) {
        _background.render(to: canvas, time: time)
        _board.render(to: canvas, time: time)
        _score.render(to: canvas, time: time)
    }

    func translate(_ event: Event, time: Seconds) -> Action? {
        switch event {
        case Event.quit:
            return Action.quit
        case .key(.pressed, SDLK_q):
            return Action.quit
        default:
            return _board.translate(event, time: time)
        }
    }

    func apply(_ message: Message, time: Seconds, play: (String) -> ()) {
        switch message {
        case let Message.scored(score):
            _score.setString(String(score))
        case Message.cleared:
            play("clear.wav")
        default:
            break
        }
        _board.apply(message, time: time)
    }
}

class TextView {
    private let _pos: Vector
    private let _font: Font
    private var _str: String

    init(font: Font, str: String, pos: Vector) {
        _pos = pos
        _font = font
        _str = str
    }

    func render(to canvas: Canvas, time: Seconds) {
        canvas.drawText(font: _font, str: _str, pos: _pos)
    }

    func setString(_ str: String) {
        _str = str
    }
}

class BoardView {
    private var _grid: Grid<Box>
    private let _pos: Vector
    private let _boxSize: Vector
    private var _selected: Cell? = nil

    init(pos: Vector, boxSize: Vector) {
        _grid = Grid<Box>(size: Cell(9, 9), filling: Box())
        _pos = pos
        _boxSize = boxSize
    }

    func render(to canvas: Canvas, time: Seconds) {
        for (cell, _) in _grid.enumerated() {
            _grid[cell].update(time: time)
            let box = _grid[cell]
            switch box.state {
            case .empty:
                break
            case .next:
                let rect = cell.bounds(cellSize: _boxSize)
                let smallRect = rect.scaled(1/3).centered(relativelyTo: rect)
                canvas.drawTexture(name: box.type.toString + ".png", dest: smallRect.moved(by: _pos))
            case .spawning:
                let f = box.anim.pos(time) * 0.7 + 0.3
                let bounds = cell.bounds(cellSize: _boxSize)
                let rect = bounds.scaled(f).centered(relativelyTo: bounds)
                canvas.drawTexture(name: box.type.spriteName, dest: rect.moved(by: _pos))
            case .normal:
                canvas.drawTexture(name: box.type.spriteName, dest: cell.bounds(cellSize: _boxSize).moved(by: _pos))
            case .clearing:
                let f = 1.0 - box.anim.pos(time)
                let bounds = cell.bounds(cellSize: _boxSize)
                let rect = bounds.scaled(Vector(f, 1)).centered(relativelyTo: bounds)
                canvas.drawTexture(name: box.type.spriteName, dest: rect.moved(by: _pos))
            case .selected:
                let f = box.anim.pos(time)
                let offset = (Float(sin(Double(f * 2 * Float.pi))) + 1) / 2 * 10
                let rect = cell.bounds(cellSize: _boxSize).moved(by: _pos - Vector(0, offset))
                canvas.drawTexture(name: box.type.spriteName, dest: rect)
            }
        }
    }

    func translate(_ event: Event, time: Seconds) -> Action? {
        switch event {
        case Event.initialize:
            return Action.start
        case let Event.button(.pressed, .left, _pos):
            let cell = windowToView(_pos).toCell(cellSize: _boxSize)
            guard _grid.isValidCell(cell) else {
                return nil
            }
            if !_grid[cell].isEmpty {
                select(cell, time)
            }
            else {
                if let src = _selected {
                    return Action.move(from: src, to: cell)
                }
            }
        default:
            return nil
        }
        return nil
    }

    func select(_ cell: Cell?, _ time: Seconds) {
        if let old = _selected {
            _grid[old].setState(.normal, time, next: nil)
        }
        if let new = cell {
            _selected = new
            _grid[new].setState(.selected, time, next: nil)
        }
    }

    func apply(_ message: Message, time: Seconds) {
        switch message {
        case let Message.spawned(balls):
            for (cell, type) in balls {
                _grid[cell].type = type
                _grid[cell].setState(.spawning, time, next: .normal)
            }
        case let Message.moved(from: src, to: dest):
            _grid[dest] = _grid[src]
            _grid[dest].setState(.normal, time, next: nil)
            _grid[src].setState(.empty, time, next: nil)
            _selected = nil
        case let Message.cleared(lines):
            for line in lines {
                for cell in line {
                    _grid[cell].setState(.clearing, time, next: .empty)
                }
            }
        case let Message.next(balls):
            for (cell, box) in _grid.enumerated() {
                if box.state == .next {
                    _grid[cell].state = .empty
                }
            }
            for (cell, type) in balls {
                _grid[cell].type = type
                _grid[cell].setState(.next, time, next: nil)
            }
        default:
            break
        }
    }

    func windowToView(_ pos: Vector) -> Vector {
        return pos - _pos
    }
}

class SpriteView {
    private let _rect: Rect
    private let _spriteName: String

    init(spriteName: String, rect: Rect) {
        _rect = rect
        _spriteName = spriteName
    }

    func render(to canvas: Canvas, time: Seconds) {
        canvas.drawTexture(name: _spriteName, dest: _rect)
    }

    func translate(event: Event) -> Action? {
        return nil
    }
}
