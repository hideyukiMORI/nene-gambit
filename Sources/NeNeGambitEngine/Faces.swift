/// 1 人の性格の、気分ごとの顔。
struct Faces: Sendable, Hashable {
    let smug: String
    let neutral: String
    let grim: String

    func face(_ mood: Mood) -> String {
        switch mood {
        case .smug:
            return smug
        case .neutral:
            return neutral
        case .grim:
            return grim
        }
    }
}
