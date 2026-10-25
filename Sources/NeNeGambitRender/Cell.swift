/// 端末の文字セル 1 つ。1 つの `Character` が 1 桁を占めると前提する（ADR 0005）。
///
/// 例外は端末が 2 桁で描くと測れた駒記号で、その右隣のセルは `isWideTail`（何も書かない）になる（ADR 0008）。
public struct Cell: Sendable, Hashable {
    public let character: Character
    public let foreground: Rgb
    public let background: Rgb
    /// 左隣の 2 桁の文字の右半分。差分描画はここに何も書かない。
    public let isWideTail: Bool

    init(character: Character, foreground: Rgb, background: Rgb, isWideTail: Bool = false) {
        self.character = character
        self.foreground = foreground
        self.background = background
        self.isWideTail = isWideTail
    }
}
