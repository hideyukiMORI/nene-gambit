import NeNeGambitCore

/// 駒の字形の組（FR-07）。既定は英字。
public enum GlyphSet: Sendable, Hashable, CaseIterable {
    /// `K Q R B N P`。白と黒は色で分ける。
    case letters
    /// Unicode の駒記号。白も黒も同じ字形を使い、色で分ける。キングからナイトは塗りつぶし（細い線の字形は端末で見えにくい）、
    /// ポーンだけは輪郭の字形（塗りつぶしの U+265F は絵文字の字形で描かれて色が効かない端末がある・ADR 0013）。
    case symbols

    /// もう一方の組（実行中のキーで切り替える）。
    public var toggled: GlyphSet {
        switch self {
        case .letters:
            return .symbols
        case .symbols:
            return .letters
        }
    }

    /// 駒の字形。
    func glyph(for kind: PieceKind) -> Character {
        switch self {
        case .letters:
            return Self.letter(kind)
        case .symbols:
            return Self.symbol(kind)
        }
    }

    private static func letter(_ kind: PieceKind) -> Character {
        switch kind {
        case .king: "K"
        case .queen: "Q"
        case .rook: "R"
        case .bishop: "B"
        case .knight: "N"
        case .pawn: "P"
        }
    }

    private static func symbol(_ kind: PieceKind) -> Character {
        switch kind {
        case .king: "\u{265A}"
        case .queen: "\u{265B}"
        case .rook: "\u{265C}"
        case .bishop: "\u{265D}"
        case .knight: "\u{265E}"
        case .pawn: "\u{2659}"
        }
    }
}
