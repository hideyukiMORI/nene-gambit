/// キャスリング権（白黒 × 王側・女王側の 4 つ）。
public struct CastlingRights: Sendable, Hashable {
    private let bits: UInt8

    /// どの権利も無い。
    public static let none = CastlingRights(bits: 0)

    /// 4 つの権利がすべてある（初期局面）。
    public static let all = CastlingRights(bits: 0b1111)

    /// その色がその向きにキャスリングする権利を持つか。
    public func allows(_ color: Color, _ side: CastlingSide) -> Bool {
        bits & Self.bit(color, side) != 0
    }

    /// 権利を 1 つ足した値。
    func granting(_ color: Color, _ side: CastlingSide) -> CastlingRights {
        CastlingRights(bits: bits | Self.bit(color, side))
    }

    /// 権利を 1 つ取り除いた値。
    func revoking(_ color: Color, _ side: CastlingSide) -> CastlingRights {
        CastlingRights(bits: bits & ~Self.bit(color, side))
    }

    private static func bit(_ color: Color, _ side: CastlingSide) -> UInt8 {
        switch (color, side) {
        case (.white, .kingside):
            return 0b0001
        case (.white, .queenside):
            return 0b0010
        case (.black, .kingside):
            return 0b0100
        case (.black, .queenside):
            return 0b1000
        }
    }
}
