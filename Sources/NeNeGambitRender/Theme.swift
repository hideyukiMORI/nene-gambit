/// カラーテーマ。色の値を持つのはここだけ（FR-12）。12 種類で、実行中の `t` で順に替える。
///
/// どのテーマも、文字と駒の色が地と升に対して 4.5:1 以上、白黒の駒どうしが明るさで 2.2:1 以上離れる（テストで確かめる）。
public struct Theme: Sendable, Hashable {
    /// 画面と起動オプションに使う名前（`--theme NEON`）。
    public let name: String
    let ground: Rgb
    let panel: Rgb
    let frame: Rgb
    let text: Rgb
    let dim: Rgb
    let accent: Rgb
    let accentAlt: Rgb
    let whitePiece: Rgb
    let blackPiece: Rgb
    let lightSquare: Rgb
    let darkSquare: Rgb

    /// 12 のテーマ（`t` で巡る順）。最初が既定。
    public static let catalog: [Theme] = [
        Theme(
            name: "NEON",
            hex: [
                0x05070D, 0x0A1020, 0x1E4D6B, 0xC8D3E0, 0x6B7F99, 0x00E5FF, 0xFF2E97, 0xEAFBFF, 0xFF4FA8, 0x1A2740,
                0x0F1828,
            ]),
        Theme(
            name: "PHOSPHOR",
            hex: [
                0x020803, 0x061208, 0x1C4D24, 0x9CF5A8, 0x4F9A5B, 0x39FF6A, 0xD8FF3E, 0xE4FFE8, 0x65BA74, 0x123A1A,
                0x08200E,
            ]),
        Theme(
            name: "AMBER",
            hex: [
                0x0A0602, 0x140C04, 0x5A3A12, 0xFFC879, 0xA87A3C, 0xFFB000, 0xFF6A1A, 0xFFF1D6, 0xEB8E37, 0x3A2410,
                0x20140A,
            ]),
        Theme(
            name: "SYNTHWAVE",
            hex: [
                0x0D0221, 0x160534, 0x4B1D7A, 0xE7D7FF, 0x9A84C4, 0xFF3CAC, 0x00F0FF, 0xFFF4FB, 0xD69B5A, 0x2E0F57,
                0x1A073A,
            ]),
        Theme(
            name: "GLACIER",
            hex: [
                0x03080F, 0x08121E, 0x2A4A6A, 0xDCEBFA, 0x7E98B3, 0x7FD4FF, 0xB6A0FF, 0xFFFFFF, 0x81B3E5, 0x16304A,
                0x0B1C2E,
            ]),
        Theme(
            name: "BLOODMOON",
            hex: [
                0x080203, 0x130507, 0x5A1620, 0xF2D0D4, 0xA06A72, 0xFF2B3F, 0xFFB347, 0xFFF0F1, 0xFF5A6A, 0x3A0E15,
                0x20070B,
            ]),
        Theme(
            name: "VAPOR",
            hex: [
                0x120B1F, 0x1C1230, 0x5A3F7F, 0xF3E8FF, 0xA897C4, 0x7DF9FF, 0xFF9DE2, 0xFFFFFF, 0xD1A0C3, 0x3A2A5C,
                0x261A40,
            ]),
        Theme(
            name: "MONO",
            hex: [
                0x050505, 0x101010, 0x3A3A3A, 0xD9D9D9, 0x8A8A8A, 0xFFFFFF, 0xBDBDBD, 0xFFFFFF, 0x9E9E9E, 0x2B2B2B,
                0x161616,
            ]),
        Theme(
            name: "TOXIC",
            hex: [
                0x06040A, 0x0F0A16, 0x3E2A5A, 0xE2F5C8, 0x8E9A78, 0xB6FF00, 0xC266FF, 0xF4FFE6, 0xCC95F5, 0x24183A,
                0x140D22,
            ]),
        Theme(
            name: "GILDED",
            hex: [
                0x070605, 0x11100C, 0x4A3F22, 0xEDE3C8, 0x9C9278, 0xE8C15A, 0x5AD1C8, 0xFFF8E6, 0xC3A24C, 0x2A2416,
                0x17140C,
            ]),
        Theme(
            name: "ABYSS",
            hex: [
                0x01060A, 0x041018, 0x123A4F, 0xCBE7F2, 0x6E93A3, 0x00C2A8, 0x3D8BFF, 0xE9FFFB, 0x42BCA9, 0x0B2A3A,
                0x061823,
            ]),
        Theme(
            name: "PAPER",
            hex: [
                0xF4F1EA, 0xE6E1D6, 0xB8AE9A, 0x2A2622, 0x5E564C, 0x0060C7, 0xC7253E, 0x1A1714, 0x9E1B30, 0xEDE4D0,
                0xD9CDB3,
            ]),
    ]

    /// 既定のテーマ。
    public static let standard = catalog[0]

    /// 名前のテーマ（大文字小文字を区別しない）。無ければ nil。
    public static func named(_ name: String) -> Theme? {
        catalog.first { $0.name == name.uppercased() }
    }

    /// `t` を押したときの次のテーマ（最後の次は最初）。
    public var next: Theme {
        let index = Self.catalog.firstIndex(of: self) ?? 0
        return Self.catalog[(index + 1) % Self.catalog.count]
    }

    /// 地・パネル・枠・文字・控えめな文字・強調 2 色・白の駒・黒の駒・明るい升・暗い升の順の 11 色から作る。
    private init(name: String, hex: [UInt32]) {
        precondition(hex.count == 11, "テーマの色は 11 個")
        let rgb = hex.map { Rgb(red: UInt8($0 >> 16 & 0xFF), green: UInt8($0 >> 8 & 0xFF), blue: UInt8($0 & 0xFF)) }
        self.name = name
        ground = rgb[0]
        panel = rgb[1]
        frame = rgb[2]
        text = rgb[3]
        dim = rgb[4]
        accent = rgb[5]
        accentAlt = rgb[6]
        whitePiece = rgb[7]
        blackPiece = rgb[8]
        lightSquare = rgb[9]
        darkSquare = rgb[10]
    }

    /// 詰まされた王の升（強調の 2 色目を暗い升に 3 割まぜる）。
    var matedSquare: Rgb {
        func mix(_ a: UInt8, _ b: UInt8) -> UInt8 {
            UInt8((Double(a) * 0.3 + Double(b) * 0.7).rounded())
        }
        return Rgb(
            red: mix(accentAlt.red, darkSquare.red), green: mix(accentAlt.green, darkSquare.green),
            blue: mix(accentAlt.blue, darkSquare.blue))
    }
}
