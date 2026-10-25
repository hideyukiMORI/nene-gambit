import NeNeGambitCore

/// 評価関数（FR-03）。駒の価値と位置の項を持つのはここだけ（1 か所のデータ）。値は手番の側から見たセンチポーン。
///
/// 位置の項は表ではなく、中央からの距離・前進・王との距離で決める（性格ごとの重みは `StyleWeights`）。
/// 駒得した側には mop-up の項（相手の王を盤の端へ追い込み、自分の王を寄せる）を足し、王とクイーン・ルーク対王を詰ませに行かせる。
enum Evaluator {
    /// 駒の価値。
    static func value(_ kind: PieceKind) -> Int {
        switch kind {
        case .pawn:
            return 100
        case .knight:
            return 320
        case .bishop:
            return 330
        case .rook:
            return 500
        case .queen:
            return 900
        case .king:
            return 0
        }
    }

    /// 手番の側から見た評価値。
    static func score(_ position: Position, weights: StyleWeights) -> Int {
        let survey = BoardSurvey(position.board)
        var white = 0
        for placed in survey.pieces {
            let term = value(placed.piece.kind) + positional(placed, survey: survey, weights: weights)
            white += placed.piece.color == .white ? term : -term
        }
        white += mopUp(survey)
        return position.sideToMove == .white ? white : -white
    }

    private static func positional(_ placed: PlacedPiece, survey: BoardSurvey, weights: StyleWeights) -> Int {
        let square = placed.square
        let color = placed.piece.color
        let advance = color == .white ? square.rank : 7 - square.rank
        let centrality = 3 - BoardSurvey.centerDistance(square)
        let enemyKing = color == .white ? survey.blackKing : survey.whiteKing
        let reach = enemyKing.map { 7 - BoardSurvey.chebyshev(square, $0) } ?? 0
        switch placed.piece.kind {
        case .pawn:
            return (advance - 1) * weights.pawnAdvance * (survey.isEndgame ? 3 : 1) + reach * weights.aggression / 2
        case .knight, .bishop:
            return centrality * weights.center + reach * weights.aggression
        case .rook:
            return (advance == 6 ? 20 : 0) + reach * weights.aggression
        case .queen:
            return centrality * weights.center / 2 + reach * weights.aggression
        case .king:
            return kingTerm(square, advance: advance, survey: survey, weights: weights)
        }
    }

    private static func kingTerm(_ square: Square, advance: Int, survey: BoardSurvey, weights: StyleWeights) -> Int {
        if survey.isEndgame {
            return (3 - BoardSurvey.centerDistance(square)) * 10
        }
        let tucked = advance == 0 && [0, 1, 2, 6, 7].contains(square.file)
        return tucked ? weights.kingShelter : -weights.kingShelter
    }

    /// 駒得した側（ポーンの無い相手）に、相手の王を端へ追い込み自分の王を寄せる項を足す（白から見た値）。
    private static func mopUp(_ survey: BoardSurvey) -> Int {
        guard let whiteKing = survey.whiteKing, let blackKing = survey.blackKing else {
            return 0
        }
        let lead = survey.material(.white) - survey.material(.black)
        guard abs(lead) >= 300 else {
            return 0
        }
        let loser: Color = lead > 0 ? .black : .white
        guard survey.pawns(loser) == 0 else {
            return 0
        }
        let loserKing = loser == .black ? blackKing : whiteKing
        let edge = BoardSurvey.manhattanFromCenter(loserKing)
        let closeness = 14 - BoardSurvey.manhattan(whiteKing, blackKing)
        let bonus = 10 * edge + 4 * closeness
        return lead > 0 ? bonus : -bonus
    }
}
