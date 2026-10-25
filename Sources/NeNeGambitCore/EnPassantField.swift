/// FEN のアンパッサンの欄を読めた結果。`square` が nil なのは欄が `-`（升が無い）のときだけ。
///
/// 「読めなかった」と「升が無い」を同じ nil で表さないための型（SWF-004）。
struct EnPassantField: Sendable, Hashable {
    let square: Square?
}
