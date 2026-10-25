/// 発言のときの気分。
public enum Mood: Sendable, Hashable, CaseIterable {
    /// 得意げ（取った・王手した・勝った）。
    case smug
    /// ふつう（始まり・静かな局面・引き分け）。
    case neutral
    /// 沈んでいる（取られた・王手された・負けた）。
    case grim
}
