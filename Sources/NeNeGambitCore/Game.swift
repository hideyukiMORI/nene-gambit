/// 1 局の対局: いまの局面と、そこまでの指し手と局面の履歴。
///
/// 値型で、手を指すと新しい対局を返す。終局の判定（FR-04）はこの型の `status` だけが行う。
public struct Game: Sendable {
    /// いまの局面。
    public let position: Position
    /// 指した手（古い順）。
    public let moves: [Move]
    /// `moves[i]` を指す直前の局面（古い順）。
    public let positionsBeforeMoves: [Position]
    private let keys: [RepetitionKey]

    private init(position: Position, moves: [Move], positionsBeforeMoves: [Position], keys: [RepetitionKey]) {
        self.position = position
        self.moves = moves
        self.positionsBeforeMoves = positionsBeforeMoves
        self.keys = keys
    }

    /// 局面から始まる対局。
    public static func starting(from position: Position) -> Game {
        Game(position: position, moves: [], positionsBeforeMoves: [], keys: [RepetitionKey(position)])
    }

    /// 合法手を 1 つ指した対局。`move` は `position.legalMoves()` が返した手でなければならない。
    public func playing(_ move: Move) -> Game {
        let next = position.applying(move)
        return Game(
            position: next,
            moves: moves + [move],
            positionsBeforeMoves: positionsBeforeMoves + [position],
            keys: keys + [RepetitionKey(next)]
        )
    }

    /// 対局の状態。合法手が無ければメイトかステイルメイトが先に決まり、次に 50 手・3 回・駒不足の順に見る。
    public var status: GameStatus {
        switch position.status {
        case .checkmate(let winner):
            return .finished(.checkmate(winner: winner))
        case .stalemate:
            return .finished(.stalemate)
        case .ongoing:
            return drawStatus
        }
    }

    private var drawStatus: GameStatus {
        if position.clocks.halfmove >= 100 {
            return .finished(.fiftyMoveRule)
        }
        if let current = keys.last, keys.filter({ $0 == current }).count >= 3 {
            return .finished(.threefoldRepetition)
        }
        if MaterialBalance(position.board).isInsufficient {
            return .finished(.insufficientMaterial)
        }
        return .ongoing
    }
}
