import NeNeGambitCore

/// 対局の列: いまの局・何局目か・通算の勝敗・白黒の指し手の種類（ARC-004）。
///
/// 値型で、1 歩進めると新しい値を返す。時計を知らない（「何秒に 1 歩進めるか」は合成ルートが決める）。
/// 乱数は引数から受け取るので、同じシードの乱数源からは同じ対局の列が出る（FR-05 の決定性）。
public struct GameSeries: Sendable {
    public let game: Game
    /// 何局目か（1 から）。
    public let gameNumber: Int
    /// 終わった局の通算。いまの局が終わった時点で数える。
    public let tally: Tally
    public let players: Players

    /// 初期局面の第 1 局から始まる列。
    public static func starting(_ players: Players) -> GameSeries {
        GameSeries(game: .starting(from: .initial), gameNumber: 1, tally: .zero, players: players)
    }

    /// 1 歩進める。いまの局が続いていれば手番の側が 1 手指し、終わっていれば次の局を初期局面から始める。
    public func advanced(using generator: inout some RandomNumberGenerator) -> GameSeries {
        guard case .ongoing = game.status else {
            return GameSeries(
                game: .starting(from: .initial), gameNumber: gameNumber + 1, tally: tally, players: players)
        }
        let mover = game.position.sideToMove == .white ? players.white : players.black
        guard let move = mover.choose(in: game.position, using: &generator) else {
            preconditionFailure("続いている局で合法手が無い")
        }
        let next = game.playing(move)
        let counted: Tally
        switch next.status {
        case .ongoing:
            counted = tally
        case .finished(let termination):
            counted = tally.recording(termination.result)
        }
        return GameSeries(game: next, gameNumber: gameNumber, tally: counted, players: players)
    }
}
