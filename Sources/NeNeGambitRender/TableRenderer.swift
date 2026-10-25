import NeNeGambitCore
import NeNeGambitEngine

/// 画面の状態と端末の大きさから、1 画面分のセルの格子を作る（ARC-011: 値を作るだけで端末を知らない）。
///
/// 配置はデザインのキャンバスの「B2」に従う（ADR 0007）: 上端に題とシード、左に盤、右に HUD、盤の下に COMMS の 2 行、下端にキーのヘルプ。
public enum TableRenderer {
    /// 縮小版がちょうど入る大きさ（これより小さければ 1 行の文言だけ）。
    public static let minimumSize = LayoutKind.compactSize
    /// 大きな盤がちょうど入る大きさ。
    public static let largeSize = LayoutKind.largeSize

    /// 1 画面分の格子。
    public static func render(_ state: ScreenState, size: ScreenSize) -> Grid {
        let theme = state.options.theme
        var grid = Grid.filled(size, with: Cell(character: " ", foreground: theme.text, background: theme.ground))
        switch LayoutKind.fitting(size) {
        case .large:
            ScreenLayout.large.draw(state, into: &grid)
        case .compact:
            ScreenLayout.compact.draw(state, into: &grid)
        case .tooSmall:
            let message = Wording.tooSmall(need: minimumSize)
            grid.write(message, column: 0, row: 0, colors: CellColors(foreground: theme.text, background: theme.ground))
        }
        return grid
    }
}
