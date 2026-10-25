/// 白と黒それぞれの指し手の種類。
public struct Players: Sendable, Hashable {
    public let white: PlayerKind
    public let black: PlayerKind

    /// 組を作る。
    public init(white: PlayerKind, black: PlayerKind) {
        self.white = white
        self.black = black
    }
}
