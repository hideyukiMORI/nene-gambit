import NeNeGambitCore
import Testing

/// FEN の読み書き（2-2 の不変条件: 読んで書くと同じ文字列に戻る）。
struct FENCodecTests {
    static let roundTrips = [
        "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
        "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1",
        "r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1",
        "8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 1",
        "r3k2r/Pppp1ppp/1b3nbN/nP6/BBP1P3/q4N2/Pp1P2PP/R2Q1RK1 w kq - 0 1",
        "rnbq1k1r/pp1Pbppp/2p5/8/2B5/8/PPP1NnPP/RNBQK2R w KQ - 1 8",
        "r4rk1/1pp1qppp/p1np1n2/2b1p1B1/2B1P1b1/P1NP1N2/1PP1QPPP/R4RK1 w - - 0 10",
    ]

    @Test(arguments: roundTrips)
    func encodesBackToTheSameText(_ fen: String) throws {
        let position = try PerftTests.decode(fen)
        #expect(FENCodec.encode(position) == fen)
    }

    struct Rejection: Sendable, CustomTestStringConvertible {
        let fen: String
        let reason: FENRejection

        var testDescription: String {
            fen
        }
    }

    static let rejections: [Rejection] = [
        Rejection(fen: "r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq -", reason: .fieldCount),
        Rejection(fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP w KQkq - 0 1", reason: .placement),
        Rejection(fen: "rnbqkbnr/pppppppp/9/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1", reason: .placement),
        Rejection(fen: "rnbqkbnr/ppppxppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1", reason: .placement),
        Rejection(fen: "rnbqqbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1", reason: .kings),
        Rejection(fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR x KQkq - 0 1", reason: .sideToMove),
        Rejection(fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w kqKQ - 0 1", reason: .castling),
        Rejection(fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KK - 0 1", reason: .castling),
        Rejection(fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq e4 0 1", reason: .enPassant),
        Rejection(fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - -1 1", reason: .halfmoveClock),
        Rejection(fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 0", reason: .fullmoveNumber),
    ]

    @Test(arguments: rejections)
    func rejectsWithTheReason(_ entry: Rejection) {
        #expect(FENCodec.decode(entry.fen) == .rejected(entry.reason))
    }
}
