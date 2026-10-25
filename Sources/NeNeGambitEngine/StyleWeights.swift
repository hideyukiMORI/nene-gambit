/// 評価の重み（性格ごとに違う）。単位はセンチポーン（ポーン 1 枚 = 100）の倍率。
struct StyleWeights: Sendable, Hashable {
    /// 小駒とクイーンが中央にいる価値。
    let center: Int
    /// ポーンが前へ進んだ価値。
    let pawnAdvance: Int
    /// 中盤に王が自陣の隅に収まっている価値。
    let kingShelter: Int
    /// 駒が相手の王に近い価値（攻め気）。
    let aggression: Int
}
