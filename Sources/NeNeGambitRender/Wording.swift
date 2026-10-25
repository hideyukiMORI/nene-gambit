import NeNeGambitCore
import NeNeGambitEngine

/// 画面に出す文言。文言のリテラルを持つのはここだけ。
///
/// ASCII の英語にしてある。1 文字 1 桁の前提（ADR 0005）を全角や幅の曖昧な文字で崩さないため。
enum Wording {
    static let title = "NeNe Gambit"
    static let movesHeading = "Moves"

    static func gameNumber(_ number: Int) -> String {
        "Game \(number)"
    }

    static func tally(_ tally: Tally) -> String {
        "White \(tally.whiteWins)  Black \(tally.blackWins)  Draws \(tally.draws)"
    }

    static func turn(_ position: Position) -> String {
        "\(side(position.sideToMove)) to move, move \(position.clocks.fullmove)"
    }

    static func players(_ players: Players) -> String {
        "White: \(name(players.white))  Black: \(name(players.black))"
    }

    static func tooSmall(need: ScreenSize) -> String {
        "Terminal too small (need \(need.columns)x\(need.rows))"
    }

    static func result(_ termination: Termination) -> String {
        switch termination {
        case .checkmate(winner: .white):
            return "1-0  White wins by checkmate"
        case .checkmate(winner: .black):
            return "0-1  Black wins by checkmate"
        case .stalemate:
            return "1/2  Draw by stalemate"
        case .threefoldRepetition:
            return "1/2  Draw by threefold repetition"
        case .fiftyMoveRule:
            return "1/2  Draw by the fifty-move rule"
        case .insufficientMaterial:
            return "1/2  Draw by insufficient material"
        }
    }

    private static func side(_ color: Color) -> String {
        switch color {
        case .white:
            return "White"
        case .black:
            return "Black"
        }
    }

    private static func name(_ kind: PlayerKind) -> String {
        switch kind {
        case .random:
            return "Random"
        }
    }
}
