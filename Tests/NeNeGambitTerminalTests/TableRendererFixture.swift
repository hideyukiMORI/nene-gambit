import NeNeGambitEngine

/// 端末のテストで描く対局の列（格子を作るには Render の入力の `GameSeries` が要る・ADR 0006）。
enum TableRendererFixture {
    static let series: GameSeries = {
        var generator = SplitMix64(seed: 1)
        return GameSeries.starting(using: &generator)
    }()
}
