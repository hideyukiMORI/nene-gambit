/// キャスリングの向き。
public enum CastlingSide: Sendable, Hashable, CaseIterable {
    case kingside
    case queenside

    /// 王の行き先の筋。
    var kingTargetFile: Int {
        switch self {
        case .kingside:
            return 6
        case .queenside:
            return 2
        }
    }

    /// ルークの元の筋。
    var rookHomeFile: Int {
        switch self {
        case .kingside:
            return 7
        case .queenside:
            return 0
        }
    }

    /// ルークの行き先の筋。
    var rookTargetFile: Int {
        switch self {
        case .kingside:
            return 5
        case .queenside:
            return 3
        }
    }
}
