/// 終局の理由（FR-04）。
public enum Termination: Sendable, Hashable {
    /// 手番の側に合法手が無く、王手されている。
    case checkmate(winner: Color)
    /// 手番の側に合法手が無く、王手されていない。
    case stalemate
    /// 同じ局面が 3 回現れた。
    case threefoldRepetition
    /// 50 手（100 半手）のあいだ、ポーンが動かず駒も取られなかった。
    case fiftyMoveRule
    /// どちらもチェックメイトに必要な駒を持っていない。
    case insufficientMaterial

    /// 結果。
    public var result: GameResult {
        switch self {
        case .checkmate(winner: .white):
            return .whiteWins
        case .checkmate(winner: .black):
            return .blackWins
        case .stalemate, .threefoldRepetition, .fiftyMoveRule, .insufficientMaterial:
            return .draw
        }
    }
}
