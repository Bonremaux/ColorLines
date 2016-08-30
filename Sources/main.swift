import CSDL2
import Glibc

func elapsed() -> Seconds {
    return Double(SDL_GetTicks()) / 1000
}

func sdlFatal(_ str: String) {
    fatalError(str + ": \(String(validatingUTF8:SDL_GetError()) ?? "unknown error")");
}

srand(UInt32(time(nil)));

if SDL_Init(UInt32(SDL_INIT_VIDEO)) == -1 {
    sdlFatal("SDL_Init")
}

if TTF_Init() == -1 {
    sdlFatal("TTF_Init")
}

var window = SDL_CreateWindow("SDL Tutorial", 0, 0, 700, 505, SDL_WINDOW_SHOWN.rawValue)
if window == nil {
    sdlFatal("SDL_CreateWindow failed")
}

var renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED.rawValue)
if renderer == nil {
    sdlFatal("SDL_CreateRenderer failed")
}

SDL_SetRenderDrawBlendMode(renderer, SDL_BLENDMODE_BLEND)

var canvas = SDLCanvas(renderer: renderer!)
var input = SDLInput()

var game = LinesGame(canvas: canvas, input: input, boardSize: Cell(9, 9), squareSize: Vector(50, 50))

game.run()

TTF_Quit()
SDL_Quit()
