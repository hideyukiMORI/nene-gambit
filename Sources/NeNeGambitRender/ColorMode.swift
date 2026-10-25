/// 端末に色を伝える方式。24 ビットが無ければ 256 色へ落とす。
///
/// どちらで描いているかを HUD に出すので Render が持ち、Terminal はこの値で色を符号化する。
public enum ColorMode: Sendable, Hashable {
    case trueColor
    case palette256
}
