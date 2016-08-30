import CSDL2

enum Action {
    case start
    case move(from: Cell, to: Cell)
    case quit
}

enum Message {
    case cleared([[Cell]])
    case moved(from: Cell, to: Cell)
    case spawned([Ball])
    case next([Ball])
}

typealias Ball = (Cell, BallType)

enum BallType: Int {
    case blue, red, green, brown, cyan, pink, yellow

    static var allValues: [BallType] {
        return [.blue, .red, .green, .brown, .cyan, .pink, .yellow]
    }

    var toString: String {
        switch self {
            case .blue: return "blue"
            case .red: return "red"
            case .green: return "green"
            case .brown: return "brown"
            case .cyan: return "cyan"
            case .pink: return "pink"
            case .yellow: return "yellow"
        }
    }
}

class Board {
    private var _balls: Grid<BallType?>
    private var _distance: DistanceGrid
    private var _nextBalls: [Ball] = []
    private let _random: (max: Int) -> Int

    init(size: Cell, random: (max: Int) -> Int) {
        _balls = Grid<BallType?>(size: size, filling: nil)
        _distance = DistanceGrid(size: size)
        _random = random
    }

    private func canMoveBall(from src: Cell, to dest: Cell) -> Bool {
        _distance.calculate(start: src, isObstacle: { _balls[$0] != nil })
        return _distance.hasPath(to: dest)
    }

    private func clearLine(from: Cell, step: Cell) -> [Cell] {
        guard let type = _balls[from] else {
            return []
        }
        var line: [Cell] = []
        var cell = from
        while cell < _balls.size && _balls[cell] == type {
            line.append(cell)
            cell += step
        }
        if line.count >= 5 {
            for cell in line {
                _balls[cell] = nil
            }
            return line
        }
        return []
    }

    private func clearAllLines() -> [[Cell]] {
        var lines: [[Cell]] = []
        for (cell, _) in _balls.enumerated() {
            for dir in [Cell(1, 0), Cell(0, 1), Cell(1, 1), Cell(-1, 1)] {
                let line = clearLine(from: cell, step: dir)
                lines += line.isEmpty ? [] : [line]
            }
        }
        return lines
    }

    private func moveBall(from src: Cell, to dest: Cell) -> [Message] {
        guard _balls[src] != nil && _balls[dest] == nil else {
            return []
        }
        guard canMoveBall(from: src, to: dest) else {
            return []
        }
        _balls[dest] = _balls[src]
        _balls[src] = nil
        var cleared = clearAllLines()
        var spawned: [Ball] = []
        if cleared.count == 0 {
            spawned = spawnBalls()
            cleared = clearAllLines()
        }

        var msg: [Message] = [.moved(from: src, to: dest)]
        if !spawned.isEmpty { msg.append(.spawned(spawned)) }
        if !_nextBalls.isEmpty { msg.append(.next(_nextBalls)) }
        if !cleared.isEmpty { msg.append(.cleared(cleared)) }

        return msg
    }

    private func getRandomEmptyCell() -> Cell {
        while true {
            let cell = Cell(_random(max: _balls.size.x), _random(max: _balls.size.y))
            if _balls[cell] == nil && !_nextBalls.contains({ $0.0 == cell }) {
                return cell
            }
        }
    }

    private func spawnBalls() -> [Ball] {
        var spawned: [Ball] = []

        for (cell, type) in _nextBalls {
            let spawnCell = _balls[cell] == nil ? cell : getRandomEmptyCell()
            _balls[spawnCell] = type
            spawned.append((spawnCell, type))
        }

        while spawned.count != 3 {
            let cell = getRandomEmptyCell()
            let type = BallType.allValues[_random(max: BallType.allValues.count)]
            _balls[cell] = type
            spawned.append((cell, type))
        }

        _nextBalls = []
        for _ in 1...3 {
            let cell = getRandomEmptyCell()
            let type = BallType.allValues[_random(max: BallType.allValues.count)]
            _nextBalls.append((cell, type))
        }

        return spawned
    }

    private func start() -> [Message] {
        let spawned = spawnBalls()
        return [.spawned(spawned), .next(_nextBalls)]
    }

    func process(_ action: Action) -> [Message] {
        switch action {
            case Action.start: return start()
            case let Action.move(src, dest): return moveBall(from: src, to: dest)
            default: break
        }
        return []
    }
}

class LinesGame {
    private let _input: Input
    private let _canvas: Canvas
    private var _board: Board
    private var _view: AppView

    init(canvas: Canvas, input: Input, boardSize: Cell, squareSize: Vector) {
        _canvas = canvas
        _input = input
        _board = Board(size: boardSize, random: input.random)
        _view = AppView()
    }

    func run() {
        while true {
            while let event = input.pollEvent() {
                if let action = _view.translate(event) {
                    if case .quit = action {
                        return
                    }
                    let messages = _board.process(action)
                    for msg in messages {
                        _view.apply(msg, time: elapsed())
                    }
                }
            }
            _canvas.setColor(Color.black)
            _canvas.clear()
            _view.render(to: canvas, time: elapsed())
            _canvas.present()
            SDL_Delay(1)
        }
    }
}
