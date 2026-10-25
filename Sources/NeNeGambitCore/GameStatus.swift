/// 対局の状態。「終局したか」を判定する経路は `Game.status` の 1 つだけ（ARC-001）。
public enum GameStatus: Sendable, Hashable {
    case ongoing
    case finished(Termination)
}
