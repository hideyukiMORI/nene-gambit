/// キー入力から読み取った利用者の意図（閉じた集合）。
public enum KeyIntent: Sendable, Hashable {
    /// `q`: 終了する（FR-08）。
    case quit
    /// `g`: 駒の字形を英字と駒記号で切り替える（FR-07）。
    case toggleGlyphs
    /// `t`: カラーテーマを次へ（FR-13）。
    case cycleTheme

    /// 読み取ったバイト列の中の意図（順番どおり）。知らないキーとエスケープ列は捨てる。
    public static func decode(_ bytes: [UInt8]) -> [KeyIntent] {
        var intents: [KeyIntent] = []
        var index = 0
        while index < bytes.count {
            let byte = bytes[index]
            if byte == 0x1B {
                index = skipEscapeSequence(bytes, from: index)
                continue
            }
            if byte == UInt8(ascii: "q") || byte == UInt8(ascii: "Q") {
                intents.append(.quit)
            } else if byte == UInt8(ascii: "g") || byte == UInt8(ascii: "G") {
                intents.append(.toggleGlyphs)
            } else if byte == UInt8(ascii: "t") || byte == UInt8(ascii: "T") {
                intents.append(.cycleTheme)
            }
            index += 1
        }
        return intents
    }

    /// `ESC [ … 終端` を読み飛ばした次の位置（矢印キー等）。`ESC` 単独なら 1 つ進める。
    private static func skipEscapeSequence(_ bytes: [UInt8], from start: Int) -> Int {
        var index = start + 1
        guard index < bytes.count, bytes[index] == UInt8(ascii: "[") || bytes[index] == UInt8(ascii: "O") else {
            return index
        }
        index += 1
        while index < bytes.count, !(0x40...0x7E).contains(bytes[index]) {
            index += 1
        }
        return index + 1
    }
}
