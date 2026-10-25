import NeNeGambitCore

/// 1 升の見た目（駒・直前の手の印・背景の色）。
struct SquareLook: Sendable, Hashable {
    let piece: Piece?
    let hot: Bool
    let background: Rgb
}
