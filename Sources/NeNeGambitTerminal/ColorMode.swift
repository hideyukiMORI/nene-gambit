/// 端末に色を伝える方式。24 ビットが無ければ 256 色へ落とす。
public enum ColorMode: Sendable, Hashable {
    case trueColor
    case palette256
}
