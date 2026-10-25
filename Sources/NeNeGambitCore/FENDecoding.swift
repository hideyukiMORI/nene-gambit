/// FEN を読んだ結果。
public enum FENDecoding: Sendable, Hashable {
    case decoded(Position)
    case rejected(FENRejection)
}
