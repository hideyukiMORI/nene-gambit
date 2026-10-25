import NeNeGambitEngine
import NeNeGambitRender
import NeNeGambitTerminal

/// 対局の列を時計で回す 1 本のループ（ADR 0006）。状態はすべてこの値の中にあり、ループの外へ出ない（ARC-005）。
struct Screensaver {
    private let options: LaunchOptions
    private let seed: UInt64
    private let clock = ContinuousClock()
    private var generator: SplitMix64
    private var series: GameSeries
    private var display: DisplayOptions
    private var previous: Grid?

    init(options: LaunchOptions, display: DisplayOptions, seed: UInt64) {
        self.options = options
        self.seed = seed
        self.display = display
        var generator = SplitMix64(seed: seed)
        series = GameSeries.starting(using: &generator)
        self.generator = generator
    }

    /// `q` か終了のシグナルが来るまで回す。
    mutating func run() {
        var deadline = clock.now + options.moveInterval
        draw(deadline: deadline)
        while true {
            let wake = min(deadline, nextRedraw(before: deadline))
            let intents = KeyIntent.decode(Console.waitForInput(milliseconds: milliseconds(until: wake)))
            let signals = Console.takeSignals()
            if signals.interrupted || intents.contains(.quit) {
                return
            }
            apply(intents)
            if signals.resized {
                previous = nil
            }
            if clock.now >= deadline {
                series = series.advanced(using: &generator)
                deadline = clock.now + pause(after: series)
            }
            draw(deadline: deadline)
        }
    }

    private mutating func apply(_ intents: [KeyIntent]) {
        for intent in intents {
            switch intent {
            case .quit:
                return
            case .toggleGlyphs:
                display = DisplayOptions(glyphs: display.glyphs.toggled, theme: display.theme, traits: display.traits)
            case .cycleTheme:
                display = DisplayOptions(glyphs: display.glyphs, theme: display.theme.next, traits: display.traits)
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

    /// 終局の秒読みの間は 1 秒ごとに描き直す。続いている局では締め切りまで描き直さない。
    private func nextRedraw(before deadline: ContinuousClock.Instant) -> ContinuousClock.Instant {
        guard case .finished = series.game.status else {
            return deadline
        }
        return clock.now + .seconds(1)
    }

    /// いまの状態を描き、前のフレームとの差分だけを 1 回で書く。
    private mutating func draw(deadline: ContinuousClock.Instant) {
        let state = ScreenState(series: series, options: display, seed: seed, countdown: countdown(until: deadline))
        let grid = TableRenderer.render(state, size: Console.size())
        Console.write(FrameEncoder.encode(grid, previous: previous, colors: display.traits.colors))
        previous = grid
    }

    private func countdown(until deadline: ContinuousClock.Instant) -> Countdown? {
        guard case .finished = series.game.status else {
            return nil
        }
        let remaining = (Int(milliseconds(until: deadline)) + 999) / 1000
        let total = (Int(options.resultPause.components.seconds) * 1000 + 999) / 1000
        return Countdown(remaining: remaining, total: max(total, 1))
    }

    /// 締め切りまでのミリ秒（過ぎていれば 0）。
    private func milliseconds(until instant: ContinuousClock.Instant) -> Int32 {
        let (seconds, attoseconds) = (instant - clock.now).components
        let total = seconds * 1000 + attoseconds / 1_000_000_000_000_000
        return Int32(clamping: max(total, 0))
    }
}
