import CSDL2

class Application {
    private let _input: Input
    private let _canvas: Canvas
    private var _game: Game
    private var _view: GameView

    init(canvas: Canvas, input: Input) {
        _canvas = canvas
        _input = input
        _game = Game(random: input.random)
        _view = GameView()
    }

    func run() {
        while true {
            while let event = input.pollEvent() {
                if let action = _view.translate(event) {
                    if case .quit = action {
                        return
                    }
                    let messages = _game.process(action)
                    for msg in messages {
                        _view.apply(msg, time: elapsed())
                    }
                }
            }
            _canvas.setColor(Color.black)
            _canvas.clear()
            _view.render(to: canvas, time: elapsed())
            _canvas.present()
            SDL_Delay(1)
        }
    }
}
