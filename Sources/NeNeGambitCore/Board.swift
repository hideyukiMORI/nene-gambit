/// 64 升の駒の配置。空の升は nil（「駒が無い」だけを意味する）。
///
/// 盤の表現はこの 1 つ（64 升の値型の配列・ADR 0003）。値型なので、指し手を適用した局面は複製から作り、元は変わらない。
public struct Board: Sendable, Hashable {
    private var cells: InlineArray<64, Piece?>

    /// 駒の無い盤。
    public static let empty = Board(cells: InlineArray(repeating: nil))

    /// その升の駒。空なら nil。
    public subscript(square: Square) -> Piece? {
        cells[square.index]
    }

    /// その升に駒を置いた（nil なら空にした）盤。
    func placing(_ piece: Piece?, at square: Square) -> Board {
        var copy = self
        copy.cells[square.index] = piece
        return copy
    }

    /// その色の王の升。王が盤に無いなら nil（FEN の読み込みが王 1 つずつを保証するので、合法な局面では起きない）。
    func kingSquare(of color: Color) -> Square? {
        Square.all.first { cells[$0.index] == Piece(color, .king) }
    }

    public static func == (lhs: Board, rhs: Board) -> Bool {
        Square.all.allSatisfy { lhs.cells[$0.index] == rhs.cells[$0.index] }
    }

    public func hash(into hasher: inout Hasher) {
        for square in Square.all {
            hasher.combine(cells[square.index])
        }
    }
}
