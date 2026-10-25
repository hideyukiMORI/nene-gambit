import NeNeGambitCore

/// 指し手を選ぶ者の種類。
///
/// いまは「合法手からランダムに選ぶ」だけ（Phase 3 の手順 2）。評価と探索を使う性格は、施主の答え（Q7）が出てから手順 4 で足す。
public enum PlayerKind: Sendable, Hashable {
    case random

    /// 局面で指す手を選ぶ。合法手が無ければ nil（終局している局面）。返す手は必ず `position.legalMoves()` の中にある。
    public func choose(in position: Position, using generator: inout some RandomNumberGenerator) -> Move? {
        switch self {
        case .random:
            return position.legalMoves().randomElement(using: &generator)
        }
    }
}
