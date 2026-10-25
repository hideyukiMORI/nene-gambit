import NeNeGambitCore

/// 対局中の発言（COMMS）の状態。どの出来事で誰が話すかの規則はここだけにある（デザインの「COMMS の発言ルール」）。
///
/// - 1 手に 1 行まで。その手でいちばん優先度の高い出来事だけを見て、確率に外れたら黙る
/// - 同じ側は話してから 2 手は黙る（局の始まりと終わりは例外で、両者が続けて話す）
/// - 返しのひと言は次の 1 歩で出す。同じ人は直近 8 回と同じセリフを言わない
/// - 乱数は引数から受け取るので、同じシードからは同じ会話になる
public struct Banter: Sendable {
    /// 画面に出す発言（古い順・最後の 2 つ）。
    public let lines: [Remark]
    private let recent: [Persona: [String]]
    private let lastSpokePly: [Color: Int]
    private let pending: Prompt?
    private let ply: Int

    static let silent = Banter(lines: [], recent: [:], lastSpokePly: [:], pending: nil, ply: 0)

    /// 局の始まり: 白、黒の順に 1 言ずつ。
    func starting(_ players: Players, using generator: inout some RandomNumberGenerator) -> Banter {
        var next = Banter(lines: lines, recent: recent, lastSpokePly: [:], pending: nil, ply: 0)
        next = next.saying(Prompt(speaker: .white, cue: .start), players, using: &generator)
        return next.saying(Prompt(speaker: .black, cue: .start), players, using: &generator)
    }

    /// 1 手の後。終局なら両者の最後のひと言、そうでなければ規則に従って 0〜1 行。
    func reacting(
        to facts: MoveFacts, status: GameStatus, players: Players, using generator: inout some RandomNumberGenerator
    ) -> Banter {
        let ticked = Banter(lines: lines, recent: recent, lastSpokePly: lastSpokePly, pending: nil, ply: ply + 1)
        if case .finished(let termination) = status {
            return ticked.finishing(termination, players, using: &generator)
        }
        if let pending {
            return ticked.saying(pending, players, using: &generator)
        }
        guard let pick = Self.pick(facts, using: &generator), ticked.mayTalk(pick.prompt.speaker) else {
            return ticked
        }
        let spoken = ticked.saying(pick.prompt, players, using: &generator)
        return Banter(
            lines: spoken.lines, recent: spoken.recent, lastSpokePly: spoken.lastSpokePly, pending: pick.reply,
            ply: spoken.ply)
    }

    private func mayTalk(_ side: Color) -> Bool {
        lastSpokePly[side].map { ply - $0 > 2 } ?? true
    }

    private func finishing(
        _ termination: Termination, _ players: Players, using generator: inout some RandomNumberGenerator
    ) -> Banter {
        let order: [Prompt]
        switch termination {
        case .checkmate(let winner):
            order = [Prompt(speaker: winner, cue: .win), Prompt(speaker: winner.opponent, cue: .lose)]
        case .stalemate, .threefoldRepetition, .fiftyMoveRule, .insufficientMaterial:
            order = [Prompt(speaker: .white, cue: .draw), Prompt(speaker: .black, cue: .draw)]
        }
        return order.reduce(self) { banter, prompt in banter.saying(prompt, players, using: &generator) }
    }

    /// 1 行を言う。直近 8 回のセリフを避けて乱数で選ぶ（全部が直近なら避けない）。
    private func saying(_ prompt: Prompt, _ players: Players, using generator: inout some RandomNumberGenerator)
        -> Banter
    {
        let persona = prompt.speaker == .white ? players.white : players.black
        let all = persona.lines(for: prompt.cue)
        let said = recent[persona] ?? []
        let fresh = all.filter { !said.contains($0) }
        let text = (fresh.isEmpty ? all : fresh).randomElement(using: &generator) ?? ""
        var remembered = recent
        remembered[persona] = Array((said + [text]).suffix(8))
        var spoke = lastSpokePly
        spoke[prompt.speaker] = ply
        let remark = Remark(side: prompt.speaker, persona: persona, cue: prompt.cue, text: text)
        return Banter(
            lines: Array((lines + [remark]).suffix(2)), recent: remembered, lastSpokePly: spoke, pending: nil, ply: ply)
    }

    /// その手でいちばん優先度の高い出来事と、その確率の抽選の結果。
    static func pick(_ facts: MoveFacts, using generator: inout some RandomNumberGenerator) -> BanterPick? {
        let mover = facts.mover
        let other = mover.opponent
        let roll = Int.random(in: 0..<100, using: &generator)
        let coin = Bool.random(using: &generator)
        if facts.captured == .queen {
            let reply = coin ? Prompt(speaker: mover, cue: .queenTaken) : nil
            return BanterPick(prompt: Prompt(speaker: other, cue: .queenLost), reply: reply)
        }
        if facts.givesCheck {
            let prompt = coin ? Prompt(speaker: mover, cue: .check) : Prompt(speaker: other, cue: .checked)
            return roll < 85 ? BanterPick(prompt: prompt, reply: nil) : nil
        }
        if facts.isPromotion || facts.isEnPassant {
            return BanterPick(
                prompt: Prompt(speaker: mover, cue: facts.isPromotion ? .promotion : .enPassant), reply: nil)
        }
        if facts.isCastle {
            return roll < 80 ? BanterPick(prompt: Prompt(speaker: mover, cue: .castle), reply: nil) : nil
        }
        return quieterPick(facts, roll: roll, coin: coin)
    }

    private static func quieterPick(_ facts: MoveFacts, roll: Int, coin: Bool) -> BanterPick? {
        let mover = facts.mover
        if let captured = facts.captured {
            let prompt = coin ? Prompt(speaker: mover, cue: .capture) : Prompt(speaker: mover.opponent, cue: .lostPiece)
            return roll < (captured == .pawn ? 20 : 60) ? BanterPick(prompt: prompt, reply: nil) : nil
        }
        if facts.quietPlies > 0, facts.quietPlies % 6 == 0, roll < 50 {
            return BanterPick(prompt: Prompt(speaker: mover.opponent, cue: .idle), reply: nil)
        }
        return nil
    }
}
