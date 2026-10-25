import NeNeGambitCore

/// 白黒の性格（キャスト）。施主の決定（Q7・2026-10-25）: 4 名で、局ごとにランダムに組む。
///
/// 性格は「指し方」（`SearchProfile`・FR-06）と「話し方」（台本）を持つ。
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

    /// 指し方（ADR 0009）。VEX は攻め・MORT は守り・NULL_PTR は浅く大きくばらつく・GRANNY はいちばん深く読む。
    var profile: SearchProfile {
        switch self {
        case .vex:
            return SearchProfile(
                depth: 3, nodeLimit: 60_000, openingPlies: 6, openingMargin: 40, tieMargin: 15,
                weights: StyleWeights(center: 8, pawnAdvance: 4, kingShelter: 10, aggression: 6))
        case .mort:
            return SearchProfile(
                depth: 3, nodeLimit: 60_000, openingPlies: 6, openingMargin: 30, tieMargin: 10,
                weights: StyleWeights(center: 6, pawnAdvance: 6, kingShelter: 30, aggression: 1))
        case .nullPointer:
            return SearchProfile(
                depth: 1, nodeLimit: 5_000, openingPlies: 10, openingMargin: 200, tieMargin: 120,
                weights: StyleWeights(center: 2, pawnAdvance: 2, kingShelter: 0, aggression: 2))
        case .granny:
            return SearchProfile(
                depth: 4, nodeLimit: 150_000, openingPlies: 4, openingMargin: 25, tieMargin: 8,
                weights: StyleWeights(center: 8, pawnAdvance: 5, kingShelter: 20, aggression: 3))
        }
    }

    /// その局で指す手。合法手が無ければ nil。返す手は必ず合法手の中にある。
    public func choose(in game: Game, using generator: inout some RandomNumberGenerator) -> Move? {
        Searcher.choose(in: game, profile: profile, using: &generator)
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
