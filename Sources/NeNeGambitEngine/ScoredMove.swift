import NeNeGambitCore

/// 探索の根で評価した手。
struct ScoredMove: Sendable, Hashable {
    let move: Move
    let score: Int
}
