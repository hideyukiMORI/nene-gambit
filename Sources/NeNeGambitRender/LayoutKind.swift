/// 端末の大きさで選ぶ配置（2 段・施主の決定 2026-10-25）。
enum LayoutKind: Sendable, Hashable {
    /// 100×30 以上: 1 升 7 桁×3 行の盤と、MATCH / SCORE / LOG / RESULT の HUD
    case large
    /// 67×15 以上: 1 升 3 桁×1 行の盤と、詰めた HUD
    case compact
    /// それより小さい: 1 行の文言だけ
    case tooSmall

    static let largeSize = ScreenSize(columns: 100, rows: 30)
    static let compactSize = ScreenSize(columns: 67, rows: 15)

    static func fitting(_ size: ScreenSize) -> LayoutKind {
        if size.columns >= largeSize.columns, size.rows >= largeSize.rows {
            return .large
        }
        if size.columns >= compactSize.columns, size.rows >= compactSize.rows {
            return .compact
        }
        return .tooSmall
    }
}
