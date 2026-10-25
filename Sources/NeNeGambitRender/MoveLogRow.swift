import NeNeGambitCore

/// 棋譜の 1 行（`06.  Bxc6     e5`）。白黒 1 手ずつで、続いている局では手番の側の空きにカーソルを置く。
struct MoveLogRow: Sendable, Hashable {
    let number: String
    let white: String
    let black: String
    let cursor: LogCursor

    /// 直近の `count` 行。
    static func recent(_ game: Game, count: Int) -> [MoveLogRow] {
        guard count > 0 else {
            return []
        }
        let firstPly = max(0, game.moves.count - count * 2 - 1)
        var rows: [MoveLogRow] = []
        for ply in firstPly..<game.moves.count {
            let before = game.positionsBeforeMoves[ply]
            let san = MoveNotation.san(game.moves[ply], in: before)
            if before.sideToMove == .black, let last = rows.popLast() {
                rows.append(MoveLogRow(number: last.number, white: last.white, black: san, cursor: .none))
            } else {
                let isWhite = before.sideToMove == .white
                rows.append(
                    MoveLogRow(
                        number: label(before.clocks.fullmove), white: isWhite ? san : "...", black: isWhite ? "" : san,
                        cursor: .none))
            }
        }
        if case .ongoing = game.status {
            rows = withCursor(rows, position: game.position)
        }
        return Array(rows.suffix(count))
    }

    private static func label(_ fullmove: Int) -> String {
        Wording.padded(fullmove, width: 2) + "."
    }

    private static func withCursor(_ rows: [MoveLogRow], position: Position) -> [MoveLogRow] {
        var result = rows
        if position.sideToMove == .black, let last = result.popLast() {
            result.append(MoveLogRow(number: last.number, white: last.white, black: "", cursor: .black))
        } else {
            result.append(MoveLogRow(number: label(position.clocks.fullmove), white: "", black: "", cursor: .white))
        }
        return result
    }
}
