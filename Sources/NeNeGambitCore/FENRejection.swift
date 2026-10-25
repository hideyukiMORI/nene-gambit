/// FEN を読めなかった理由。
public enum FENRejection: Sendable, Hashable {
    /// 空白で区切った欄が 6 つでない。
    case fieldCount
    /// 駒の配置の欄が読めない（段が 8 つでない・1 段が 8 升でない・知らない文字）。
    case placement
    /// 白黒それぞれの王がちょうど 1 つでない。
    case kings
    /// 手番の欄が `w` でも `b` でもない。
    case sideToMove
    /// キャスリング権の欄が読めない。
    case castling
    /// アンパッサンの欄が `-` でも 3 段目・6 段目の升でもない。
    case enPassant
    /// 半手の時計が 0 以上の整数でない。
    case halfmoveClock
    /// 手数が 1 以上の整数でない。
    case fullmoveNumber
}
