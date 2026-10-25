import NeNeGambitRender
import NeNeGambitTerminal
import Testing

/// 端末へ書くバイト列とキー入力・カーソル位置の報告の読み取り（端末そのものは使わない）。
struct TerminalTests {
    static func text(_ bytes: [UInt8]) -> String {
        String(decoding: bytes, as: UTF8.self)
    }

    static func grid(_ glyphs: GlyphSet, size: ScreenSize = TableRenderer.largeSize) -> Grid {
        let options = DisplayOptions(glyphs: glyphs, theme: .standard, frame: .boxDrawing, colors: .trueColor)
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

    @Test func resizedFrameIsRedrawnInFull() {
        let small = Self.grid(.letters, size: ScreenSize(columns: 10, rows: 2))
        let text = Self.text(FrameEncoder.encode(Self.grid(.letters), previous: small, colors: .trueColor))
        #expect(text.hasPrefix("\u{1B}[0m\u{1B}[2J"))
    }
}
