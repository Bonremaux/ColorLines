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

    func anim(start: Seconds) -> Anim {
        switch self {
            case empty: return Anim(start: start, duration: 0)
            case next: return Anim(start: start, duration: 1)
            case normal: return Anim(start: start, duration: 1)
            case spawning: return Anim(start: start, duration: 0.5)
            case clearing: return Anim(start: start, duration: 0.3)
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

class AppView {
    private let _board: BoardView
    private let _background: SpriteView
    private let _score: ScoreView

    init() {
        let boxSize = Vector(50, 50)
        let boardFrameSize = Vector(30, 30)
        let gridSize = Cell(9, 9)
        _board = BoardView(pos: boardFrameSize, boxSize: boxSize)
        let rect = Rect(size: gridSize.toVector(cellSize: boxSize) + boardFrameSize * 2)
        _background = SpriteView(spriteName: "board.png", rect: rect)
        _score = ScoreView(canvas: canvas, rect: Rect(pos: Vector(500, 50), size: Vector(150, 500)))
    }

    func render(to canvas: Canvas, time: Seconds) {
        _background.render(to: canvas, time: time)
        _board.render(to: canvas, time: time)
        _score.render(to: canvas, time: time)
    }

    func translate(_ event: Event) -> Action? {
        switch event {
        case Event.quit:
            return Action.quit
        case .key(.pressed, SDLK_q):
            return Action.quit
        default:
            return _board.translate(event)
        }
    }

    func apply(_ message: Message, time: Seconds) {
        _board.apply(message, time: time)
    }
}

class ScoreView {
    private let _rect: Rect
    private let _scoreNumber: NumberCache

    init(canvas: Canvas, rect: Rect) {
        _rect = rect
        _scoreNumber = canvas.createNumberCache(color: Color.yellow)
    }

    func render(to canvas: Canvas, time: Seconds) {
        _scoreNumber.draw(to: canvas, at: _rect.position, numberString: String(123))
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
                if let selected = _selected where selected == cell {
                    canvas.setColor(Color(0, 255, 0, 50))
                    canvas.drawRect(dest: cell.bounds(cellSize: _boxSize).moved(by: _pos))
                }
                canvas.drawTexture(name: box.type.spriteName, dest: cell.bounds(cellSize: _boxSize).moved(by: _pos))
            case .clearing:
                let f = 1.0 - box.anim.pos(time)
                let bounds = cell.bounds(cellSize: _boxSize)
                let rect = bounds.scaled(Vector(f, 1)).centered(relativelyTo: bounds)
                canvas.drawTexture(name: box.type.spriteName, dest: rect.moved(by: _pos))
            }
        }
    }

    func translate(_ event: Event) -> Action? {
        switch event {
        case Event.initialize:
            return Action.start
        case let Event.button(.pressed, .left, _pos):
            let cell = windowToView(_pos).toCell(cellSize: _boxSize)
            guard _grid.isValidCell(cell) else {
                return nil
            }
            if !_grid[cell].isEmpty {
                _selected = cell
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

    func apply(_ message: Message, time: Seconds) {
        switch message {
        case let Message.spawned(balls):
            for (cell, type) in balls {
                _grid[cell].type = type
                _grid[cell].setState(.spawning, time, next: .normal)
            }
        case let Message.moved(from: src, to: dest):
            _grid[dest] = _grid[src]
            _grid[src].setState(.empty, time, next: nil)
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
