/// 端末の文字セル 1 つ。1 つの `Character` が 1 桁を占めると前提する（ADR 0005）。
public struct Cell: Sendable, Hashable {
    public let character: Character
    public let foreground: Rgb
    public let background: Rgb
}
