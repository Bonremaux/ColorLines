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
    private var _nextBalls: [Ball] = []
    private let _random: (max: Int) -> Int

    init(size: Cell, random: (max: Int) -> Int) {
        _balls = Grid<BallType?>(size: size, filling: nil)
        _random = random
    }

    var nextBalls: [Ball] {
        return _nextBalls
    }

    func moveBall(from src: Cell, to dest: Cell) -> [Cell] {
        var distance = DistanceGrid(size: _balls.size)
        distance.calculate(start: src, isObstacle: { _balls[$0] != nil })
        let path = distance.path(to: dest)
        if !path.isEmpty {
            _balls[dest] = _balls[src]
            _balls[src] = nil
        }
        return path
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

    private func getEmptyCell() -> Cell? {
        if emptyCount - _nextBalls.count <= 0 {
            return nil
        }
        while true {
            let cell = Cell(_random(max: _balls.size.x), _random(max: _balls.size.y))
            if _balls[cell] == nil && !_nextBalls.contains({ cell == $0.0 }) {
                return cell
            }
        }
    }

    func spawnBalls() -> [Ball] {
        var spawned: [Ball] = []

        for (cell, type) in _nextBalls {
            guard let spawnCell = _balls[cell] == nil ? cell : getEmptyCell() else { break }
            _balls[spawnCell] = type
            spawned.append((spawnCell, type))
        }
        _nextBalls = []

        while spawned.count != 3 {
            guard let cell = getEmptyCell() else { break }
            let type = BallType.allValues[_random(max: BallType.allValues.count)]
            _balls[cell] = type
            spawned.append((cell, type))
        }

        while _nextBalls.count != 3 {
            guard let cell = getEmptyCell() else { break }
            let type = BallType.allValues[_random(max: BallType.allValues.count)]
            _nextBalls.append((cell, type))
        }

        return spawned
    }

    private var emptyCount: Int {
        return _balls.values().filter{ $0 == nil }.count
    }

    var isFull: Bool {
        return emptyCount == 0
    }
}
