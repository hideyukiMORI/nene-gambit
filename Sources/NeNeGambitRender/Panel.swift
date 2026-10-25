/// 決まった幅の枠つきパネルの行を作る（`┌─[ TITLE ]──┐` / `│ 中身 │` / `└──┘`）。
struct Panel: Sendable {
    let width: Int
    let glyphs: FrameGlyphs

    /// 題つきの上端（`first` なら角、そうでなければ T 字）。
    func header(_ title: String, title titleColor: Rgb, frame: Rgb, first: Bool) -> [Segment] {
        let left = (first ? glyphs.topLeft : glyphs.teeLeft) + glyphs.horizontal + "[ "
        let right = first ? glyphs.topRight : glyphs.teeRight
        let fill = String(repeating: glyphs.horizontal, count: max(width - 6 - title.count - 1, 0))
        return [Segment(left, frame), Segment(title, titleColor), Segment(" ]" + fill + right, frame)]
    }

    /// 中身の行。中身は幅に合わせて右を空白で埋め、はみ出す分は切る。
    func row(_ content: [Segment], frame: Rgb) -> [Segment] {
        let inner = width - 4
        var used = 0
        var clipped: [Segment] = []
        for segment in content where used < inner {
            let piece = String(segment.text.prefix(inner - used))
            clipped.append(Segment(piece, segment.color))
            used += piece.count
        }
        let padding = String(repeating: " ", count: inner - used)
        return [Segment(glyphs.vertical + " ", frame)] + clipped + [Segment(padding + " " + glyphs.vertical, frame)]
    }

    /// 下端。
    func footer(frame: Rgb) -> [Segment] {
        [
            Segment(
                glyphs.bottomLeft + String(repeating: glyphs.horizontal, count: width - 2) + glyphs.bottomRight, frame)
        ]
    }

    /// 棒グラフ（`▕████░░░░▏`）。割合を `cells` 桁で描く。
    func bar(_ share: Fraction, cells: Int, fill: Rgb, frame: Rgb) -> [Segment] {
        let ratio = share.total > 0 ? Double(share.value) / Double(share.total) : 0
        let filled = Int((ratio * Double(cells)).rounded())
        let full = min(max(filled, 0), cells)
        return [
            Segment(glyphs.barOpen, frame), Segment(String(repeating: glyphs.barFull, count: full), fill),
            Segment(String(repeating: glyphs.barEmpty, count: cells - full) + glyphs.barClose, frame),
        ]
    }
}
