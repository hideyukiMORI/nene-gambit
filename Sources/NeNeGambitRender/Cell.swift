/// 端末の文字セル 1 つ。1 つの `Character` が 1 桁を占めると前提する（ADR 0005）。
///
/// 例外は駒記号で、端末は 1 桁進めながら約 2 桁の幅で描く。右隣のセルは升の色の空白にしておき、字形はその上に描かれる（ADR 0011）。
public struct Cell: Sendable, Hashable {
    public let character: Character
    public let foreground: Rgb
    public let background: Rgb
}
