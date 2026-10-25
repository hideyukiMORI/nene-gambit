import NeNeGambitCore
import Testing

/// 終局の判定（FR-04）。
struct GameTests {
    /// 局面から合法手を SAN 風の「元の升と先の升の名前」で選んで指す（テストの中だけの補助）。
    static func play(_ game: Game, _ steps: [(String, String)]) throws -> Game {
        var current = game
        for (from, to) in steps {
            let move = try #require(
                current.position.legalMoves().first { $0.from.name == from && $0.to.name == to && $0.promotion == nil })
            current = current.playing(move)
        }
        return current
    }

    @Test func checkmateEndsTheGame() throws {
        let game = try Self.play(.starting(from: .initial), [("f2", "f3"), ("e7", "e5"), ("g2", "g4"), ("d8", "h4")])
        #expect(game.status == .finished(.checkmate(winner: .black)))
        #expect(Termination.checkmate(winner: .black).result == .blackWins)
    }

    @Test func stalemateEndsTheGame() throws {
        let start = try PerftTests.decode("7k/8/6K1/8/8/8/8/5Q2 w - - 0 1")
        let game = try Self.play(.starting(from: start), [("f1", "f7")])
        #expect(game.status == .finished(.stalemate))
    }

    /// ナイトを 2 往復させると初期局面が 3 回目に現れる。
    @Test func threefoldRepetitionEndsTheGame() throws {
        let shuffle = [("g1", "f3"), ("g8", "f6"), ("f3", "g1"), ("f6", "g8")]
        let twice = try Self.play(.starting(from: .initial), shuffle)
        #expect(twice.status == .ongoing)
        let thrice = try Self.play(twice, shuffle)
        #expect(thrice.status == .finished(.threefoldRepetition))
        #expect(Termination.threefoldRepetition.result == .draw)
    }

    @Test func fiftyMoveRuleEndsTheGame() throws {
        let start = try PerftTests.decode("4k3/8/8/8/8/8/8/R3K3 w - - 99 80")
        let game = try Self.play(.starting(from: start), [("a1", "a2")])
        #expect(game.status == .finished(.fiftyMoveRule))
    }

    /// 升の色は (筋 + 段) の偶奇（c1 と f8 は同じ色・b1 と d1 も同じ色・b1 と c1、c8 と c1 は違う色）。
    @Test(arguments: [
        "4k3/8/8/8/8/8/8/4K3 w - - 0 1",
        "4k3/8/8/8/8/8/8/2B1K3 w - - 0 1",
        "4k3/8/8/8/8/8/8/1N2K3 w - - 0 1",
        "4kb2/8/8/8/8/8/8/2B1K3 w - - 0 1",
        "4k3/8/8/8/8/8/8/1B1BK3 w - - 0 1",
    ])
    func insufficientMaterialEndsTheGame(fen: String) throws {
        let game = Game.starting(from: try PerftTests.decode(fen))
        #expect(game.status == .finished(.insufficientMaterial))
    }

    @Test(arguments: [
        "4k3/8/8/8/8/8/8/1BB1K3 w - - 0 1",
        "2b1k3/8/8/8/8/8/8/2B1K3 w - - 0 1",
        "4k3/8/8/8/8/8/P7/4K3 w - - 0 1",
        "4k3/8/8/8/8/8/8/1NN1K3 w - - 0 1",
    ])
    func enoughMaterialKeepsTheGameGoing(fen: String) throws {
        let game = Game.starting(from: try PerftTests.decode(fen))
        #expect(game.status == .ongoing)
    }

    @Test func historyKeepsPositionsBeforeEachMove() throws {
        let game = try Self.play(.starting(from: .initial), [("e2", "e4"), ("e7", "e5")])
        #expect(game.moves.count == 2)
        #expect(game.positionsBeforeMoves.first == Position.initial)
        #expect(game.positionsBeforeMoves.last?.sideToMove == .black)
    }
}
