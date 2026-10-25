import NeNeGambitCore

/// 誰が、どの出来事について話すか。
struct Prompt: Sendable, Hashable {
    let speaker: Color
    let cue: Cue
}
