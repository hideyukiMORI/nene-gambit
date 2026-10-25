/// 見た目の選択（駒の字形・テーマ）と端末の性質。持ち主は合成ルートで、Render は受け取って描くだけ。
public struct DisplayOptions: Sendable, Hashable {
    public let glyphs: GlyphSet
    public let theme: Theme
    public let traits: TerminalTraits

    /// 組を作る。
    public init(glyphs: GlyphSet, theme: Theme, traits: TerminalTraits) {
        self.glyphs = glyphs
        self.theme = theme
        self.traits = traits
    }
}
