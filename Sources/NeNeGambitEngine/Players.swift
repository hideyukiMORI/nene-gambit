/// その局の白と黒の性格。局ごとに 4 名から違う 2 名をランダムに組む（施主の決定 Q7）。
public struct Players: Sendable, Hashable {
    public let white: Persona
    public let black: Persona

    /// 組を作る。
    public init(white: Persona, black: Persona) {
        self.white = white
        self.black = black
    }

    /// 4 名から違う 2 名を乱数で選ぶ。
    static func drawn(using generator: inout some RandomNumberGenerator) -> Players {
        let shuffled = Persona.allCases.shuffled(using: &generator)
        return Players(white: shuffled[0], black: shuffled[1])
    }
}
