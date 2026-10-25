/// 局面が持つ「特殊な手を指す権利」: キャスリング権と、アンパッサンで取れる升。
public struct SpecialMoveRights: Sendable, Hashable {
    public let castling: CastlingRights
    /// 直前の手でポーンが 2 升進んだときに通り過ぎた升。無ければ nil。
    public let enPassant: Square?
}
