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
    case scored(score: Int, lines: Int)
}

class Game {
    private let _board: Board
    private var _score: Int = 0
    private var _lines: Int = 0

    init(random: (max: Int) -> Int) {
        _board = Board(size: Cell(9, 9), random: random)
    }

    func process(_ action: Action) -> [Message] {
        switch action {
            case Action.start: return start()
            case let Action.move(src, dest): return moveBall(from: src, to: dest)
            default: break
        }
        return []
    }

    private func start() -> [Message] {
        let spawned = _board.spawnBalls()
        return [.spawned(spawned), .next(_board.nextBalls)]
    }

    private func moveBall(from src: Cell, to dest: Cell) -> [Message] {
        guard _board[src] != nil && _board[dest] == nil else {
            return []
        }
        guard _board.hasPath(from: src, to: dest) else {
            return []
        }

        _board[dest] = _board[src]
        _board[src] = nil
        var cleared = _board.clearAllLines()
        var spawned: [Ball] = []
        if cleared.count == 0 {
            spawned = _board.spawnBalls()
            cleared = _board.clearAllLines()
        }

        var msg: [Message] = [.moved(from: src, to: dest)]
        if !spawned.isEmpty { msg += [.spawned(spawned), .next(_board.nextBalls)] }
        if !cleared.isEmpty { msg += [.cleared(cleared)] }

        for line in cleared {
            _score += line.count * 10
        }
        _lines += cleared.count

        msg += [.scored(score: _score, lines: _lines)]

        return msg
    }
}
