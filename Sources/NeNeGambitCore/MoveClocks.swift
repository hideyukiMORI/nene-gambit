/// 手数の時計（FEN の第 5・第 6 欄）。
public struct MoveClocks: Sendable, Hashable {
    /// 最後にポーンが動くか駒が取られてからの半手の数（50 手ルール用）。
    public let halfmove: Int
    /// 手数。1 から始まり、黒が指すたびに 1 増える。
    public let fullmove: Int
}
