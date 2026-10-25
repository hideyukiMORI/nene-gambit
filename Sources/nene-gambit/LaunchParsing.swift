/// 起動オプションを読んだ結果。
enum LaunchParsing {
    case parsed(LaunchOptions)
    /// 読めなかった理由（起動できなかった理由として 1 行で出す）。
    case rejected(String)
}
