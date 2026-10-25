/// 棋譜の行のどこに手番のカーソルを置くか。
enum LogCursor: Sendable, Hashable {
    case none
    case white
    case black
}
