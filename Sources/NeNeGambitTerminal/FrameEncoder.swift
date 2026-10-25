import NeNeGambitRender

/// 格子を ANSI のバイト列にする。前の格子と違うセルだけを書く（1 フレーム 1 回の `write` 用）。
public enum FrameEncoder {
    /// `previous` が無いか大きさが違えば、画面を消して全部を書く。
    public static func encode(_ grid: Grid, previous: Grid?, colors: ColorMode) -> [UInt8] {
        var out: [UInt8] = []
        let full = previous?.size != grid.size
        if full {
            out += Array("\u{1B}[0m\u{1B}[2J".utf8)
        }
        var cursor: Int?  // 次に書く位置（row * columns + column）。不明なら nil
        var styled: Cell?  // いま端末に効いている色を持つセル
        for row in 0..<grid.size.rows {
            for column in 0..<grid.size.columns {
                let cell = grid[column, row]
                if !full, let previous, previous[column, row] == cell {
                    continue
                }
                let position = row * grid.size.columns + column
                if cursor != position {
                    out += Array("\u{1B}[\(row + 1);\(column + 1)H".utf8)
                }
                if styled?.foreground != cell.foreground || styled?.background != cell.background {
                    out += sgr(cell.foreground, cell.background, colors)
                    styled = cell
                }
                out += Array(String(cell.character).utf8)
                cursor = column + 1 < grid.size.columns ? position + 1 : nil
            }
        }
        if !out.isEmpty {
            out += Array("\u{1B}[0m".utf8)
        }
        return out
    }

    private static func sgr(_ foreground: Rgb, _ background: Rgb, _ colors: ColorMode) -> [UInt8] {
        switch colors {
        case .trueColor:
            let fg = "38;2;\(foreground.red);\(foreground.green);\(foreground.blue)"
            let bg = "48;2;\(background.red);\(background.green);\(background.blue)"
            return Array("\u{1B}[\(fg);\(bg)m".utf8)
        case .palette256:
            return Array("\u{1B}[38;5;\(paletteIndex(foreground));48;5;\(paletteIndex(background))m".utf8)
        }
    }

    /// 256 色の 6×6×6 の色立方体のいちばん近い番号（16〜231）。
    static func paletteIndex(_ color: Rgb) -> Int {
        let level = { (value: UInt8) in (Int(value) * 5 + 127) / 255 }
        return 16 + 36 * level(color.red) + 6 * level(color.green) + level(color.blue)
    }
}
