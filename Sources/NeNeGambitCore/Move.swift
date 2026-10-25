/// 指し手。内部の表記はこれ 1 つ（元の升・先の升・昇格先。UCI 形式と同じ情報）。
///
/// キャスリングは「王が 2 筋動く手」、アンパッサンは「ポーンがアンパッサンの升へ動く手」として表し、
/// 種別は局面から導く。表示用の表記（SAN 等）への変換は Render だけが持つ（ADR 0003）。
/// 指し手は `Position.legalMoves()` からだけ得る。Core の外では作れない。
public struct Move: Sendable, Hashable {
    public let from: Square
    public let to: Square
    /// 昇格先。昇格しない手では nil。
    public let promotion: PromotionKind?

    init(from: Square, to: Square, promotion: PromotionKind? = nil) {
        self.from = from
        self.to = to
        self.promotion = promotion
    }
}
