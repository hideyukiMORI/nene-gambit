/// 駒と手番の色。
public enum Color: Sendable, Hashable, CaseIterable {
    case white
    case black

    /// 相手の色。
    public var opponent: Color {
        switch self {
        case .white:
            return .black
        case .black:
            return .white
        }
    }

    /// ポーンが進む向き（段の増える向きが +1）。
    var forward: Int {
        switch self {
        case .white:
            return 1
        case .black:
            return -1
        }
    }

    /// 自陣の最下段（0 = 1 段目）。
    var homeRank: Int {
        switch self {
        case .white:
            return 0
        case .black:
            return 7
        }
    }
}
