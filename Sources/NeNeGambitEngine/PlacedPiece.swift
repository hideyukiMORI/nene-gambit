import NeNeGambitCore

/// 盤上の駒とその升。
struct PlacedPiece: Sendable, Hashable {
    let square: Square
    let piece: Piece
}
