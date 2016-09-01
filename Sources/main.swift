import CSDL2
import Glibc

func elapsed() -> Seconds {
    return Double(SDL_GetTicks()) / 1000
}

func sdlFatal(_ str: String) {
    fatalError(str + ": \(String(validatingUTF8:SDL_GetError()) ?? "unknown error")");
}

srand(UInt32(time(nil)));

if SDL_Init(UInt32(SDL_INIT_VIDEO | SDL_INIT_AUDIO)) == -1 {
    sdlFatal("SDL_Init")
}

if TTF_Init() == -1 {
    sdlFatal("TTF_Init")
}

Mix_OpenAudio(MIX_DEFAULT_FREQUENCY, UInt16(MIX_DEFAULT_FORMAT), 2, 640)

// let wav = Mix_LoadWAV_RW(SDL_RWFromFile("Data/clear.wav", "rb"), 1)
// Mix_PlayChannelTimed(-1, wav, 0, -1)

var window = SDL_CreateWindow("SDL Tutorial", 0, 0, 510, 510 + 50, SDL_WINDOW_SHOWN.rawValue)
if window == nil {
    sdlFatal("SDL_CreateWindow failed")
}

private var renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED.rawValue)
if renderer == nil {
    sdlFatal("SDL_CreateRenderer failed")
}

SDL_SetRenderDrawBlendMode(renderer, SDL_BLENDMODE_BLEND)

private var canvas = SDLCanvas(renderer: renderer!)
private var input = SDLInput()

private var app = Application(canvas: canvas, input: input)

app.run()

TTF_Quit()
SDL_Quit()
