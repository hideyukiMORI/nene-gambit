import NeNeGambitRender

/// 起動オプション（ARC-008: 境界で 1 度だけ検証し、型に変えてから中へ渡す）。
///
/// `--seed <0 以上の整数>` / `--glyphs letters|symbols` / `--theme <名前>` / `--move-interval <秒>` / `--result-pause <秒>`。
struct LaunchOptions {
    /// 乱数のシード。与えられなければ nil（起動時にシステムの乱数から決める）。
    let seed: UInt64?
    let glyphs: GlyphSet
    let theme: Theme
    /// 1 手を指す間隔（FR-11 の初期値は 1.0 秒。手順 3 で施主が「0.7 秒は少し早い」と見て変えた）。
    let moveInterval: Duration
    /// 終局後に結果を見せる時間（FR-11 の初期値は 3 秒）。
    let resultPause: Duration

    static let defaults = LaunchOptions(
        seed: nil, glyphs: .letters, theme: .standard, moveInterval: .milliseconds(1000), resultPause: .seconds(3))

    /// 起動オプションを読む（プログラム名を除いた引数）。
    static func parse(_ arguments: [String]) -> LaunchParsing {
        var options = defaults
        var rest = arguments[...]
        while let name = rest.popFirst() {
            guard let value = rest.popFirst() else {
                return .rejected("\(name) に値が無い")
            }
            guard let next = options.setting(name, value) else {
                return .rejected(
                    "読めないオプション: \(name) \(value)（--seed / --glyphs / --theme / --move-interval / --result-pause / --version）"
                )
            }
            options = next
        }
        return .parsed(options)
    }

    /// 文字列で分岐するので `switch` ではなく `if` で書く（SWF-002: 全捕捉を書かない）。
    private func setting(_ name: String, _ value: String) -> LaunchOptions? {
        if name == "--seed" {
            return UInt64(value).map { with(seed: $0) }
        }
        if name == "--glyphs" {
            return ["letters": GlyphSet.letters, "symbols": GlyphSet.symbols][value].map { with(glyphs: $0) }
        }
        if name == "--theme" {
            return Theme.named(value).map { with(theme: $0) }
        }
        if name == "--move-interval" {
            return Self.duration(value).map { with(moveInterval: $0) }
        }
        if name == "--result-pause" {
            return Self.duration(value).map { with(resultPause: $0) }
        }
        return nil
    }

    /// 0.05〜60 秒の秒数。
    private static func duration(_ text: String) -> Duration? {
        guard let seconds = Double(text), (0.05...60).contains(seconds) else {
            return nil
        }
        return .milliseconds(Int((seconds * 1000).rounded()))
    }

    private func with(seed: UInt64) -> LaunchOptions {
        LaunchOptions(seed: seed, glyphs: glyphs, theme: theme, moveInterval: moveInterval, resultPause: resultPause)
    }

    private func with(glyphs: GlyphSet) -> LaunchOptions {
        LaunchOptions(seed: seed, glyphs: glyphs, theme: theme, moveInterval: moveInterval, resultPause: resultPause)
    }

    private func with(theme: Theme) -> LaunchOptions {
        LaunchOptions(seed: seed, glyphs: glyphs, theme: theme, moveInterval: moveInterval, resultPause: resultPause)
    }

    private func with(moveInterval: Duration? = nil, resultPause: Duration? = nil) -> LaunchOptions {
        LaunchOptions(
            seed: seed,
            glyphs: glyphs,
            theme: theme,
            moveInterval: moveInterval ?? self.moveInterval,
            resultPause: resultPause ?? self.resultPause
        )
    }
}
