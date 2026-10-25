/// 盤上の駒（色と種類）。
public struct Piece: Sendable, Hashable {
    public let color: Color
    public let kind: PieceKind

    /// 駒を作る。どの組み合わせも正しい駒なので検証は要らない。
    public init(_ color: Color, _ kind: PieceKind) {
        self.color = color
        self.kind = kind
    }
}
