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

    var nextBalls: [Ball] {
        return _nextBalls
    }

    subscript(cell: Cell) -> BallType? {
        get {
            return _balls[cell]
        }
        set {
            _balls[cell] = newValue
        }
    }

    func hasPath(from src: Cell, to dest: Cell) -> Bool {
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

    func clearAllLines() -> [[Cell]] {
        var lines: [[Cell]] = []
        for (cell, _) in _balls.enumerated() {
            for dir in [Cell(1, 0), Cell(0, 1), Cell(1, 1), Cell(-1, 1)] {
                let line = clearLine(from: cell, step: dir)
                lines += line.isEmpty ? [] : [line]
            }
        }
        return lines
    }

    private func getRandomEmptyCell() -> Cell {
        while true {
            let cell = Cell(_random(max: _balls.size.x), _random(max: _balls.size.y))
            if _balls[cell] == nil && !_nextBalls.contains({ $0.0 == cell }) {
                return cell
            }
        }
    }

    func spawnBalls() -> [Ball] {
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
}
