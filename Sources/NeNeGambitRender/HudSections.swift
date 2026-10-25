import NeNeGambitCore
import NeNeGambitEngine

/// HUD のパネルの各段（MATCH・SCORE・LOG・RESULT）の行を作る。
struct HudSections: Sendable {
    let state: ScreenState
    let panel: Panel

    private var theme: Theme {
        state.options.theme
    }

    private var game: Game {
        state.series.game
    }

    /// MATCH: 局の番号・白黒の性格・手番。
    func match() -> [[Segment]] {
        let series = state.series
        return [
            panel.header(Wording.match, title: theme.accent, frame: theme.frame, first: true),
            row([Segment(Wording.gameLabel, theme.dim), Segment(Wording.gameNumber(series.gameNumber), theme.text)]),
            row([Segment(Wording.whiteLabel, theme.dim), Segment(series.players.white.handle, theme.whitePiece)]),
            row([Segment(Wording.blackLabel, theme.dim), Segment(series.players.black.handle, theme.blackPiece)]),
            row([Segment(Wording.turnLabel, theme.dim)] + turn()),
        ]
    }

    /// 手番（終局していれば `--`）と手数。
    func turn() -> [Segment] {
        let position = game.position
        let side: Segment
        switch game.status {
        case .ongoing:
            side = Segment(Wording.side(position.sideToMove), color(of: position.sideToMove))
        case .finished:
            side = Segment(Wording.noTurn, theme.dim)
        }
        return [side, Segment(Wording.moveNumber(position.clocks.fullmove), theme.dim)]
    }

    /// SCORE: 白勝ち・黒勝ち・引き分けの棒（通算の局数に対する割合）。
    func score() -> [[Segment]] {
        let tally = state.series.tally
        return [
            panel.header(Wording.score, title: theme.accent, frame: theme.frame, first: false),
            scoreRow(.whiteWins, tally.whiteWins, tag: theme.whitePiece, fill: theme.accent),
            scoreRow(.blackWins, tally.blackWins, tag: theme.blackPiece, fill: theme.accentAlt),
            scoreRow(.draw, tally.draws, tag: theme.dim, fill: theme.dim),
        ]
    }

    private func scoreRow(_ result: GameResult, _ count: Int, tag: Rgb, fill: Rgb) -> [Segment] {
        let total = state.series.tally.finishedGames
        return row(
            [Segment(Wording.scoreTag(result), tag)]
                + panel.bar(Fraction(value: count, total: total), cells: 20, fill: fill, frame: theme.frame)
                + [Segment("  " + Wording.padded(count, width: 2), theme.text)])
    }

    /// LOG: 直近の棋譜を `count` 行（足りない分は空の行）。
    func log(rows count: Int) -> [[Segment]] {
        let cursor = Segment(panel.glyphs.cursor, theme.accent)
        let lines = MoveLogRow.recent(game, count: count).map { entry -> [Segment] in
            let white = entry.cursor == .white ? [cursor] : [Segment(entry.white, theme.whitePiece)]
            let gap = String(repeating: " ", count: max(9 - (entry.cursor == .white ? 1 : entry.white.count), 1))
            let black = entry.cursor == .black ? [cursor] : [Segment(entry.black, theme.blackPiece)]
            return row([Segment(entry.number + "  ", theme.dim)] + white + [Segment(gap, theme.dim)] + black)
        }
        let empty = Array(repeating: row([]), count: max(count - lines.count, 0))
        return [panel.header(Wording.log, title: theme.accent, frame: theme.frame, first: false)] + lines + empty
    }

    /// RESULT: 勝敗・理由・次の局までの秒読み。終局していなければ空。
    func result() -> [[Segment]] {
        guard case .finished(let termination) = game.status else {
            return []
        }
        let frame = theme.accentAlt
        var rows = [
            panel.header(Wording.result, title: theme.accentAlt, frame: frame, first: false),
            panel.row([Segment(Wording.headline(termination), theme.accentAlt)], frame: frame),
            panel.row(
                [
                    Segment(Wording.reason(termination), theme.text),
                    Segment(Wording.moveNumber(game.position.clocks.fullmove), theme.dim),
                ],
                frame: frame),
        ]
        if let countdown = state.countdown {
            let share = Fraction(value: countdown.remaining, total: countdown.total)
            let bar = panel.bar(share, cells: 15, fill: theme.accent, frame: theme.frame)
            let seconds = Segment("  " + Wording.seconds(countdown.remaining), theme.accent)
            rows.append(panel.row([Segment(Wording.nextGame, theme.dim)] + bar + [seconds], frame: frame))
        } else {
            rows.append(panel.row([], frame: frame))
        }
        return rows
    }

    /// 縮小版の MATCH（題に局の番号・1 行に白黒の性格・手番・通算）。
    func compactMatch() -> [[Segment]] {
        let series = state.series
        let tally = series.tally
        let title = Wording.match + " " + Wording.gameNumber(series.gameNumber)
        return [
            panel.header(title, title: theme.accent, frame: theme.frame, first: true),
            row([
                Segment("W ", theme.dim), Segment(series.players.white.handle, theme.whitePiece),
                Segment("  vs  B ", theme.dim), Segment(series.players.black.handle, theme.blackPiece),
            ]),
            row([Segment("TURN ", theme.dim)] + turn()),
            row([
                Segment(Wording.score + "  ", theme.dim),
                Segment(
                    Wording.scoreTag(.whiteWins) + Wording.padded(tally.whiteWins, width: 2) + "  ", theme.whitePiece),
                Segment(
                    Wording.scoreTag(.blackWins) + Wording.padded(tally.blackWins, width: 2) + "  ", theme.blackPiece),
                Segment(Wording.scoreTag(.draw) + Wording.padded(tally.draws, width: 2), theme.dim),
            ]),
        ]
    }

    func row(_ content: [Segment]) -> [Segment] {
        panel.row(content, frame: theme.frame)
    }

    func color(of side: Color) -> Rgb {
        side == .white ? theme.whitePiece : theme.blackPiece
    }
}
