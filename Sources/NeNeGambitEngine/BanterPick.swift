/// 1 手の出来事から選んだ発言と、次の 1 歩で出す返し（無ければ nil）。
struct BanterPick: Sendable, Hashable {
    let prompt: Prompt
    let reply: Prompt?
}
