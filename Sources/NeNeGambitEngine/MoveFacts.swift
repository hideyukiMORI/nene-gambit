import NeNeGambitCore

/// 1 手で起きたこと（発言のきっかけを選ぶための事実）。
struct MoveFacts: Sendable {
    let mover: Color
    /// 取られた駒（アンパッサンを含む）。取らなければ nil。
    let captured: PieceKind?
    let isEnPassant: Bool
    let isCastle: Bool
    let isPromotion: Bool
    let givesCheck: Bool
    /// 手を指した後の半手の時計（ポーンが動かず駒も取られていない半手の数）。
    let quietPlies: Int

    init(before: Position, move: Move, after: Position) {
        let piece = before.board[move.from]
        let isPawn = piece?.kind == .pawn
        let diagonal = move.from.file != move.to.file
        mover = before.sideToMove
        isEnPassant = isPawn && diagonal && before.board[move.to] == nil
        captured = isEnPassant ? .pawn : before.board[move.to]?.kind
        isCastle = piece?.kind == .king && abs(move.to.file - move.from.file) == 2
        isPromotion = move.promotion != nil
        givesCheck = after.isInCheck
        quietPlies = after.clocks.halfmove
    }
}
