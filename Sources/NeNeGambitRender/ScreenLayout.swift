import NeNeGambitCore
import NeNeGambitEngine

/// 1 つの配置（大きな盤か縮小版）の、各部品の置き場所と描き方。
struct ScreenLayout: Sendable {
    let board: BoardFrame
    let hudColumn: Int
    let hudWidth: Int
    let hudRows: Int
    let commsRow: Int
    let footerRow: Int
    let isCompact: Bool

    /// 大きな盤（100×30 以上）。駒記号なら 1 升 6 桁、英字なら 7 桁。
    static func large(_ glyphs: GlyphSet) -> ScreenLayout {
        let width = glyphs == .symbols ? 6 : 7
        return ScreenLayout(
            board: BoardFrame(column: 3, row: 2, squareWidth: width, squareHeight: 3), hudColumn: 61, hudWidth: 37,
            hudRows: 24, commsRow: 27, footerRow: 29, isCompact: false)
    }

    /// 縮小版。駒記号なら 1 升 4 桁で盤が 8 桁広くなり、HUD を右へ寄せる。
    static func compact(_ glyphs: GlyphSet) -> ScreenLayout {
        let width = glyphs == .symbols ? 4 : 3
        return ScreenLayout(
            board: BoardFrame(column: 3, row: 2, squareWidth: width, squareHeight: 1), hudColumn: 3 + 8 * width + 4,
            hudWidth: 35, hudRows: 10, commsRow: 12, footerRow: 14, isCompact: true)
    }

    func draw(_ state: ScreenState, into grid: inout Grid) {
        let glyphs = FrameGlyphs.of(state.options.traits.frame)
        let theme = state.options.theme
        grid.write(
            String(repeating: " ", count: grid.size.columns), column: 0, row: 0,
            colors: CellColors(foreground: theme.text, background: theme.panel))
        grid.write(ScreenChrome.header(state, glyphs: glyphs), column: 0, row: 0, background: theme.panel)
        board.draw(state.series.game, options: state.options, into: &grid)
        for (offset, line) in hudLines(state, glyphs: glyphs).prefix(hudRows).enumerated() {
            grid.write(line, column: hudColumn, row: board.row + offset, background: theme.ground)
        }
        for (offset, line) in ScreenChrome.comms(state, glyphs: glyphs, compact: isCompact).enumerated() {
            grid.write(line, column: 0, row: commsRow + offset, background: theme.ground)
        }
        grid.write(
            String(repeating: " ", count: grid.size.columns), column: 0, row: footerRow,
            colors: CellColors(foreground: theme.text, background: theme.panel))
        grid.write(
            ScreenChrome.footer(state, glyphs: glyphs, compact: isCompact), column: 0, row: footerRow,
            background: theme.panel)
    }

    private func hudLines(_ state: ScreenState, glyphs: FrameGlyphs) -> [[Segment]] {
        let sections = HudSections(state: state, panel: Panel(width: hudWidth, glyphs: glyphs))
        let result = sections.result()
        let bottom = sections.panel.footer(
            frame: result.isEmpty ? state.options.theme.frame : state.options.theme.accentAlt)
        if isCompact {
            let top = sections.compactMatch()
            let middle = result.isEmpty ? sections.log(rows: hudRows - top.count - 2) : result
            return top + middle + [bottom]
        }
        let top = sections.match() + sections.score()
        let logRows = hudRows - top.count - result.count - 2
        return top + sections.log(rows: logRows) + result + [bottom]
    }
}
