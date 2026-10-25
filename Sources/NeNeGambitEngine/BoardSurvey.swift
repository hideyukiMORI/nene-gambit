import NeNeGambitCore

/// 評価のために盤を 1 回なめて集めた事実（駒の位置・王の升・駒の価値の合計・終盤かどうか）。
struct BoardSurvey: Sendable {
    let pieces: [PlacedPiece]
    let whiteKing: Square?
    let blackKing: Square?
    let isEndgame: Bool

    init(_ board: Board) {
        var pieces: [PlacedPiece] = []
        var whiteKing: Square?
        var blackKing: Square?
        var queens = 0
        var minorsAndRooks = 0
        for square in Square.all {
            guard let piece = board[square] else {
                continue
            }
            pieces.append(PlacedPiece(square: square, piece: piece))
            if piece.kind == .king {
                if piece.color == .white { whiteKing = square } else { blackKing = square }
            }
            queens += piece.kind == .queen ? 1 : 0
            minorsAndRooks += [.knight, .bishop, .rook].contains(piece.kind) ? 1 : 0
        }
        self.pieces = pieces
        self.whiteKing = whiteKing
        self.blackKing = blackKing
        isEndgame = queens == 0 || minorsAndRooks <= 2
    }

    /// その色の駒の価値の合計（王を除く）。
    func material(_ color: Color) -> Int {
        pieces.filter { $0.piece.color == color }.reduce(0) { $0 + Evaluator.value($1.piece.kind) }
    }

    /// その色のポーンの数。
    func pawns(_ color: Color) -> Int {
        pieces.filter { $0.piece == Piece(color, .pawn) }.count
    }

    /// 中央の 4 升からの距離（0〜3）。
    static func centerDistance(_ square: Square) -> Int {
        max(abs(2 * square.file - 7), abs(2 * square.rank - 7)) / 2
    }

    /// 中央からのマンハッタン距離（1〜7）。
    static func manhattanFromCenter(_ square: Square) -> Int {
        (abs(2 * square.file - 7) + abs(2 * square.rank - 7)) / 2
    }

    static func chebyshev(_ a: Square, _ b: Square) -> Int {
        max(abs(a.file - b.file), abs(a.rank - b.rank))
    }

    static func manhattan(_ a: Square, _ b: Square) -> Int {
        abs(a.file - b.file) + abs(a.rank - b.rank)
    }
}
