/// 盤上の駒から見た「チェックメイトできる駒があるか」の判定。
///
/// 駒不足とみなすのは次だけ: 王と王、王と小駒 1 つ（ナイトかビショップ）と王、
/// ビショップがすべて同じ色の升にいて他に駒が無いとき。それ以外は駒が足りるとみなす。
struct MaterialBalance: Sendable {
    private let others: [Piece]
    private let bishopSquareColors: Set<Int>

    init(_ board: Board) {
        var others: [Piece] = []
        var colors = Set<Int>()
        for square in Square.all {
            guard let piece = board[square], piece.kind != .king else {
                continue
            }
            others.append(piece)
            if piece.kind == .bishop {
                colors.insert((square.file + square.rank) % 2)
            }
        }
        self.others = others
        bishopSquareColors = colors
    }

    var isInsufficient: Bool {
        if others.isEmpty {
            return true
        }
        if others.count == 1, let only = others.first, only.kind == .knight || only.kind == .bishop {
            return true
        }
        return others.allSatisfy { $0.kind == .bishop } && bishopSquareColors.count == 1
    }
}
