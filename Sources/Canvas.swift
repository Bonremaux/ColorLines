import CSDL2

typealias Seconds = Double

protocol Canvas {
    func drawTexture(name: String, dest rect: Rect)
    func setColor(_ color: Color)
    func drawRect(dest rect: Rect)
    func clear()
    func present()
    func createNumberCache(color: Color) -> NumberCache
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
    private let _font: OpaquePointer

    init(renderer: OpaquePointer) {
        _renderer = renderer
        if let font = TTF_OpenFont("Data/GoodDog.otf", 50) {
            _font = font
        }
        else {
            fatalError("TTF_OpenFont: \(String(validatingUTF8:SDL_GetError())!)");
        }
    }

    deinit {
        TTF_CloseFont(_font)
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

    func clear() {
        SDL_RenderClear(_renderer)
    }

    func present() {
        SDL_RenderPresent(_renderer)
    }

    private func loadTexture(_ name: String) -> Texture? {
        let texture = IMG_LoadTexture(renderer, "Data/" + name)
        return Texture(renderer: _renderer, texture: texture)
    }

    func createNumberCache(color: Color) -> NumberCache {
        return NumberCache(renderer: _renderer, font: _font, color: color)
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
        }

        return nil
    }

    func random(max: Int) -> Int {
        return Int(rand()) % max
    }
}

class NumberCache {
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

    private init(renderer: OpaquePointer, font: OpaquePointer, color: Color) {
        for char in "0123456789".characters {
            let surface = TTF_RenderText_Blended(font, String(char), SDL_Color(color))
            if surface != nil {
                let texture = SDL_CreateTextureFromSurface(renderer, surface)
                let width = surface!.pointee.w
                let height = surface!.pointee.h
                _glyphs[char] = Glyph(texture!, width, height)
                SDL_FreeSurface(surface)
            }
        }
    }

    func draw(to canvas: Canvas, at pos: Vector, numberString: String) {
        var p = pos
        for char in numberString.characters {
            if let glyph = _glyphs[char] {
                var rect = SDL_Rect(x: Int32(p.x), y: Int32(p.y), w: glyph.width, h: glyph.height)
                SDL_RenderCopy(renderer, glyph.texture, nil, &rect)
                p += Vector(Float(glyph.width), 0)
            }
        }
    }
}

