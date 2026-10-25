import NeNeGambitCore

/// キャラクターの 1 回の発言。
public struct Remark: Sendable, Hashable {
    /// 話した側。
    public let side: Color
    public let persona: Persona
    public let cue: Cue
    public let text: String

    /// 気分の顔（ASCII 3 文字）。
    public var face: String {
        persona.face(cue.mood)
    }
}
