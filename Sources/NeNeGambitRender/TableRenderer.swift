import NeNeGambitCore
import NeNeGambitEngine

/// 対局の列と端末の大きさから、1 画面分のセルの格子を作る（ARC-011: 値を作るだけで端末を知らない）。
///
/// 配置: 左に盤（1 升 3 桁 × 1 行・8 段目が上）、右に HUD（FR-10）。盤と HUD が入らない大きさなら 1 行の文言だけを出す。
public enum TableRenderer {
    static let squareWidth = 3
    static let boardColumn = 4
    static let boardRow = 1
    static let hudColumn = 33
    static let hudWidth = 34
    static let recentMoveLines = 4
    /// 盤と HUD がちょうど入る大きさ。
    public static let minimumSize = ScreenSize(columns: hudColumn + hudWidth, rows: 15)

    /// 1 画面分の格子。
    public static func render(_ series: GameSeries, glyphs: GlyphSet, size: ScreenSize) -> Grid {
        let theme = Theme.wood
        let blank = Cell(character: " ", foreground: theme.text, background: theme.background)
        var grid = Grid.filled(size, with: blank)
        guard size.columns >= minimumSize.columns, size.rows >= minimumSize.rows else {
            let message = Wording.tooSmall(need: minimumSize)
            grid.write(
                message, column: 0, row: 0, colors: CellColors(foreground: theme.text, background: theme.background))
            return grid
        }
        drawBoard(series.game.position.board, glyphs: glyphs, theme: theme, into: &grid)
        drawHUD(series, theme: theme, into: &grid)
        return grid
    }

    private static func drawBoard(_ board: Board, glyphs: GlyphSet, theme: Theme, into grid: inout Grid) {
        for square in Square.all {
            let row = boardRow + 7 - square.rank
            let column = boardColumn + square.file * squareWidth
            let isLight = (square.file + square.rank) % 2 == 1
            let background = isLight ? theme.lightSquare : theme.darkSquare
            let piece = board[square]
            let glyph = piece.map { glyphs.glyph(for: $0.kind) } ?? " "
            let foreground = piece?.color == .black ? theme.blackPiece : theme.whitePiece
            grid.write(
                " \(glyph) ", column: column, row: row,
                colors: CellColors(foreground: foreground, background: background))
        }
        for square in Square.all where square.file == 0 {
            let label = String(square.name.suffix(1))
            grid.write(
                label, column: boardColumn - 2, row: boardRow + 7 - square.rank,
                colors: CellColors(foreground: theme.dimText, background: theme.background))
        }
        for square in Square.all where square.rank == 0 {
            let label = String(square.name.prefix(1))
            grid.write(
                label, column: boardColumn + square.file * squareWidth + 1, row: boardRow + 8,
                colors: CellColors(foreground: theme.dimText, background: theme.background))
        }
    }

    private static func drawHUD(_ series: GameSeries, theme: Theme, into grid: inout Grid) {
        let game = series.game
        var lines = [
            HUDLine(text: Wording.title, color: theme.accent),
            HUDLine(text: Wording.gameNumber(series.gameNumber), color: theme.text),
            HUDLine(text: Wording.tally(series.tally), color: theme.text),
            HUDLine(text: Wording.turn(game.position), color: theme.text),
            HUDLine(text: Wording.players(series.players), color: theme.text),
            HUDLine(text: "", color: theme.text),
            HUDLine(text: Wording.movesHeading, color: theme.dimText),
        ]
        lines += recentMoves(game).map { HUDLine(text: $0, color: theme.text) }
        if case .finished(let termination) = game.status {
            lines.append(HUDLine(text: "", color: theme.text))
            lines.append(HUDLine(text: Wording.result(termination), color: theme.accent))
        }
        for (offset, line) in lines.enumerated() {
            grid.write(
                line.text, column: hudColumn, row: boardRow + offset,
                colors: CellColors(foreground: line.color, background: theme.background))
        }
    }

    /// 直近の棋譜（手数つきで 1 行に白黒 1 手ずつ・最後の `recentMoveLines` 行）。
    ///
    /// SAN にするのは最後の `recentMoveLines * 2 + 1` 手だけ（長い局でも 1 画面の手間を一定にする）。
    static func recentMoves(_ game: Game) -> [String] {
        let firstPly = max(0, game.moves.count - recentMoveLines * 2 - 1)
        var lines: [String] = []
        for ply in firstPly..<game.moves.count {
            let before = game.positionsBeforeMoves[ply]
            let san = MoveNotation.san(game.moves[ply], in: before)
            if before.sideToMove == .white || lines.isEmpty {
                let dots = before.sideToMove == .white ? "." : "..."
                lines.append("\(before.clocks.fullmove)\(dots) \(san)")
            } else {
                lines[lines.count - 1] += " \(san)"
            }
        }
        return Array(lines.suffix(recentMoveLines))
    }
}
