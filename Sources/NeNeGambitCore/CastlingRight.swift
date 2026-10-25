/// キャスリング権 1 つ分（どちらの色が・どちらの向きに）。
struct CastlingRight: Sendable, Hashable {
    let color: Color
    let side: CastlingSide
}
