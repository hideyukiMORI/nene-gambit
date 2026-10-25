/// 端末を開いた結果。
public enum ConsoleOpening: Sendable, Hashable {
    case opened
    /// 標準入力か標準出力が端末でない。
    case notATerminal
    /// 端末の設定を読めないか書けない。
    case failed
}
