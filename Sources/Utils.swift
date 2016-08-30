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

struct Vector: Equatable {
    var x: Float
    var y: Float

    init(_ x: Float, _ y: Float) {
        self.x = x
        self.y = y
    }

    func toCell(cellSize: Vector) -> Cell {
        return Cell(Int(x / cellSize.x), Int(y / cellSize.y))
    }
}

func == (l: Vector, r: Vector) -> Bool {
    return l.x == r.x && l.y == r.y
}

func + (l: Vector, r: Vector) -> Vector {
    return Vector(l.x + r.x, l.y + r.y)
}

func - (l: Vector, r: Vector) -> Vector {
    return Vector(l.x - r.x, l.y - r.y)
}

func * (l: Vector, r: Vector) -> Vector {
    return Vector(l.x * r.x, l.y * r.y)
}

func / (l: Vector, r: Vector) -> Vector {
    return Vector(l.x / r.x, l.y / r.y)
}

func += (l: inout Vector, r: Vector) {
    l = l + r
}

func + (l: Vector, s: Float) -> Vector {
    return Vector(l.x + s, l.y + s)
}

func - (l: Vector, s: Float) -> Vector {
    return Vector(l.x - s, l.y - s)
}

func * (v: Vector, s: Float) -> Vector {
    return Vector(v.x * s, v.y * s)
}

func / (l: Vector, s: Float) -> Vector {
    return Vector(l.x / s, l.y / s)
}

struct Rect: Equatable {
    var x: Float
    var y: Float
    var w: Float
    var h: Float

    init(pos p: Vector, size s: Vector) {
        x = p.x
        y = p.y
        w = s.x
        h = s.y
    }

    init(size s: Vector) {
        self.init(pos: Vector(0, 0), size: s)
    }

    var position: Vector {
        set {
            x = newValue.x
            y = newValue.y
        }
        get {
            return Vector(x, y)
        }
    }

    var size: Vector {
        set {
            w = newValue.x
            h = newValue.y
        }
        get {
            return Vector(w, h)
        }
    }

    func moved(to pos: Vector) -> Rect {
        return Rect(pos: pos, size: size)
    }

    func moved(by offset: Vector) -> Rect {
        return moved(to: position + offset)
    }

    func expanded(thickness t: Float) -> Rect {
        return Rect(pos: position - t, size: size + t * 2)
    }

    func scaled(_ scale: Float) -> Rect {
        return Rect(pos: position, size: size * scale)
    }

    func scaled(_ scale: Vector) -> Rect {
        return Rect(pos: position, size: size * scale)
    }

    func centered(relativelyTo rect: Rect) -> Rect {
        return moved(to: rect.position + (rect.size - size) / 2)
    }
}

func == (l: Rect, r: Rect) -> Bool {
    return l.x == r.x && l.y == r.y && l.w == r.w && l.h == r.h
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

struct Color {
    var r, g, b, a: UInt8

    init(_ r: UInt8, _ g: UInt8, _ b: UInt8, _ a: UInt8 = 255) {
        self.r = r
        self.g = g
        self.b = b
        self.a = a
    }

    init(hex: Int) {
        self.init(UInt8((hex >> 16) & 0xff), UInt8((hex >> 8) & 0xff), UInt8(hex & 0xff))
    }

    static let black = Color(hex: 0x000000)
    static let white = Color(hex: 0xFFFFFF)
    static let red = Color(hex: 0xFF0000)
    static let grey = Color(hex: 0x808080)
    static let blue = Color(hex: 0x0000FF)
    static let cyan = Color(hex: 0x00FFFF)
    static let orange = Color(hex: 0xFFA500)
    static let yellow = Color(hex: 0xFFFF00)
    static let lime = Color(hex: 0x00FF00)
    static let purple = Color(hex: 0x800080)
    static let maroon = Color(hex: 0x800000)
    static let pink = Color(hex: 0xFFF0CB)
    static let magenta = Color(hex: 0xFF00FF)
    static let green = Color(hex: 0x008000)
    static let indigo = Color(hex: 0x4B0082)
    static let crimson = Color(hex: 0xDC143C)
    static let amber = Color(hex: 0xFFBF00)
    static let lightgrey = Color(hex: 0xD3D3D3)
    static let navy = Color(hex: 0x000080)
    static let darkgreen = Color(hex: 0x006400)
    static let brown = Color(hex: 0xA52A2A)
    static let teal = Color(hex: 0x008080)
    static let slateblue = Color(hex: 0x6A5ACD)
}
