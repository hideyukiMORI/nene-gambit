/// 色の付いた文字列のひと切れ（1 文字 1 桁）。
struct Segment: Sendable, Hashable {
    let text: String
    let color: Rgb

    init(_ text: String, _ color: Rgb) {
        self.text = text
        self.color = color
    }
}
