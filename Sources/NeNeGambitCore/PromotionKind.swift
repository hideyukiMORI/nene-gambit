/// ポーンが昇格できる駒の種類（4 種）。
public enum PromotionKind: Sendable, Hashable, CaseIterable {
    case knight
    case bishop
    case rook
    case queen

    /// 昇格した後の駒の種類。
    public var pieceKind: PieceKind {
        switch self {
        case .knight:
            return .knight
        case .bishop:
            return .bishop
        case .rook:
            return .rook
        case .queen:
            return .queen
        }
    }
}
