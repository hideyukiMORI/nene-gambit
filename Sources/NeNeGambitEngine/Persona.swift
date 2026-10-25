/// 白黒の性格（キャスト）。施主の決定（Q7・2026-10-25）: 4 名で、局ごとにランダムに組む。
///
/// 性格は「指し方」と「話し方」を持つ。指し方は評価と探索が入るまで全員ランダム（Phase 3 の手順 4 で差を付ける）。
public enum Persona: Sendable, Hashable, CaseIterable {
    /// 自信過剰な攻め屋。
    case vex
    /// 穏やかな葬儀屋。
    case mort
    /// 計画ゼロの混沌。
    case nullPointer
    /// 優しくて容赦ない、根に持つおばあちゃん。
    case granny

    /// 画面に出す名前。
    public var handle: String {
        switch self {
        case .vex:
            return "VEX.EXE"
        case .mort:
            return "MORT.SH"
        case .nullPointer:
            return "NULL_PTR"
        case .granny:
            return "GRANNY.DLL"
        }
    }

    /// 指し方。
    public var strategy: PlayerKind {
        switch self {
        case .vex, .mort, .nullPointer, .granny:
            return .random
        }
    }

    /// 気分ごとの顔（ASCII 3 文字）。
    public func face(_ mood: Mood) -> String {
        faces.face(mood)
    }

    private var faces: Faces {
        switch self {
        case .vex:
            return Faces(smug: ">:)", neutral: "B-)", grim: ">:(")
        case .mort:
            return Faces(smug: ":| ", neutral: "._.", grim: "x_x")
        case .nullPointer:
            return Faces(smug: ">:D", neutral: "?_?", grim: "o_O")
        case .granny:
            return Faces(smug: "^_^", neutral: ":) ", grim: "-_-")
        }
    }

    /// セリフの台本（1 人 50 本）。
    var script: [ScriptLine] {
        switch self {
        case .vex:
            return Self.vexScript
        case .mort:
            return Self.mortScript
        case .nullPointer:
            return Self.nullPointerScript
        case .granny:
            return Self.grannyScript
        }
    }

    /// その出来事のセリフ（名前や顔と同じく性格の公開の属性）。
    public func lines(for cue: Cue) -> [String] {
        script.filter { $0.cue == cue }.map(\.text)
    }
}
