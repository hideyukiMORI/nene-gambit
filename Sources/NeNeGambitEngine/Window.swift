/// アルファベータ探索の窓（手番の側から見た下限と上限）。
struct Window: Sendable, Hashable {
    let alpha: Int
    let beta: Int

    /// 相手の手番から見た窓（符号と上下を入れ替える）。
    var flipped: Window {
        Window(alpha: -beta, beta: -alpha)
    }

    /// 下限を引き上げた窓。
    func raising(to value: Int) -> Window {
        Window(alpha: max(alpha, value), beta: beta)
    }
}
