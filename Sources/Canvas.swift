import CSDL2

typealias Seconds = Double

protocol Canvas {
    func drawTexture(name: String, dest rect: Rect)
    func setColor(_ color: Color)
    func drawRect(dest rect: Rect)
    func clear()
    func present()
    func loadFont(family: String, size: Int, color: Color) -> Font
    func drawText(font: Font, str: String, pos: Vector)
    func playSound(name: String)
}

protocol Font {
}

typealias KeyCode = Int

enum KeyState {
    case pressed
    case released
}

enum ButtonType {
    case left
    case right
    case middle
}

enum ButtonState {
    case pressed
    case released
}

enum Event {
    case initialize
    case quit
    case button(state: ButtonState, type: ButtonType, pos: Vector)
    case key(state: KeyState, code: KeyCode)
    case motion(pos: Vector)
}

protocol Input {
    func pollEvent() -> Event?
    func random(max: Int) -> Int
}

extension SDL_Color {
    init(_ c: Color) {
        self = SDL_Color(r: c.r, g: c.g, b: c.b, a: c.a)
    }
}

class Texture {
    private var renderer: OpaquePointer
    private let texture: OpaquePointer

    init?(renderer: OpaquePointer, texture: OpaquePointer?) {
        if let t = texture {
            self.renderer = renderer
            self.texture = t
        }
        else {
            return nil
        }
    }

    func draw(to canvas: Canvas, dest rect: Rect) {
        var sdlRect = SDL_Rect(x: Int32(rect.x), y: Int32(rect.y), w: Int32(rect.w), h: Int32(rect.h))
        SDL_RenderCopy(renderer, texture, nil, &sdlRect)
    }
}

class SDLCanvas: Canvas {
    private var _renderer: OpaquePointer
    private var _textures: [String: Texture] = [:]
    private var _sounds: [String: UnsafeMutablePointer<Mix_Chunk>] = [:]

    init(renderer: OpaquePointer) {
        _renderer = renderer
    }

    func setColor(_ color: Color) {
        SDL_SetRenderDrawColor(_renderer, color.r, color.g, color.b, color.a)
    }

    func drawRect(dest rect: Rect) {
        var sdlRect = SDL_Rect(x: Int32(rect.x), y: Int32(rect.y), w: Int32(rect.w), h: Int32(rect.h))
        SDL_RenderFillRect(_renderer, &sdlRect)
    }

    func drawTexture(name: String, dest rect: Rect) {
        if _textures[name] == nil {
            _textures[name] = loadTexture(name)
        }
        _textures[name]?.draw(to: self, dest: rect)
    }

    func playSound(name: String) {
        if _sounds[name] == nil {
            _sounds[name] = Mix_LoadWAV_RW(SDL_RWFromFile("Data/" + name, "rb"), 1)
        }
        if let sound = _sounds[name] {
            Mix_PlayChannelTimed(-1, sound, 0, -1)
        }
    }

    func clear() {
        SDL_RenderClear(_renderer)
    }

    func present() {
        SDL_RenderPresent(_renderer)
    }

    private func loadTexture(_ name: String) -> Texture? {
        let texture = IMG_LoadTexture(_renderer, "Data/" + name)
        return Texture(renderer: _renderer, texture: texture)
    }

    func loadFont(family: String, size: Int, color: Color) -> Font {
        return SDLFont(path: "Data/" + family, size: size, color: color)
    }

    func drawText(font: Font, str: String, pos: Vector) {
        let sdlFont = font as! SDLFont
        sdlFont.drawText(_renderer, str, pos)
    }
}

class SDLFont: Font {
    private let _font: OpaquePointer
    private let _color: Color

    class Glyph {
        let texture: OpaquePointer
        let width: Int32
        let height: Int32

        init(_ t: OpaquePointer, _ w: Int32, _ h: Int32) {
            texture = t
            width = w
            height = h
        }

        deinit {
            SDL_DestroyTexture(texture)
        }
    }

    private var _glyphs = [Character: Glyph]()

    init(path: String, size: Int, color: Color) {
        _color = color
        if let font = TTF_OpenFont(path, Int32(size)) {
            _font = font
        }
        else {
            fatalError("TTF_OpenFont: \(String(validatingUTF8:SDL_GetError())!)");
        }
    }

    deinit {
        TTF_CloseFont(_font)
    }

    func drawText(_ renderer: OpaquePointer, _ str: String, _ pos: Vector) {
        var p = pos
        for char in str.characters {
            if let glyph = getGlyph(renderer, char) {
                var rect = SDL_Rect(x: Int32(p.x), y: Int32(p.y), w: glyph.width, h: glyph.height)
                SDL_RenderCopy(renderer, glyph.texture, nil, &rect)
                p += Vector(Float(glyph.width), 0)
            }
        }
    }

    func getGlyph(_ renderer: OpaquePointer, _ char: Character) -> Glyph? {
        if _glyphs[char] == nil {
            _glyphs[char] = createGlyph(renderer, char)
        }
        return _glyphs[char]
    }

    func createGlyph(_ renderer: OpaquePointer, _ char: Character) -> Glyph? {
        guard let surface = TTF_RenderText_Blended(_font, String(char), SDL_Color(_color)) else { return nil }
        defer { SDL_FreeSurface(surface) }
        guard let texture = SDL_CreateTextureFromSurface(renderer, surface) else { return nil }
        let width = surface.pointee.w
        let height = surface.pointee.h
        return Glyph(texture, width, height)
    }
}

extension ButtonType {
    static func fromSDL(_ button: UInt8) -> ButtonType? {
        switch Int32(button) {
            case SDL_BUTTON_LEFT: return .left
            case SDL_BUTTON_RIGHT: return .right
            case SDL_BUTTON_MIDDLE: return .middle
            default: return nil
        }
    }
}

class SDLInput: Input {
    private var _sendInit = true

    func pollEvent() -> Event? {
        if _sendInit {
            _sendInit = false
            return Event.initialize
        }
        var event = SDL_Event()
        if SDL_PollEvent(&event) != 0 {
            let eventType = SDL_EventType(event.type)

            if eventType == SDL_QUIT {
                return Event.quit
            }

            if [SDL_KEYDOWN, SDL_KEYUP].contains(eventType) {
                if event.key.repeat != 0 {
                    return nil
                }
                let code = KeyCode(event.key.keysym.sym)
                let state = eventType == SDL_KEYDOWN ? KeyState.pressed : KeyState.released
                return Event.key(state: state, code: code)
            }

            if [SDL_MOUSEBUTTONDOWN, SDL_MOUSEBUTTONUP].contains(eventType) {
                if let type = ButtonType.fromSDL(event.button.button) {
                    let state = eventType == SDL_MOUSEBUTTONDOWN ? ButtonState.pressed : ButtonState.released
                    return Event.button(state: state, type: type, pos: Vector(Float(event.button.x), Float(event.button.y)))
                }
            }

            if eventType == SDL_MOUSEMOTION {
                return Event.motion(pos: Vector(Float(event.button.x), Float(event.button.y)))
            }
        }

        return nil
    }

    func random(max: Int) -> Int {
        return Int(rand()) % max
    }
}
