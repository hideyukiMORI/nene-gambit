import NeNeGambitCore

/// 指し手の表示用の表記（SAN: `Nf3` / `exd6` / `O-O` / `e8=Q+` / `Qh4#`）。
///
/// 指し手の内部表記は Core の `Move` 1 つで、表示用の表記への変換はここだけが持つ（ADR 0003）。
/// 表記は Render が出す値そのものなので公開する（画面の棋譜もこれを使う）。
public enum MoveNotation {
    /// `move` を `position` で指したときの SAN。`move` は `position.legalMoves()` の手であること。
    public static func san(_ move: Move, in position: Position) -> String {
        guard let piece = position.board[move.from] else {
            return "?"
        }
        let body: String
        if piece.kind == .king, abs(move.to.file - move.from.file) == 2 {
            body = move.to.file > move.from.file ? "O-O" : "O-O-O"
        } else {
            body = ordinary(move, piece: piece, in: position)
        }
        return body + suffix(after: position.applying(move))
    }

    private static func ordinary(_ move: Move, piece: Piece, in position: Position) -> String {
        let isCapture = position.board[move.to] != nil || (piece.kind == .pawn && move.from.file != move.to.file)
        let prefix: String
        if piece.kind == .pawn {
            prefix = isCapture ? String(move.from.name.prefix(1)) : ""
        } else {
            prefix = letter(piece.kind) + disambiguation(move, kind: piece.kind, in: position)
        }
        let promotion = move.promotion.map { "=" + letter($0.pieceKind) } ?? ""
        return prefix + (isCapture ? "x" : "") + move.to.name + promotion
    }

    /// 同じ種類の駒が同じ升へ行けるとき、筋、段、両方の順で足りる分だけ足す。
    private static func disambiguation(_ move: Move, kind: PieceKind, in position: Position) -> String {
        let rivals = position.legalMoves().filter { other in
            other.to == move.to && other.from != move.from && position.board[other.from]?.kind == kind
        }
        if rivals.isEmpty {
            return ""
        }
        if !rivals.contains(where: { $0.from.file == move.from.file }) {
            return String(move.from.name.prefix(1))
        }
        if !rivals.contains(where: { $0.from.rank == move.from.rank }) {
            return String(move.from.name.suffix(1))
        }
        return move.from.name
    }

    private static func suffix(after next: Position) -> String {
        switch next.status {
        case .checkmate:
            return "#"
        case .stalemate, .ongoing:
            return next.isInCheck ? "+" : ""
        }
    }

    private static func letter(_ kind: PieceKind) -> String {
        switch kind {
        case .king:
            return "K"
        case .queen:
            return "Q"
        case .rook:
            return "R"
        case .bishop:
            return "B"
        case .knight:
            return "N"
        case .pawn:
            return ""
        }
    }
}
