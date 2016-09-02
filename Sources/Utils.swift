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

    func shifted(by offset: Vector) -> Rect {
        return moved(to: position + offset)
    }

    func inflated(by amount: Vector) -> Rect {
        return Rect(pos: position - amount, size: size + amount * 2)
    }

    func scaled(by factor: Vector) -> Rect {
        return Rect(pos: position, size: size * factor)
    }

    func scaled(by factor: Float) -> Rect {
        return Rect(pos: position, size: size * factor)
    }

    func centered(on rect: Rect) -> Rect {
        return moved(to: rect.position + (rect.size - size) / 2)
    }
}

func == (l: Rect, r: Rect) -> Bool {
    return l.x == r.x && l.y == r.y && l.w == r.w && l.h == r.h
}

struct Color {
    var r, g, b, a: UInt8

    init(_ r: UInt8, _ g: UInt8, _ b: UInt8, _ a: UInt8 = 255) {
        self.r = r
        self.g = g
        self.b = b
        self.a = a
    }

    static func fromFloat(_ r: Float, _ g: Float, _ b: Float, _ a: Float = 1.0) -> Color {
        return Color(UInt8(r * 255), UInt8(g * 255), UInt8(b * 255), UInt8(a * 255))
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
