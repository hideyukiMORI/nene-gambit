/// 発言のきっかけになる出来事（話す本人から見た向き）。
public enum Cue: Sendable, Hashable, CaseIterable {
    case start
    case capture
    case lostPiece
    case queenTaken
    case queenLost
    case check
    case checked
    case promotion
    case enPassant
    case castle
    case idle
    case win
    case lose
    case draw

    /// その出来事を言うときの気分。
    public var mood: Mood {
        switch self {
        case .capture, .queenTaken, .check, .promotion, .enPassant, .castle, .win:
            return .smug
        case .start, .idle, .draw:
            return .neutral
        case .lostPiece, .queenLost, .checked, .lose:
            return .grim
        }
    }
}
