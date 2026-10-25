/// 盤の升。a1 が 0、h8 が 63（`index = rank * 8 + file`）。
///
/// 筋（file）は 0 = a 〜 7 = h、段（rank）は 0 = 1 段目 〜 7 = 8 段目。盤の外の升は作れない。
public struct Square: Sendable, Hashable {
    public let index: Int

    private init(index: Int) {
        self.index = index
    }

    /// 64 升すべて（a1, b1, …, h8 の順）。
    public static let all: [Square] = (0..<64).map { Square(index: $0) }

    /// 筋と段から升を作る。盤の外なら nil。
    public static func at(file: Int, rank: Int) -> Square? {
        (0..<8).contains(file) && (0..<8).contains(rank) ? Square(index: rank * 8 + file) : nil
    }

    /// 筋。0 = a 〜 7 = h。
    public var file: Int {
        index % 8
    }

    /// 段。0 = 1 段目 〜 7 = 8 段目。
    public var rank: Int {
        index / 8
    }

    /// 筋と段をずらした升。盤の外へ出たら nil。
    public func offset(file fileStep: Int, rank rankStep: Int) -> Square? {
        Square.at(file: file + fileStep, rank: rank + rankStep)
    }
}
