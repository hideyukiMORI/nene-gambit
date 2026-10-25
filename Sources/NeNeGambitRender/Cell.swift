/// 端末の文字セル 1 つ。1 つの `Character` が 1 桁を占めると前提する（ADR 0005）。
///
/// 例外は駒記号で、描くと約 2 桁の幅を使うので、右隣のセルを `isWideTail`（何も書かない）にする（ADR 0010）。
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
