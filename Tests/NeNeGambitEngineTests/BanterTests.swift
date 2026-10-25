import NeNeGambitCore
import NeNeGambitEngine
import Testing

/// キャラクターの発言（FR-14）。
struct BanterTests {
    /// 台本は 1 人 50 本・出来事ごとに 1 本以上・どれも ASCII の印字可能な文字だけで 72 文字以内・重複なし（施主の決定 2026-10-25）。
    @Test(arguments: Persona.allCases)
    func scriptHasFiftyShortAsciiLines(persona: Persona) {
        let lines = Cue.allCases.flatMap { persona.lines(for: $0) }
        #expect(lines.count == 50)
        #expect(Set(lines).count == lines.count)
        for cue in Cue.allCases {
            #expect(!persona.lines(for: cue).isEmpty, "\(persona.handle) に \(cue) のセリフが無い")
        }
        for line in lines {
            #expect(line.count <= 72, "長すぎる: \(line)")
            #expect(line.unicodeScalars.allSatisfy { (0x20...0x7E).contains($0.value) }, "ASCII でない: \(line)")
        }
    }

    @Test(arguments: Persona.allCases)
    func facesAreThreeAsciiCharacters(persona: Persona) {
        for mood in Mood.allCases {
            let face = persona.face(mood)
            #expect(face.count == 3 && face.unicodeScalars.allSatisfy { (0x20...0x7E).contains($0.value) })
        }
    }

    /// 局が始まると白、黒の順に始まりのひと言を言う。白黒は違う 2 名。
    @Test(arguments: [UInt64(1), 2, 3, 4, 5])
    func gameStartsWithBothGreetings(seed: UInt64) {
        var generator = SplitMix64(seed: seed)
        let series = GameSeries.starting(using: &generator)
        #expect(series.players.white != series.players.black)
        #expect(series.banter.lines.map(\.cue) == [.start, .start])
        #expect(series.banter.lines.map(\.side) == [.white, .black])
        #expect(series.banter.lines.map(\.persona) == [series.players.white, series.players.black])
    }

    /// 終局の 1 歩で両者が最後のひと言を言う（チェックメイトなら勝った側が先）。
    @Test func gameOverEndsWithBothVerdicts() {
        var generator = SplitMix64(seed: 9)
        var series = GameSeries.starting(using: &generator)
        while case .ongoing = series.game.status {
            series = series.advanced(using: &generator)
        }
        let cues = series.banter.lines.map(\.cue)
        guard case .finished(let termination) = series.game.status else {
            Issue.record("終局していない")
            return
        }
        switch termination {
        case .checkmate(let winner):
            #expect(cues == [.win, .lose])
            #expect(series.banter.lines.first?.side == winner)
        case .stalemate, .threefoldRepetition, .fiftyMoveRule, .insufficientMaterial:
            #expect(cues == [.draw, .draw])
        }
    }

    /// 同じシードからは同じ会話が出る。
    @Test func sameSeedGivesTheSameBanter() {
        #expect(Self.transcript(seed: 21, plies: 40) == Self.transcript(seed: 21, plies: 40))
        #expect(Self.transcript(seed: 21, plies: 40) != Self.transcript(seed: 22, plies: 40))
    }

    /// 話す頻度: 100 半手あたり 8〜30 回（局の始まりと終わりを除く）。
    ///
    /// 2026-10-25 の実測（シード 4・300 半手・探索ありの対局）は 14 回（43 回のうち王手まわり 22・取り合い 18・静かな局面 2）。
    /// ランダムな対局のときは 11 回で、4 割近くが静かな局面のひと言だった（ADR 0007）。この範囲は「黙り込む」「しゃべりすぎる」退行を捕まえるためのもの。
    @Test func talksOftenButNotConstantly() {
        let framing: Set<Cue> = [.start, .win, .lose, .draw]
        let lines = Self.transcript(seed: 4, plies: 300).filter { !framing.contains($0.cue) }
        let perHundred = lines.count * 100 / 300
        #expect((8...30).contains(perHundred), "100 半手あたり \(perHundred) 回")
    }

    /// `plies` 歩のあいだに新しく出た発言の列。
    static func transcript(seed: UInt64, plies: Int) -> [Remark] {
        var generator = SplitMix64(seed: seed)
        var series = GameSeries.starting(using: &generator)
        var spoken: [Remark] = series.banter.lines
        for _ in 0..<plies {
            let before = series.banter.lines
            series = series.advanced(using: &generator)
            let after = series.banter.lines
            let fresh = after.filter { !before.contains($0) }
            spoken += fresh
        }
        return spoken
    }
}
