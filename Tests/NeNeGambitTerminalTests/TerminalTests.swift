import NeNeGambitRender
import NeNeGambitTerminal
import Testing

/// 端末へ書くバイト列とキー入力・カーソル位置の報告の読み取り（端末そのものは使わない）。
struct TerminalTests {
    static func text(_ bytes: [UInt8]) -> String {
        String(decoding: bytes, as: UTF8.self)
    }

    static func grid(_ glyphs: GlyphSet, size: ScreenSize = TableRenderer.largeSize, theme: Theme = .standard) -> Grid {
        let traits = TerminalTraits(frame: .boxDrawing, colors: .trueColor)
        let options = DisplayOptions(glyphs: glyphs, theme: theme, traits: traits)
        let state = ScreenState(series: TableRendererFixture.series, options: options, seed: 1, countdown: nil)
        return TableRenderer.render(state, size: size)
    }

    @Test func keysBecomeIntents() {
        #expect(KeyIntent.decode(Array("q".utf8)) == [.quit])
        #expect(KeyIntent.decode(Array("Gxg".utf8)) == [.toggleGlyphs, .toggleGlyphs])
        #expect(KeyIntent.decode(Array("tT".utf8)) == [.cycleTheme, .cycleTheme])
        #expect(KeyIntent.decode([0x1B, UInt8(ascii: "["), UInt8(ascii: "A"), UInt8(ascii: "q")]) == [.quit])
        #expect(KeyIntent.decode([0x1B]).isEmpty)
    }

    @Test func cursorReportGivesTheColumn() {
        #expect(CursorReport.column(in: Array("\u{1B}[12;2R".utf8)) == 2)
        #expect(CursorReport.column(in: Array("x\u{1B}[1;3R".utf8)) == 3)
        #expect(CursorReport.column(in: Array("garbage".utf8)) == nil)
        #expect(CursorReport.column(in: []) == nil)
    }

    @Test func firstFrameClearsAndDrawsEverything() {
        let text = Self.text(FrameEncoder.encode(Self.grid(.letters), previous: nil, colors: .trueColor))
        #expect(text.hasPrefix("\u{1B}[0m\u{1B}[2J"))
        #expect(text.contains("\u{1B}[38;2;"))
        #expect(text.hasSuffix("\u{1B}[0m"))
    }

    @Test func unchangedFrameWritesNothing() {
        let grid = Self.grid(.letters)
        #expect(FrameEncoder.encode(grid, previous: grid, colors: .trueColor).isEmpty)
    }

    /// 字形を替えると駒の升だけが変わる。差分は全面の書き直しより短く、画面を消さない。
    @Test func changedCellsAreTheOnlyOnesWritten() {
        let after = Self.grid(.symbols)
        let full = FrameEncoder.encode(after, previous: nil, colors: .trueColor)
        let diff = FrameEncoder.encode(after, previous: Self.grid(.letters), colors: .trueColor)
        #expect(!diff.isEmpty && diff.count < full.count)
        #expect(!Self.text(diff).contains("\u{1B}[2J"))
        #expect(Self.text(diff).contains("\u{265A}"))
    }

    @Test func palette256IsUsedWithoutTrueColor() {
        let text = Self.text(FrameEncoder.encode(Self.grid(.letters), previous: nil, colors: .palette256))
        #expect(text.contains("\u{1B}[38;5;") && !text.contains("38;2;"))
    }

    /// 256 色の近似: 各テーマの地（いちばん暗い色）は、どの成分も元の色から 40 以内に収まる（暗い色が明るい色へ飛ばない）。
    @Test(arguments: Theme.catalog.map(\.name))
    func paletteKeepsDarkGroundsDark(name: String) throws {
        let ground = Self.grid(.letters, theme: try #require(Theme.named(name)))[0, 1].background
        let mapped = Palette256.rgb(at: Palette256.nearest(ground))
        let original = [Int(ground.red), Int(ground.green), Int(ground.blue)]
        #expect(zip(mapped, original).allSatisfy { abs($0 - $1) <= 40 }, "\(name): \(original) -> \(mapped)")
    }

    @Test func paletteMapsExactColorsToThemselves() {
        #expect(Palette256.nearest(Rgb(red: 0, green: 0, blue: 0)) == 16)
        #expect(Palette256.nearest(Rgb(red: 255, green: 255, blue: 255)) == 231)
        #expect(Palette256.nearest(Rgb(red: 128, green: 128, blue: 128)) == 244)
    }

    /// 端末が駒記号でカーソルを 1 進めても 2 進めても、すべてのセル（駒記号の右隣の空白を含む）が格子どおりの桁に書かれる。
    /// 書いたバイト列を、その 2 種類の端末として再生して確かめる（Windows Terminal は 1 と答えて約 2 桁で描く・Issue #13・#15）。
    @Test(arguments: [1, 2])
    func everyCellLandsWhateverTheTerminalAdvances(advance: Int) {
        let grid = Self.grid(.symbols)
        let symbols: Set<Character> = ["\u{265A}", "\u{265B}", "\u{265C}", "\u{265D}", "\u{265E}", "\u{265F}"]
        var screen: [[Int]: Character] = [:]
        var cursor = [0, 0]
        var characters = Array(Self.text(FrameEncoder.encode(grid, previous: nil, colors: .trueColor)))[...]
        while let character = characters.popFirst() {
            guard character == "\u{1B}" else {
                screen[cursor] = character
                cursor[1] += symbols.contains(character) ? advance : 1
                continue
            }
            var sequence = ""
            while let next = characters.popFirst() {
                sequence.append(next)
                if next.isLetter { break }
            }
            if sequence.hasSuffix("H") {
                let parts = sequence.dropFirst().dropLast().split(separator: ";").compactMap { Int($0) }
                cursor = [parts[0] - 1, parts[1] - 1]
            }
        }
        var mismatches = 0
        for row in 0..<grid.size.rows {
            for column in 0..<grid.size.columns {
                if screen[[row, column]] != grid[column, row].character {
                    mismatches += 1
                }
            }
        }
        #expect(mismatches == 0)
    }

    @Test func resizedFrameIsRedrawnInFull() {
        let small = Self.grid(.letters, size: ScreenSize(columns: 10, rows: 2))
        let text = Self.text(FrameEncoder.encode(Self.grid(.letters), previous: small, colors: .trueColor))
        #expect(text.hasPrefix("\u{1B}[0m\u{1B}[2J"))
    }
}
