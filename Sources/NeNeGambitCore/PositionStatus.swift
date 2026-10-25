/// 合法手の有無から決まる局面の状態。
///
/// 同一局面 3 回・50 手ルール・駒不足による引き分けは、対局の履歴を扱う Phase 3 の手順 2 で終局の理由として足す。
public enum PositionStatus: Sendable, Hashable {
    /// 手番の側に合法手がある。
    case ongoing
    /// 手番の側に合法手が無く、王手されている。
    case checkmate(winner: Color)
    /// 手番の側に合法手が無く、王手されていない。
    case stalemate
}
