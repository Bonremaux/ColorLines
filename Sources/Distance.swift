struct DistanceGrid {
    private var _distance: Grid<Int>

    init(size: Cell) {
        _distance = Grid<Int>(size: size, filling: -1)
    }

    private func neighbors(_ cell: Cell) -> [Cell] {
        let offsets = [Cell(-1, 0), Cell(0, -1), Cell(1, 0), Cell(0, 1)]
        return offsets.map { $0 + cell }.filter(_distance.isValidCell)
    }

    mutating func calculate(start: Cell, isObstacle: @noescape (Cell) -> Bool) {
        _distance.fill(with: -1)

        for (cell, _) in _distance.enumerated() {
            if isObstacle(cell) {
                _distance[cell] = -2
            }
        }

        _distance[start] = 0
        var openSet: Set<Cell> = [start]
        while !openSet.isEmpty {
            for cell in openSet {
                openSet.remove(cell)
                let nbs = neighbors(cell).filter { _distance[$0] == -1 }
                for nb in nbs {
                    _distance[nb] = _distance[cell] + 1
                    openSet.insert(nb)
                }
            }
        }
    }

    func path(to dest: Cell) -> [Cell] {
        guard _distance[dest] > 0 else { return [] }
        var path: [Cell] = []
        var cell = dest
        while _distance[cell] != 0 {
            let nbs = neighbors(cell).filter { _distance[$0] >= 0 && _distance[$0] < _distance[cell] }
            if let next = nbs.first {
                cell = next
                path.append(next)
            }
            else {
                return []
            }
        }
        return path
    }

    func hasPath(to dest: Cell) -> Bool {
        return _distance[dest] >= 0
    }
}
