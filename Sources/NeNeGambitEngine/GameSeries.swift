import NeNeGambitCore

/// 対局の列: いまの局・何局目か・通算の勝敗・その局の性格の組・発言（ARC-004）。
///
/// 値型で、1 歩進めると新しい値を返す。時計を知らない（「何秒に 1 歩進めるか」は合成ルートが決める）。
/// 乱数は引数から受け取るので、同じシードの乱数源からは同じ対局と同じ会話の列が出る（FR-05 の決定性）。
public struct GameSeries: Sendable {
    public let game: Game
    /// 何局目か（1 から）。
    public let gameNumber: Int
    /// 終わった局の通算。いまの局が終わった時点で数える。
    public let tally: Tally
    /// その局の白と黒の性格。
    public let players: Players
    /// 対局中の発言。
    public let banter: Banter

    /// 初期局面の第 1 局から始まる列。性格の組と最初のひと言を乱数で決める。
    public static func starting(using generator: inout some RandomNumberGenerator) -> GameSeries {
        newGame(number: 1, tally: .zero, previous: .silent, using: &generator)
    }

    /// 1 歩進める。いまの局が続いていれば手番の側が 1 手指し、終わっていれば次の局を初期局面から始める。
    public func advanced(using generator: inout some RandomNumberGenerator) -> GameSeries {
        guard case .ongoing = game.status else {
            return Self.newGame(number: gameNumber + 1, tally: tally, previous: banter, using: &generator)
        }
        let mover = game.position.sideToMove == .white ? players.white : players.black
        guard let move = mover.choose(in: game, using: &generator) else {
            preconditionFailure("続いている局で合法手が無い")
        }
        let next = game.playing(move)
        let status = next.status
        let counted: Tally
        switch status {
        case .ongoing:
            counted = tally
        case .finished(let termination):
            counted = tally.recording(termination.result)
        }
        let facts = MoveFacts(before: game.position, move: move, after: next.position)
        let said = banter.reacting(to: facts, status: status, players: players, using: &generator)
        return GameSeries(game: next, gameNumber: gameNumber, tally: counted, players: players, banter: said)
    }

    private static func newGame(
        number: Int, tally: Tally, previous: Banter, using generator: inout some RandomNumberGenerator
    ) -> GameSeries {
        let players = Players.drawn(using: &generator)
        let banter = previous.starting(players, using: &generator)
        return GameSeries(
            game: .starting(from: .initial), gameNumber: number, tally: tally, players: players, banter: banter)
    }
}
