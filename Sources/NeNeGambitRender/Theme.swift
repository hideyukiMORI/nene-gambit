/// 配色表。色の値を持つのはここだけ（FR-12: 1 テーマから始める）。
///
/// 木目調。明るい升と暗い升の明るさを近づけ、白の駒（象牙色）と黒の駒（焦げ茶）がどちらの升の上でも読めるようにした。
/// 実機（Windows Terminal）での見え方は Phase 3 の手順 3 で施主が確かめる。
struct Theme: Sendable {
    let lightSquare: Rgb
    let darkSquare: Rgb
    let whitePiece: Rgb
    let blackPiece: Rgb
    let background: Rgb
    let text: Rgb
    let dimText: Rgb
    let accent: Rgb

    /// 唯一のテーマ。
    static let wood = Theme(
        lightSquare: Rgb(red: 181, green: 136, blue: 99),
        darkSquare: Rgb(red: 120, green: 80, blue: 50),
        whitePiece: Rgb(red: 255, green: 250, blue: 240),
        blackPiece: Rgb(red: 25, green: 18, blue: 12),
        background: Rgb(red: 28, green: 24, blue: 20),
        text: Rgb(red: 230, green: 220, blue: 200),
        dimText: Rgb(red: 150, green: 140, blue: 125),
        accent: Rgb(red: 240, green: 190, blue: 90)
    )
}
