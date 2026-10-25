/// 同一局面の判定に使う局面の同一性: 駒の配置・手番・キャスリング権・**実際に取れる**アンパッサン。
///
/// 手数の時計は含めない。アンパッサンの升は、その升へ取る合法手があるときだけ数える
/// （2 升進んだだけで取れる駒が無いなら、局面は進む前と同じとみなす）。
struct RepetitionKey: Sendable, Hashable {
    let board: Board
    let sideToMove: Color
    let castling: CastlingRights
    let enPassant: Square?

    init(_ position: Position) {
        board = position.board
        sideToMove = position.sideToMove
        castling = position.rights.castling
        let target = position.rights.enPassant
        let capturable = target.map { square in
            position.legalMoves().contains { move in
                move.to == square && position.board[move.from]?.kind == .pawn && move.from.file != square.file
            }
        }
        enPassant = capturable == true ? target : nil
    }
}
