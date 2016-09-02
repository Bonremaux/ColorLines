struct Cell: Equatable, Comparable, Hashable {
    var x: Int
    var y: Int

    init(_ x: Int, _ y: Int) {
        self.x = x
        self.y = y
    }

    func toVector(cellSize: Vector) -> Vector {
        return Vector(Float(x), Float(y)) * cellSize
    }

    func bounds(cellSize: Vector) -> Rect {
        return Rect(pos: toVector(cellSize: cellSize), size: cellSize)
    }

    var hashValue: Int {
        return y ^ x
    }
}

func == (l: Cell, r: Cell) -> Bool {
    return l.x == r.x && l.y == r.y
}

func - (l: Cell, r: Cell) -> Cell {
    return Cell(l.x - r.x, l.y - r.y)
}

func + (l: Cell, r: Cell) -> Cell {
    return Cell(l.x + r.x, l.y + r.y)
}

func += (l: inout Cell, r: Cell) {
    l = l + r
}

func < (l: Cell, r: Cell) -> Bool {
    return l.x < r.x && l.y < r.y
}

func >= (l: Cell, r: Cell) -> Bool {
    return l.x >= r.x && l.y >= r.y
}

struct Grid<T> {
    private var _values: [T]
    let size: Cell

    init(size: Cell, filling value: T) {
        self.size = size
        _values = Array<T>(repeating: value, count: size.x * size.y)
    }

    subscript(cell: Cell) -> T {
        get {
            return _values[cell.y * size.x + cell.x]
        }
        set {
            _values[cell.y * size.x + cell.x] = newValue
        }
    }

    mutating func fill(with value: T) {
        for i in 0..<_values.count {
            _values[i] = value
        }
    }

    func isValidCell(_ cell: Cell) -> Bool {
        return cell < size && cell >= Cell(0, 0)
    }

    func nextCell(_ cell: Cell) -> Cell? {
        var next = cell + Cell(1, 0)
        if next.x >= size.x {
            next = Cell(0, next.y + 1)
        }
        return isValidCell(next) ? next : nil
    }
 
    var isEmpty: Bool {
        return size.x * size.y == 0
    }

    func values() -> Array<T>.Iterator {
        return _values.makeIterator()
    }

    func enumerated() -> GridSequence<T> {
        return GridSequence(grid: self)
    }
}

struct GridSequence<T>: Sequence, IteratorProtocol {
    private let _grid: Grid<T>
    private var _current: Cell?

    init(grid: Grid<T>) {
        _grid = grid
        _current = grid.isEmpty ? nil: Cell(0, 0)
    }

    mutating func next() -> (Cell, T)? {
        defer {
            if let cell = _current {
                _current = _grid.nextCell(cell)
            }
        }
        if let cell = _current {
            return (cell, _grid[cell])
        }
        else {
            return nil
        }
    }
}
