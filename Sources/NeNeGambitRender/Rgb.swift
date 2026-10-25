/// 24 ビットの色。色の値を決めるのは `Theme` だけ（Render の配色表）。
public struct Rgb: Sendable, Hashable {
    public let red: UInt8
    public let green: UInt8
    public let blue: UInt8
}
