/// 棒グラフに描く割合（`value / total`）。
struct Fraction: Sendable, Hashable {
    let value: Int
    let total: Int
}
