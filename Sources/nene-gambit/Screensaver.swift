import NeNeGambitEngine
import NeNeGambitRender
import NeNeGambitTerminal

/// 対局の列を時計で回す 1 本のループ（ADR 0006）。状態はすべてこの値の中にあり、ループの外へ出ない（ARC-005）。
struct Screensaver {
    private let options: LaunchOptions
    private let colors: ColorMode
    private let clock = ContinuousClock()
    private var generator: SplitMix64
    private var series = GameSeries.starting(Players(white: .random, black: .random))
    private var glyphs: GlyphSet
    private var previous: Grid?

    init(options: LaunchOptions, colors: ColorMode, seed: UInt64) {
        self.options = options
        self.colors = colors
        generator = SplitMix64(seed: seed)
        glyphs = options.glyphs
    }

    /// `q` か終了のシグナルが来るまで回す。
    mutating func run() {
        var deadline = clock.now + options.moveInterval
        draw()
        while true {
            let intents = KeyIntent.decode(Console.waitForInput(milliseconds: milliseconds(until: deadline)))
            let signals = Console.takeSignals()
            if signals.interrupted || intents.contains(.quit) {
                return
            }
            if intents.filter({ $0 == .toggleGlyphs }).count % 2 == 1 {
                glyphs = glyphs.toggled
                draw()
            }
            if signals.resized {
                previous = nil
                draw()
            }
            if clock.now >= deadline {
                series = series.advanced(using: &generator)
                deadline = clock.now + pause(after: series)
                draw()
            }
        }
    }

    /// 次の 1 歩までの間隔。終局した直後は結果を見せる時間（FR-11）。
    private func pause(after series: GameSeries) -> Duration {
        switch series.game.status {
        case .ongoing:
            return options.moveInterval
        case .finished:
            return options.resultPause
        }
    }

    /// いまの状態を描き、前のフレームとの差分だけを 1 回で書く。
    private mutating func draw() {
        let grid = TableRenderer.render(series, glyphs: glyphs, size: Console.size())
        Console.write(FrameEncoder.encode(grid, previous: previous, colors: colors))
        previous = grid
    }

    /// 締め切りまでのミリ秒（過ぎていれば 0）。
    private func milliseconds(until instant: ContinuousClock.Instant) -> Int32 {
        let (seconds, attoseconds) = (instant - clock.now).components
        let total = seconds * 1000 + attoseconds / 1_000_000_000_000_000
        return Int32(clamping: max(total, 0))
    }
}
