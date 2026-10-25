import NeNeGambitCore
import NeNeGambitEngine
import Testing

/// 評価と探索（FR-03・FR-06）。
struct SearchTests {
    static func position(_ fen: String) throws -> Position {
        guard case .decoded(let position) = FENCodec.decode(fen) else {
            Issue.record("FEN を読めない: \(fen)")
            return try #require(nil as Position?)
        }
        return position
    }

    /// 探索が返す手は必ず合法手の中にある（2-2 の不変条件）。4 名それぞれ、序盤・中盤・終盤の局面で。
    @Test(arguments: Persona.allCases)
    func everyPersonaPlaysOnlyLegalMoves(persona: Persona) throws {
        var generator = SplitMix64(seed: 17)
        for fen in [
            "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
            "r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1",
            "8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 1",
        ] {
            let game = Game.starting(from: try Self.position(fen))
            let move = try #require(persona.choose(in: game, using: &generator))
            #expect(game.position.legalMoves().contains(move))
        }
    }

    /// 1 手詰めがあれば指す（スカラーズ・メイトの Qxf7#）。
    @Test(arguments: Persona.allCases)
    func everyPersonaFindsMateInOne(persona: Persona) throws {
        var generator = SplitMix64(seed: 2)
        let game = Game.starting(
            from: try Self.position("r1bqkb1r/pppp1ppp/2n2n2/4p2Q/2B1P3/8/PPPP1PPP/RNB1K1NR w KQkq - 4 4"))
        let move = try #require(persona.choose(in: game, using: &generator))
        #expect(game.playing(move).status == .finished(.checkmate(winner: .white)))
    }

    /// 王とクイーン対王・王とルーク対王を、50 手ルールに届く前にチェックメイトする（施主の観察「逃げ続けて終わらない」への対応）。
    @Test(arguments: [
        "8/8/8/4k3/8/8/8/3QK3 w - - 0 1",
        "8/8/8/3k4/8/8/8/R3K3 w - - 0 1",
    ])
    func strongSideMatesTheLoneKing(fen: String) throws {
        var generator = SplitMix64(seed: 5)
        var game = Game.starting(from: try Self.position(fen))
        while case .ongoing = game.status, game.moves.count < 200 {
            let mover: Persona = game.position.sideToMove == .white ? .granny : .mort
            game = game.playing(try #require(mover.choose(in: game, using: &generator)))
        }
        #expect(game.status == .finished(.checkmate(winner: .white)), "\(game.status) after \(game.moves.count) plies")
    }

    /// 同じシードの乱数源からは同じ手が出る。
    @Test func sameSeedGivesTheSameMoves() {
        func line(seed: UInt64) -> [Move] {
            var generator = SplitMix64(seed: seed)
            var series = GameSeries.starting(using: &generator)
            for _ in 0..<24 {
                series = series.advanced(using: &generator)
            }
            return series.game.moves
        }
        #expect(line(seed: 31) == line(seed: 31))
    }
}
