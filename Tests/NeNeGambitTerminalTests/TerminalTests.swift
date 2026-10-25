import NeNeGambitRender
import NeNeGambitTerminal
import Testing

/// 端末へ書くバイト列とキー入力の読み取り（端末そのものは使わない）。
struct TerminalTests {
    static let size = TableRenderer.minimumSize

    static func text(_ bytes: [UInt8]) -> String {
        String(decoding: bytes, as: UTF8.self)
    }

    @Test func keysBecomeIntents() {
        #expect(KeyIntent.decode(Array("q".utf8)) == [.quit])
        #expect(KeyIntent.decode(Array("Gxg".utf8)) == [.toggleGlyphs, .toggleGlyphs])
        #expect(KeyIntent.decode([0x1B, UInt8(ascii: "["), UInt8(ascii: "A"), UInt8(ascii: "q")]) == [.quit])
        #expect(KeyIntent.decode([0x1B]).isEmpty)
        #expect(KeyIntent.decode([]).isEmpty)
    }

    @Test func firstFrameClearsAndDrawsEverything() throws {
        let grid = try Self.grid(.letters)
        let bytes = FrameEncoder.encode(grid, previous: nil, colors: .trueColor)
        let text = Self.text(bytes)
        #expect(text.hasPrefix("\u{1B}[0m\u{1B}[2J"))
        #expect(text.contains("\u{1B}[38;2;"))
        #expect(text.hasSuffix("\u{1B}[0m"))
    }

    @Test func unchangedFrameWritesNothing() throws {
        let grid = try Self.grid(.letters)
        #expect(FrameEncoder.encode(grid, previous: grid, colors: .trueColor).isEmpty)
    }

    /// 字形を替えると駒の升だけが変わる。差分は全面の書き直しより短く、画面を消さない。
    @Test func changedCellsAreTheOnlyOnesWritten() throws {
        let before = try Self.grid(.letters)
        let after = try Self.grid(.symbols)
        let full = FrameEncoder.encode(after, previous: nil, colors: .trueColor)
        let diff = FrameEncoder.encode(after, previous: before, colors: .trueColor)
        #expect(!diff.isEmpty)
        #expect(diff.count < full.count)
        #expect(!Self.text(diff).contains("\u{1B}[2J"))
        #expect(Self.text(diff).contains("\u{265A}"))
    }

    @Test func palette256IsUsedWithoutTrueColor() throws {
        let text = Self.text(FrameEncoder.encode(try Self.grid(.letters), previous: nil, colors: .palette256))
        #expect(text.contains("\u{1B}[38;5;"))
        #expect(!text.contains("38;2;"))
    }

    @Test func resizedFrameIsRedrawnInFull() throws {
        let small = TableRenderer.render(
            TableRendererFixture.series, glyphs: .letters, size: ScreenSize(columns: 10, rows: 2))
        let text = Self.text(FrameEncoder.encode(try Self.grid(.letters), previous: small, colors: .trueColor))
        #expect(text.hasPrefix("\u{1B}[0m\u{1B}[2J"))
    }

    static func grid(_ glyphs: GlyphSet) throws -> Grid {
        TableRenderer.render(TableRendererFixture.series, glyphs: glyphs, size: size)
    }
}
