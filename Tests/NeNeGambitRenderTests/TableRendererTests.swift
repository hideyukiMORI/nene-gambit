import NeNeGambitCore
import NeNeGambitEngine
import NeNeGambitRender
import Testing

/// 画面の格子（FR-01・FR-07・FR-10）と棋譜の表記。
struct TableRendererTests {
    static let series = GameSeries.starting(Players(white: .random, black: .random))

    /// 格子の 1 行を文字列として読む。
    static func line(_ grid: Grid, _ row: Int) -> String {
        String((0..<grid.size.columns).map { grid[$0, row].character })
    }

    @Test func boardHasRankEightOnTopAndLettersByDefault() {
        let grid = TableRenderer.render(Self.series, glyphs: .letters, size: TableRenderer.minimumSize)
        #expect(Self.line(grid, 1).hasPrefix("  8  R  N  B  Q  K  B  N  R "))
        #expect(Self.line(grid, 8).hasPrefix("  1  R  N  B  Q  K  B  N  R "))
        #expect(Self.line(grid, 9).hasPrefix("     a  b  c  d  e  f  g  h"))
    }

    @Test func whiteAndBlackDifferOnlyByColor() {
        let grid = TableRenderer.render(Self.series, glyphs: .letters, size: TableRenderer.minimumSize)
        let blackKing = grid[4 + 4 * 3 + 1, 1]
        let whiteKing = grid[4 + 4 * 3 + 1, 8]
        #expect(blackKing.character == whiteKing.character)
        #expect(blackKing.foreground != whiteKing.foreground)
    }

    @Test func symbolsReplaceLetters() {
        let grid = TableRenderer.render(Self.series, glyphs: .symbols, size: TableRenderer.minimumSize)
        #expect(grid[4 + 4 * 3 + 1, 8].character == "\u{265A}")
        #expect(GlyphSet.letters.toggled == .symbols)
        #expect(GlyphSet.symbols.toggled == .letters)
    }

    @Test func hudShowsGameTallyTurnAndPlayers() {
        let grid = TableRenderer.render(Self.series, glyphs: .letters, size: TableRenderer.minimumSize)
        let hud = (1...7).map { Self.line(grid, $0) }.joined(separator: "\n")
        #expect(hud.contains("Game 1"))
        #expect(hud.contains("White 0  Black 0  Draws 0"))
        #expect(hud.contains("White to move, move 1"))
        #expect(hud.contains("White: Random  Black: Random"))
    }

    @Test func tooSmallScreenShowsOneLine() {
        let size = ScreenSize(columns: 40, rows: 10)
        let grid = TableRenderer.render(Self.series, glyphs: .letters, size: size)
        #expect(Self.line(grid, 0).hasPrefix("Terminal too small (need 67x15)"))
        #expect(Self.line(grid, 1).allSatisfy { $0 == " " })
    }

    @Test func zeroSizeDoesNotCrash() {
        let grid = TableRenderer.render(Self.series, glyphs: .letters, size: ScreenSize(columns: 0, rows: -3))
        #expect(grid.size == ScreenSize(columns: 0, rows: 0))
    }

    /// SAN の表記（キャスリング・アンパッサン・昇格・王手・メイト・曖昧さの解消）。
    @Test(arguments: [
        ("r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1", "e1", "g1", "O-O"),
        ("r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1", "e1", "c1", "O-O-O"),
        ("4k3/8/8/3pP3/8/8/8/4K3 w - d6 0 1", "e5", "d6", "exd6"),
        ("8/4P3/8/8/8/8/k7/4K3 w - - 0 1", "e7", "e8", "e8=Q"),
        ("4k3/8/8/8/8/8/8/R3K1R1 w - - 0 1", "a1", "a8", "Ra8+"),
        ("rnbqkbnr/pppp1ppp/8/4p3/6P1/5P2/PPPPP2P/RNBQKBNR b KQkq - 0 2", "d8", "h4", "Qh4#"),
        ("4k3/8/8/8/8/8/8/1N2KN2 w - - 0 1", "b1", "d2", "Nbd2"),
        ("4k3/8/8/8/8/8/8/1N2KN2 w - - 0 1", "e1", "d1", "Kd1"),
    ])
    func sanMatchesTheStandard(fen: String, from: String, to: String, expected: String) throws {
        guard case .decoded(let position) = FENCodec.decode(fen) else {
            Issue.record("FEN を読めない")
            return
        }
        let candidates = position.legalMoves().filter { $0.from.name == from && $0.to.name == to }
        let move = try #require(candidates.first { $0.promotion == nil || $0.promotion == .queen })
        #expect(MoveNotation.san(move, in: position) == expected)
    }

    /// 棋譜の行は「手数. 白 黒」で、最後の 4 行だけを出す。
    @Test func recentMovesShowNumberedPairs() throws {
        var generator = SplitMix64(seed: 5)
        var series = Self.series
        for _ in 0..<12 {
            series = series.advanced(using: &generator)
        }
        let grid = TableRenderer.render(series, glyphs: .letters, size: TableRenderer.minimumSize)
        let lines = (8...11).map { Self.line(grid, $0).dropFirst(33).prefix(34).trimmingCharacters() }
        #expect(lines.map { $0.split(separator: " ").first.map(String.init) } == ["3.", "4.", "5.", "6."])
    }
}

extension Substring {
    /// 末尾の空白を落とす（Foundation を使わない）。
    func trimmingCharacters() -> String {
        String(self.reversed().drop { $0 == " " }.reversed())
    }
}
