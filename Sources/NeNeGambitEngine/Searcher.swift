import NeNeGambitCore

/// アルファベータ探索（FR-03）。深さを 1 から `depth` まで増やし、ノード数の上限を超えたら 1 つ浅い深さの結果を使う。
/// 時計を読まない（ARC-007）。乱数は引数で受け取るので、同じシードからは同じ手が出る。
struct Searcher {
    static let mate = 100_000
    private static let quiescenceLimit = 4

    private let weights: StyleWeights
    private let nodeLimit: Int
    private var nodes = 0
    private var exhausted = false

    private init(weights: StyleWeights, nodeLimit: Int) {
        self.weights = weights
        self.nodeLimit = nodeLimit
    }

    /// その局で指す手。合法手が無ければ nil。返す手は必ず `game.position.legalMoves()` の中にある。
    static func choose(in game: Game, profile: SearchProfile, using generator: inout some RandomNumberGenerator)
        -> Move?
    {
        let moves = ordered(game.position.legalMoves(), in: game.position)
        guard let first = moves.first else {
            return nil
        }
        var searcher = Searcher(weights: profile.weights, nodeLimit: profile.nodeLimit)
        var scored = moves.map { ScoredMove(move: $0, score: 0) }
        for depth in 1...max(profile.depth, 1) {
            let round = searcher.scoreRoot(moves, in: game.position, depth: depth)
            if searcher.exhausted {
                break
            }
            scored = round
        }
        let adjusted = scored.map { avoidingRepetition($0, in: game) }
        let margin = game.moves.count < profile.openingPlies ? profile.openingMargin : profile.tieMargin
        let best = adjusted.map(\.score).max() ?? 0
        let candidates = adjusted.filter { $0.score >= best - margin }
        return candidates.randomElement(using: &generator)?.move ?? first
    }

    /// 勝っている側は、もう現れた局面へ戻る手を引き分け（0）より少し悪いとみなす（同一局面 3 回で勝ちを逃さない）。
    private static func avoidingRepetition(_ scored: ScoredMove, in game: Game) -> ScoredMove {
        guard scored.score > 0, game.occurrences(after: scored.move) > 0 else {
            return scored
        }
        return ScoredMove(move: scored.move, score: -10)
    }

    private mutating func scoreRoot(_ moves: [Move], in position: Position, depth: Int) -> [ScoredMove] {
        var round: [ScoredMove] = []
        let full = Window(alpha: -Self.mate - 1, beta: Self.mate + 1)
        for move in moves {
            let score = -negamax(position.applying(move), depth: depth - 1, window: full, ply: 1)
            if exhausted {
                return round
            }
            round.append(ScoredMove(move: move, score: score))
        }
        return round
    }

    private mutating func negamax(_ position: Position, depth: Int, window: Window, ply: Int) -> Int {
        nodes += 1
        if nodes > nodeLimit {
            exhausted = true
            return 0
        }
        if depth <= 0 {
            return quiesce(position, window: window, ply: ply, step: 0)
        }
        let moves = position.legalMoves()
        if moves.isEmpty {
            return position.isInCheck ? -(Self.mate - ply) : 0
        }
        if position.clocks.halfmove >= 100 {
            return 0
        }
        var current = window
        for move in Self.ordered(moves, in: position) {
            let score = -negamax(position.applying(move), depth: depth - 1, window: current.flipped, ply: ply + 1)
            if exhausted {
                return 0
            }
            if score >= current.beta {
                return current.beta
            }
            current = current.raising(to: score)
        }
        return current.alpha
    }

    /// 静止探索: 駒を取る手だけを読み、取り合いの途中で評価しない。
    private mutating func quiesce(_ position: Position, window: Window, ply: Int, step: Int) -> Int {
        nodes += 1
        if nodes > nodeLimit {
            exhausted = true
            return 0
        }
        if position.isInCheck {
            // 王手を受けているときは受けの手を全部読む（立ち止まって評価すると王手を無視することになる）
            return evasions(position, window: window, ply: ply, step: step)
        }
        let standPat = Evaluator.score(position, weights: weights)
        if standPat >= window.beta {
            return window.beta
        }
        var current = window.raising(to: standPat)
        guard step < Self.quiescenceLimit else {
            return current.alpha
        }
        for move in Self.ordered(position.legalCaptures(), in: position) {
            let score = -quiesce(position.applying(move), window: current.flipped, ply: ply + 1, step: step + 1)
            if exhausted {
                return 0
            }
            if score >= current.beta {
                return current.beta
            }
            current = current.raising(to: score)
        }
        return current.alpha
    }

    /// 王手を受けている局面の静止探索: 合法手が無ければ詰み、あれば全部の受けを読む。
    private mutating func evasions(_ position: Position, window: Window, ply: Int, step: Int) -> Int {
        let moves = position.legalMoves()
        if moves.isEmpty {
            return -(Self.mate - ply)
        }
        var current = window
        for move in Self.ordered(moves, in: position) {
            let score = -quiesce(position.applying(move), window: current.flipped, ply: ply + 1, step: step + 1)
            if exhausted {
                return 0
            }
            if score >= current.beta {
                return current.beta
            }
            current = current.raising(to: score)
        }
        return current.alpha
    }

    /// 取る手を先に（価値の高い駒を、価値の低い駒で取る順）、昇格を次に並べる。
    static func ordered(_ moves: [Move], in position: Position) -> [Move] {
        func key(_ move: Move) -> Int {
            let victim = captured(by: move, in: position).map { Evaluator.value($0) * 10 } ?? 0
            let attacker = position.board[move.from].map { Evaluator.value($0.kind) / 100 } ?? 0
            let promotion = move.promotion.map { Evaluator.value($0.pieceKind) } ?? 0
            return victim > 0 ? victim - attacker + promotion : promotion
        }
        return moves.enumerated().sorted { lhs, rhs in
            let (left, right) = (key(lhs.element), key(rhs.element))
            return left != right ? left > right : lhs.offset < rhs.offset
        }.map(\.element)
    }

    /// その手で取られる駒の種類（アンパッサンを含む）。取らなければ nil。
    static func captured(by move: Move, in position: Position) -> PieceKind? {
        if let target = position.board[move.to] {
            return target.kind
        }
        let isPawn = position.board[move.from]?.kind == .pawn
        return isPawn && move.from.file != move.to.file ? .pawn : nil
    }
}
