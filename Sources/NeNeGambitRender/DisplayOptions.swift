/// 見た目の選択（駒の字形・テーマ・枠・色の方式）。持ち主は合成ルートで、Render は受け取って描くだけ。
public struct DisplayOptions: Sendable, Hashable {
    public let glyphs: GlyphSet
    public let theme: Theme
    public let frame: FrameStyle
    public let colors: ColorMode

    /// 組を作る。
    public init(glyphs: GlyphSet, theme: Theme, frame: FrameStyle, colors: ColorMode) {
        self.glyphs = glyphs
        self.theme = theme
        self.frame = frame
        self.colors = colors
    }
}
