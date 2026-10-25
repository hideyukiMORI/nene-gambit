/// 終局後、次の局までの残り時間（秒）。
public struct Countdown: Sendable, Hashable {
    public let remaining: Int
    public let total: Int

    /// 残りを 0〜total に収めて作る。
    public init(remaining: Int, total: Int) {
        self.total = max(total, 1)
        self.remaining = min(max(remaining, 0), self.total)
    }
}
