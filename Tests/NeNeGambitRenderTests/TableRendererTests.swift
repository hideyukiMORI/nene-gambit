import NeNeGambitCore
import NeNeGambitEngine
import NeNeGambitRender
import Testing

/// 画面の格子（FR-01・FR-07・FR-10・FR-13〜15）と棋譜の表記。
struct TableRendererTests {
    static func series(seed: UInt64 = 1) -> GameSeries {
        var generator = SplitMix64(seed: seed)
        return GameSeries.starting(using: &generator)
    }

    static func state(
        _ series: GameSeries, glyphs: GlyphSet = .letters, theme: Theme = .standard, frame: FrameStyle = .boxDrawing
    ) -> ScreenState {
        let traits = TerminalTraits(frame: frame, colors: .trueColor)
        return ScreenState(
            series: series, options: DisplayOptions(glyphs: glyphs, theme: theme, traits: traits), seed: 42,
            countdown: nil)
    }

    /// 駒記号は約 2 桁の幅で描かれる（Issue #13）: 升は偶数桁（大きな盤 6・縮小版 4）で、字形は升の中央の 2 桁、
    /// 右半分のセルには何も書かず、直前の手の括弧はその両隣で升の中に収まる。
    @Test(arguments: [(true, 6), (false, 4)])
    func symbolsSitInTheMiddleTwoCellsOfEvenSquares(large: Bool, width: Int) throws {
        var generator = SplitMix64(seed: 3)
        let series = GameSeries.starting(using: &generator).advanced(using: &generator)
        let move = try #require(series.game.moves.last)
        let size = large ? TableRenderer.largeSize : ScreenSize(columns: 75, rows: 15)
        let grid = TableRenderer.render(Self.state(series, glyphs: .symbols), size: size)
        let left = 3 + move.to.file * width
        let row = large ? 2 + (7 - move.to.rank) * 3 + 1 : 2 + (7 - move.to.rank)
        let start = left + width / 2 - 1
        #expect(!grid[start, row].isWideTail && grid[start + 1, row].isWideTail)
        #expect(start - left == (left + width - 1) - (start + 1), "字形の左右の余白が同じ")
        #expect(grid[start - 1, row].character == "[" && grid[start + 2, row].character == "]")
        #expect(start - 1 >= left && start + 2 < left + width)
    }

    @Test func compactSymbolsNeedSeventyFiveColumns() {
        let grid = TableRenderer.render(Self.state(Self.series(), glyphs: .symbols), size: TableRenderer.minimumSize)
        #expect(Self.line(grid, 0).hasPrefix("TERMINAL TOO SMALL (NEED 75x15)"))
    }

    /// 格子の 1 行を文字列として読む。
    static func line(_ grid: Grid, _ row: Int) -> String {
        String((0..<grid.size.columns).map { grid[$0, row].character })
    }

    static func text(_ grid: Grid) -> String {
        (0..<grid.size.rows).map { line(grid, $0) }.joined(separator: "\n")
    }

    @Test func largeBoardHasRankEightOnTopWithSevenColumnSquares() {
        let grid = TableRenderer.render(Self.state(Self.series()), size: TableRenderer.largeSize)
        let rank8 = Array(Self.line(grid, 3))
        let rank1 = Array(Self.line(grid, 24))
        #expect(rank8[1] == "8" && rank1[1] == "1")
        #expect(String((0..<8).map { rank8[6 + $0 * 7] }) == "RNBQKBNR")
        #expect(String((0..<8).map { rank1[6 + $0 * 7] }) == "RNBQKBNR")
        #expect(grid[6, 3].foreground != grid[6, 24].foreground)
    }

    @Test func headerAndKeyHelpAreAlwaysShown() {
        let grid = TableRenderer.render(Self.state(Self.series()), size: TableRenderer.largeSize)
        let header = Self.line(grid, 0)
        let footer = Self.line(grid, 29)
        #expect(header.contains("NENE//GAMBIT") && header.contains("GAME 001"))
        #expect(header.contains("SEED 0x000000000000002A"))
        #expect(footer.contains("[q] QUIT") && footer.contains("[g] GLYPHS: LETTERS"))
        #expect(footer.contains("[t] THEME: NEON"))
    }

    @Test func hudShowsTheCastAndPanels() {
        let series = Self.series()
        let text = Self.text(TableRenderer.render(Self.state(series), size: TableRenderer.largeSize))
        #expect(text.contains("┌─[ MATCH ]") && text.contains("├─[ SCORE ]") && text.contains("├─[ LOG ]"))
        #expect(text.contains("WHITE     " + series.players.white.handle))
        #expect(text.contains("BLACK     " + series.players.black.handle))
        #expect(text.contains(series.banter.lines[0].text) && text.contains(series.banter.lines[1].text))
    }

    /// HUD のどの行も 37 桁ちょうどで、両端が枠になる。
    @Test func hudRowsAreExactlyThePanelWidth() {
        let grid = TableRenderer.render(Self.state(Self.series()), size: TableRenderer.largeSize)
        for row in 2..<26 {
            let line = Array(Self.line(grid, row))
            #expect("┌│├└".contains(line[61]), "行 \(row) の左端")
            #expect("┐│┤┘".contains(line[97]), "行 \(row) の右端")
        }
    }

    @Test func asciiFrameUsesOnlyAscii() {
        let grid = TableRenderer.render(Self.state(Self.series(), frame: .ascii), size: TableRenderer.largeSize)
        let text = Self.text(grid)
        #expect(text.unicodeScalars.allSatisfy { $0.value < 0x80 })
        #expect(text.contains("+-[ MATCH ]"))
    }

    @Test func compactLayoutFitsTheMinimum() {
        let grid = TableRenderer.render(Self.state(Self.series()), size: TableRenderer.minimumSize)
        let rank8 = Array(Self.line(grid, 2))
        #expect(rank8[1] == "8")
        #expect(String((0..<8).map { rank8[4 + $0 * 3] }) == "RNBQKBNR")
        #expect(Self.line(grid, 2).contains("MATCH 001"))
        #expect(Self.line(grid, 14).contains("[q] QUIT"))
    }

    @Test func symbolsReplaceLetters() {
        let grid = TableRenderer.render(Self.state(Self.series(), glyphs: .symbols), size: TableRenderer.largeSize)
        #expect(grid[3 + 4 * 6 + 2, 24].character == "\u{265A}")
        #expect(GlyphSet.letters.toggled == .symbols)
    }

    @Test func lastMoveIsBracketed() throws {
        var generator = SplitMix64(seed: 3)
        let series = GameSeries.starting(using: &generator).advanced(using: &generator)
        let move = try #require(series.game.moves.last)
        let grid = TableRenderer.render(Self.state(series), size: TableRenderer.largeSize)
        let column = 3 + move.to.file * 7 + 3
        let row = 2 + (7 - move.to.rank) * 3 + 1
        #expect(grid[column - 1, row].character == "[" && grid[column + 1, row].character == "]")
    }

    @Test func tooSmallScreenShowsOneLine() {
        let grid = TableRenderer.render(Self.state(Self.series()), size: ScreenSize(columns: 40, rows: 10))
        #expect(Self.line(grid, 0).hasPrefix("TERMINAL TOO SMALL (NEED 67x15)"))
        #expect(Self.line(grid, 1).allSatisfy { $0 == " " })
    }

    @Test func zeroSizeDoesNotCrash() {
        let grid = TableRenderer.render(Self.state(Self.series()), size: ScreenSize(columns: 0, rows: -3))
        #expect(grid.size == ScreenSize(columns: 0, rows: 0))
    }

    @Test func themesCycleThroughTwelve() {
        #expect(Theme.catalog.count == 12)
        #expect(Set(Theme.catalog.map(\.name)).count == 12)
        var theme = Theme.standard
        for _ in 0..<12 {
            theme = theme.next
        }
        #expect(theme == Theme.standard)
        #expect(Theme.named("amber")?.name == "AMBER")
        #expect(Theme.named("plaid") == nil)
    }

    /// どのテーマでも、文字（英数字）は背景に対して 4.5:1 以上、白黒の駒は明るさで 2.2:1 以上離れる。
    @Test(arguments: Theme.catalog.map(\.name))
    func everyThemeIsReadable(name: String) throws {
        let theme = try #require(Theme.named(name))
        var generator = SplitMix64(seed: 8)
        var series = GameSeries.starting(using: &generator)
        for _ in 0..<30 {
            series = series.advanced(using: &generator)
        }
        let grid = TableRenderer.render(Self.state(series, theme: theme), size: TableRenderer.largeSize)
        for row in 0..<grid.size.rows {
            for column in 0..<grid.size.columns {
                let cell = grid[column, row]
                guard cell.character.isLetter || cell.character.isNumber else {
                    continue
                }
                let ratio = Contrast.ratio(cell.foreground, cell.background)
                #expect(ratio >= 4.5, "\(name) \(column),\(row) '\(cell.character)' \(ratio)")
            }
        }
        let start = TableRenderer.render(Self.state(Self.series(), theme: theme), size: TableRenderer.largeSize)
        #expect(Contrast.ratio(start[6, 24].foreground, start[6, 3].foreground) >= 2.2, "\(name) 白黒の駒")
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

    /// 棋譜の行は「手数. 白 黒」で、手番の側にカーソルを置く。
    @Test func moveLogShowsNumberedPairsAndCursor() {
        var generator = SplitMix64(seed: 5)
        var series = GameSeries.starting(using: &generator)
        for _ in 0..<12 {
            series = series.advanced(using: &generator)
        }
        let text = Self.text(TableRenderer.render(Self.state(series), size: TableRenderer.largeSize))
        #expect(text.contains("│ 01.  ") && text.contains("│ 06.  "))
        #expect(text.contains("│ 07.  ▌"))
    }
}
