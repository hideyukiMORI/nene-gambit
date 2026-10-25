/// 局面: 駒の配置・手番・特殊な手の権利・手数の時計。
///
/// 値型で、指し手を適用すると新しい局面を返す（元の局面は変わらない）。合法手の生成・適用・状態の判定は
/// この型の拡張（`Position+MoveGeneration` / `Position+Applying` / `Position+Attacks`）にだけある。
public struct Position: Sendable, Hashable {
    public let board: Board
    public let sideToMove: Color
    public let rights: SpecialMoveRights
    public let clocks: MoveClocks

    init(board: Board, sideToMove: Color, rights: SpecialMoveRights, clocks: MoveClocks) {
        self.board = board
        self.sideToMove = sideToMove
        self.rights = rights
        self.clocks = clocks
    }

    /// 初期局面。
    public static let initial: Position = {
        let back: [PieceKind] = [.rook, .knight, .bishop, .queen, .king, .bishop, .knight, .rook]
        var board = Board.empty
        for file in 0..<8 {
            let column = [
                (0, Piece(.white, back[file])), (1, Piece(.white, .pawn)),
                (6, Piece(.black, .pawn)), (7, Piece(.black, back[file])),
            ]
            for (rank, piece) in column {
                if let square = Square.at(file: file, rank: rank) {
                    board = board.placing(piece, at: square)
                }
            }
        }
        return Position(
            board: board,
            sideToMove: .white,
            rights: SpecialMoveRights(castling: .all, enPassant: nil),
            clocks: MoveClocks(halfmove: 0, fullmove: 1)
        )
    }()

    /// 合法手の有無から決まる状態。
    public var status: PositionStatus {
        guard legalMoves().isEmpty else {
            return .ongoing
        }
        return isInCheck ? .checkmate(winner: sideToMove.opponent) : .stalemate
    }

    /// 手番の側の王が王手されているか。
    public var isInCheck: Bool {
        isKingAttacked(sideToMove)
    }
}
