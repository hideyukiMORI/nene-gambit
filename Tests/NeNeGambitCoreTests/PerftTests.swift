import NeNeGambitCore
import Testing

/// perft（深さ N までの合法手の列の数）を公表値と突き合わせる（FR-02）。
///
/// 期待値の出典: Chess Programming Wiki「Perft Results」 https://www.chessprogramming.org/Perft_Results
/// （2026-10-25 に取得した HTML の表から写した。記憶では書いていない）。
/// - Position 2（Kiwipete）は出典の FEN に手数の欄が無いので、` 0 1` を足して 6 欄にした（FENCodec は欄を補わない）
/// - Position 3 の深さ 5 は、出典の表で脚注番号が数字の前に付いて「9 674624」と見えるが、値は 674624
/// どの局面をどの深さまで回すかは ADR 0004。
struct PerftTests {
    struct Case: Sendable, CustomTestStringConvertible {
        let name: String
        let fen: String
        let counts: [Int]

        var testDescription: String {
            name
        }
    }

    static let cases: [Case] = [
        Case(
            name: "初期局面",
            fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
            counts: [20, 400, 8_902, 197_281, 4_865_609]
        ),
        Case(
            name: "Position 2（Kiwipete）",
            fen: "r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1",
            counts: [48, 2_039, 97_862, 4_085_603, 193_690_690]
        ),
        Case(
            name: "Position 3",
            fen: "8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 1",
            counts: [14, 191, 2_812, 43_238, 674_624]
        ),
        Case(
            name: "Position 4",
            fen: "r3k2r/Pppp1ppp/1b3nbN/nP6/BBP1P3/q4N2/Pp1P2PP/R2Q1RK1 w kq - 0 1",
            counts: [6, 264, 9_467, 422_333, 15_833_292]
        ),
        Case(
            name: "Position 5",
            fen: "rnbq1k1r/pp1Pbppp/2p5/8/2B5/8/PPP1NnPP/RNBQK2R w KQ - 1 8",
            counts: [44, 1_486, 62_379, 2_103_487, 89_941_194]
        ),
        Case(
            name: "Position 6",
            fen: "r4rk1/1pp1qppp/p1np1n2/2b1p1B1/2B1P1b1/P1NP1N2/1PP1QPPP/R4RK1 w - - 0 10",
            counts: [46, 2_079, 89_890, 3_894_594, 164_075_551]
        ),
    ]

    @Test(arguments: cases)
    func matchesPublishedCounts(_ entry: Case) throws {
        let position = try Self.decode(entry.fen)
        let measured = (1...entry.counts.count).map { Self.perft(position, depth: $0) }
        #expect(measured == entry.counts)
    }

    @Test func initialPositionMatchesItsFEN() throws {
        let position = try Self.decode("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
        #expect(position == Position.initial)
    }

    static func decode(_ fen: String) throws -> Position {
        switch FENCodec.decode(fen) {
        case .decoded(let position):
            return position
        case .rejected(let reason):
            Issue.record("FEN を読めない: \(reason)")
            return try #require(nil as Position?)
        }
    }

    /// 深さ 1 は合法手の数をそのまま数える（葉で局面を作らない）。
    static func perft(_ position: Position, depth: Int) -> Int {
        let moves = position.legalMoves()
        if depth == 1 {
            return moves.count
        }
        return moves.reduce(0) { total, move in total + perft(position.applying(move), depth: depth - 1) }
    }
}
