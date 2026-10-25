/// 起動時に端末に問い合わせて分かった性質（合成ルートが測って渡す）。
public struct TerminalTraits: Sendable, Hashable {
    /// 枠の字形（罫線が 1 桁で描かれるときだけ罫線）。
    public let frame: FrameStyle
    /// 駒記号（U+265A〜）を端末が 2 桁で描くか。
    public let wideSymbols: Bool
    /// 24 ビットか 256 色か。
    public let colors: ColorMode

    /// 組を作る。
    public init(frame: FrameStyle, wideSymbols: Bool, colors: ColorMode) {
        self.frame = frame
        self.wideSymbols = wideSymbols
        self.colors = colors
    }
}
