/// 枠の字形（`FrameStyle` ごと）。
struct FrameGlyphs: Sendable, Hashable {
    let topLeft: String
    let topRight: String
    let teeLeft: String
    let teeRight: String
    let bottomLeft: String
    let bottomRight: String
    let horizontal: String
    let vertical: String
    let barFull: String
    let barEmpty: String
    let barOpen: String
    let barClose: String
    /// 行頭の印（COMMS の話し手・HUD の題）。
    let marker: String
    /// 棋譜の手番のカーソル。
    let cursor: String

    static func of(_ style: FrameStyle) -> FrameGlyphs {
        switch style {
        case .boxDrawing:
            return FrameGlyphs(
                topLeft: "┌", topRight: "┐", teeLeft: "├", teeRight: "┤", bottomLeft: "└", bottomRight: "┘",
                horizontal: "─", vertical: "│", barFull: "█", barEmpty: "░", barOpen: "▕", barClose: "▏", marker: "▌",
                cursor: "▌")
        case .ascii:
            return FrameGlyphs(
                topLeft: "+", topRight: "+", teeLeft: "+", teeRight: "+", bottomLeft: "+", bottomRight: "+",
                horizontal: "-", vertical: "|", barFull: "#", barEmpty: "-", barOpen: "[", barClose: "]", marker: ">",
                cursor: "_")
        }
    }
}
