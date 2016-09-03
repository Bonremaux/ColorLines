import CSDL2

struct Anim {
    let start: Seconds
    let duration: Seconds

    init(start: Seconds, duration: Seconds) {
        self.start = start
        self.duration = duration
    }

    func pos(_ now: Seconds) -> Float {
        let diff = now - start
        return min(Float(diff / duration), 1.0)
    }
}

enum BallState {
    case empty
    case normal
    case spawning
    case clearing
    case selected

    func anim(start: Seconds) -> Anim {
        switch self {
            case empty: return Anim(start: start, duration: 0)
            case normal: return Anim(start: start, duration: 1)
            case spawning: return Anim(start: start, duration: 0.5)
            case clearing: return Anim(start: start, duration: 0.3)
            case selected: return Anim(start: start, duration: 1.0)
        }
    }
}

enum TraceState {
    case highlighted
    case fading
}

struct Box {
    var type: BallType = .blue
    var state: BallState = .empty
    var nextState: BallState? = nil
    var anim: Anim = Anim(start: 0, duration: 0)
    var traceAnim: Anim? = nil
    var traceState: TraceState = .highlighted

    mutating func setState(_ newState: BallState, _ time: Seconds, next: BallState?) {
        state = newState
        anim = newState.anim(start: time)
        nextState = next
    }

    mutating func update(time: Seconds) {
        if anim.pos(time) >= 1.0 {
            if let next = nextState {
                state = next
                nextState = nil
                anim = state.anim(start: time)
            }
            else {
                anim = Anim(start: time, duration: anim.duration)
            }
        }

        if let anim = traceAnim {
            if anim.pos(time) >= 1.0 {
                traceAnim = nil
            }
        }
    }

    var isEmpty: Bool {
        return state != .normal && state != .spawning && state != .selected // TODO remove me
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
    private var _nextBalls: [Ball] = []
    private var _distance: DistanceGrid
    private var _selected: Cell? = nil

    init(pos: Vector, boxSize: Vector) {
        let boardSize = Cell(9, 9) // TODO remove me
        _grid = Grid<Box>(size: boardSize, filling: Box())
        _pos = pos
        _boxSize = boxSize
        _distance = DistanceGrid(size: boardSize)
    }

    func render(to canvas: Canvas, time: Seconds) {
        for (cell, type) in _nextBalls {
            let rect = cell.bounds(cellSize: _boxSize)
            let smallRect = rect.scaled(by: 1/3).centered(on: rect)
            canvas.drawTexture(name: type.toString + ".png", dest: smallRect.shifted(by: _pos))
        }
        for (cell, _) in _grid.enumerated() {
            _grid[cell].update(time: time)
            let box = _grid[cell]

            if let anim = box.traceAnim {
                let f = anim.pos(time)
                if f > 0 {
                    if box.traceState == .fading {
                        let rect = cell.bounds(cellSize: _boxSize).shifted(by: _pos)
                        let alpha = (1 - f)
                        canvas.setColor(Color.fromFloat(0.4, 0.4, 0.8, alpha))
                        canvas.drawRect(dest: rect)
                    }
                    else if box.traceState == .highlighted {
                        let rect = cell.bounds(cellSize: _boxSize).shifted(by: _pos)
                        var alpha = (1 - f)
                        alpha = alpha <= 0.5 ? alpha : 1 - alpha
                        canvas.setColor(Color.fromFloat(0.0, 0.5, 0.0, alpha * 0.5))
                        canvas.drawRect(dest: rect)
                    }
                }
            }

            switch box.state {
            case .empty:
                break
            case .spawning:
                let f = box.anim.pos(time) * 0.7 + 0.3
                let bounds = cell.bounds(cellSize: _boxSize)
                let rect = bounds.scaled(by: f).centered(on: bounds)
                canvas.drawTexture(name: box.type.spriteName, dest: rect.shifted(by: _pos))
            case .normal:
                canvas.drawTexture(name: box.type.spriteName, dest: cell.bounds(cellSize: _boxSize).shifted(by: _pos))
            case .clearing:
                let f = 1.0 - box.anim.pos(time)
                let bounds = cell.bounds(cellSize: _boxSize)
                let rect = bounds.scaled(by: Vector(f, 1)).centered(on: bounds)
                canvas.drawTexture(name: box.type.spriteName, dest: rect.shifted(by: _pos))
            case .selected:
                let f = box.anim.pos(time)
                let offset = (Float(sin(Double(f * 2 * Float.pi))) + 1) / 2 * 10
                let rect = cell.bounds(cellSize: _boxSize).shifted(by: _pos - Vector(0, offset))
                canvas.drawTexture(name: box.type.spriteName, dest: rect)
            }
        }
    }

    func translate(_ event: Event, time: Seconds) -> Action? {
        switch event {
        case Event.initialize:
            return Action.start
        case let Event.button(.pressed, .left, pos):
            let cell = windowToView(pos).toCell(cellSize: _boxSize)
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

    func select(_ cell: Cell, _ time: Seconds) {
        if let selected = _selected {
            _grid[selected].setState(.normal, time, next: nil)
        }

        _selected = cell
        _grid[cell].setState(.selected, time, next: nil)
        _distance.calculate(start: cell, isObstacle: { _grid[$0].state != .empty })

        for (cell, distance) in _distance.grid.enumerated() {
            if distance > 0 {
                _grid[cell].traceState = .highlighted
                _grid[cell].traceAnim = Anim(start: time + Double(_distance.max - distance) * 0.03, duration: 1.0)
            }
        }
    }

    func deselect() {
        _selected = nil
        _distance.clear()
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
            let path = _distance.path(to: dest)
            for (i, cell) in path.enumerated() {
                _grid[cell].traceState = .fading
                _grid[cell].traceAnim = Anim(start: time + Double(i) * 0.02, duration: 0.5)
            }
            deselect()
        case let Message.cleared(lines):
            for line in lines {
                for cell in line {
                    _grid[cell].setState(.clearing, time, next: .empty)
                }
            }
        case let Message.next(balls):
            _nextBalls = balls
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
