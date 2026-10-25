import NeNeGambitCore
import Testing

/// 局面の不変条件（2-2）。
struct PositionTests {
    /// 指し手の適用は値の意味で、元の局面を変えない。「戻す」は元の値を持っていることで成り立つ（ADR 0003）。
    @Test func applyingLeavesTheOriginalUntouched() throws {
        let original = try PerftTests.decode("r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1")
        let copy = original
        let before = FENCodec.encode(original)
        for move in original.legalMoves() {
            _ = original.applying(move)
        }
        #expect(original == copy)
        #expect(FENCodec.encode(original) == before)
    }

    @Test func foolsMateIsCheckmateForBlack() throws {
        let position = try PerftTests.decode("rnb1kbnr/pppp1ppp/8/4p3/6Pq/5P2/PPPPP2P/RNBQKBNR w KQkq - 1 3")
        #expect(position.isInCheck)
        #expect(position.status == .checkmate(winner: .black))
    }

    @Test func cornerKingWithoutMovesIsStalemate() throws {
        let position = try PerftTests.decode("7k/5Q2/6K1/8/8/8/8/8 b - - 0 1")
        #expect(!position.isInCheck)
        #expect(position.status == .stalemate)
    }

    @Test func initialPositionIsOngoing() {
        #expect(Position.initial.status == .ongoing)
    }

    /// 深さ 4 の葉のうちチェックメイトの局面の数を公表値と突き合わせる（合法手 0 で王手＝メイトの判定の確認）。
    ///
    /// 出典は PerftTests と同じ Chess Programming Wiki「Perft Results」の Checkmates の列
    /// （初期局面: 深さ 3 で 0・深さ 4 で 8。Kiwipete: 深さ 3 で 1）。
    @Test(arguments: [
        ("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1", 3, 0),
        ("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1", 4, 8),
        ("r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1", 3, 1),
    ])
    func checkmateLeavesMatchPublishedCounts(fen: String, depth: Int, mates: Int) throws {
        var frontier = [try PerftTests.decode(fen)]
        for _ in 0..<depth {
            frontier = frontier.flatMap { position in position.legalMoves().map { position.applying($0) } }
        }
        let counted = frontier.filter { position in
            if case .checkmate = position.status {
                return true
            }
            return false
        }
        #expect(counted.count == mates)
    }

    @Test func doublePushSetsEnPassantAndClocks() throws {
        let start = Position.initial
        let e2 = Square.at(file: 4, rank: 1)
        let e4 = Square.at(file: 4, rank: 3)
        let push = try #require(start.legalMoves().first { $0.from == e2 && $0.to == e4 })
        let next = start.applying(push)
        #expect(FENCodec.encode(next) == "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1")
    }
}
