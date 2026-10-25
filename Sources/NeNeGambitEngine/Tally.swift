import NeNeGambitCore

/// 通算の勝敗（FR-10）。
public struct Tally: Sendable, Hashable {
    public let whiteWins: Int
    public let blackWins: Int
    public let draws: Int

    /// 1 局も終わっていない。
    public static let zero = Tally(whiteWins: 0, blackWins: 0, draws: 0)

    /// 終わった局の数。
    public var finishedGames: Int {
        whiteWins + blackWins + draws
    }

    /// 1 局の結果を足した通算。
    func recording(_ result: GameResult) -> Tally {
        switch result {
        case .whiteWins:
            return Tally(whiteWins: whiteWins + 1, blackWins: blackWins, draws: draws)
        case .blackWins:
            return Tally(whiteWins: whiteWins, blackWins: blackWins + 1, draws: draws)
        case .draw:
            return Tally(whiteWins: whiteWins, blackWins: blackWins, draws: draws + 1)
        }
    }
}
