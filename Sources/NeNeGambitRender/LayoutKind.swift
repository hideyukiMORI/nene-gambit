/// 端末の大きさで選ぶ配置（2 段・施主の決定 2026-10-25）。
enum LayoutKind: Sendable, Hashable {
    /// 100×30 以上: 1 升 3 行の大きな盤と、MATCH / SCORE / LOG / RESULT の HUD
    case large
    /// 縮小版が入る大きさ: 1 升 1 行の盤と、詰めた HUD
    case compact
    /// それより小さい: 1 行の文言だけ
    case tooSmall

    static let largeSize = ScreenSize(columns: 100, rows: 30)

    /// 縮小版が入る大きさ（英字 67×15・駒記号は盤が 8 桁広いので 75×15）。
    static func compactSize(_ glyphs: GlyphSet) -> ScreenSize {
        let layout = ScreenLayout.compact(glyphs)
        return ScreenSize(columns: layout.hudColumn + layout.hudWidth + 1, rows: layout.footerRow + 1)
    }

    static func fitting(_ size: ScreenSize, glyphs: GlyphSet) -> LayoutKind {
        if size.columns >= largeSize.columns, size.rows >= largeSize.rows {
            return .large
        }
        let compact = compactSize(glyphs)
        if size.columns >= compact.columns, size.rows >= compact.rows {
            return .compact
        }
        return .tooSmall
    }
}
