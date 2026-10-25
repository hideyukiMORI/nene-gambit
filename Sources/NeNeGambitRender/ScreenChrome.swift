import NeNeGambitCore
import NeNeGambitEngine

/// 上端の題・盤の下の COMMS・下端のキーのヘルプ。
enum ScreenChrome {
    /// ` ▌NENE//GAMBIT  │  GAME 012  │  SEED 0x…  │  24BIT`
    static func header(_ state: ScreenState, glyphs: FrameGlyphs) -> [Segment] {
        let theme = state.options.theme
        let divider = Segment("  " + glyphs.vertical + "  ", theme.frame)
        return [
            Segment(" " + glyphs.marker + Wording.title, theme.accent), divider,
            Segment(Wording.headerGame(state.series.gameNumber), theme.text), divider,
            Segment(Wording.seed(state.seed), theme.text), divider,
            Segment(Wording.colors(state.options.colors), theme.dim),
        ]
    }

    /// キーのヘルプ（施主の指定: 常に出す）と直前の手。
    static func footer(_ state: ScreenState, glyphs: FrameGlyphs, compact: Bool) -> [Segment] {
        let theme = state.options.theme
        let options = state.options
        var segments = [
            Segment(" " + Wording.quitKey, theme.accent), Segment(Wording.quitName, theme.dim),
            Segment(Wording.glyphKey, theme.accent), Segment(compact ? " " : Wording.glyphName, theme.dim),
            Segment(Wording.glyphs(options.glyphs) + "   ", theme.text),
            Segment(Wording.themeKey, theme.accent), Segment(compact ? " " : Wording.themeName, theme.dim),
            Segment(options.theme.name, theme.text),
        ]
        let game = state.series.game
        if let move = game.moves.last, let before = game.positionsBeforeMoves.last {
            let color = before.sideToMove == .white ? theme.whitePiece : theme.blackPiece
            segments += [
                Segment("   " + glyphs.vertical + "   ", theme.frame), Segment(Wording.lastLabel, theme.dim),
                Segment(MoveNotation.san(move, in: before), color),
                Segment(compact ? "" : "  " + move.from.name + " > " + move.to.name, theme.dim),
            ]
        }
        return segments
    }

    /// COMMS の 2 行（古い方は控えめな色、新しい方は話し手の側の色）。
    static func comms(_ state: ScreenState, glyphs: FrameGlyphs, compact: Bool) -> [[Segment]] {
        let theme = state.options.theme
        let lines = state.series.banter.lines
        return lines.enumerated().map { index, remark in
            let newest = index == lines.count - 1
            let side = remark.side == .white ? theme.whitePiece : theme.blackPiece
            let tag = remark.side == .white ? "W" : "B"
            let handle = compact ? remark.persona.handle + " " : remark.persona.handle.padding(to: 11)
            let lead = compact ? glyphs.marker + tag + " " : glyphs.marker + " " + tag + "  "
            let face = remark.face + (compact ? " " : "  ")
            guard newest else {
                return [Segment(lead + handle + face + remark.text, theme.dim)]
            }
            return [Segment(lead + handle, side), Segment(face, theme.accentAlt), Segment(remark.text, theme.text)]
        }
    }
}

extension String {
    /// 右を空白で埋めて `width` 桁にする（長ければそのまま）。
    func padding(to width: Int) -> String {
        self + String(repeating: " ", count: max(width - count, 0))
    }
}
