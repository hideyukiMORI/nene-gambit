import NeNeGambitCore

/// 画面に出す文言。文言のリテラルを持つのはここだけ（キャラクターの名前とセリフは Engine の性格が持つ）。
///
/// ASCII の英語の大文字にしてある。1 文字 1 桁の前提（ADR 0005）を全角や幅の曖昧な文字で崩さないため。
enum Wording {
    static let title = "NENE//GAMBIT"
    static let match = "MATCH"
    static let score = "SCORE"
    static let log = "LOG"
    static let result = "RESULT"
    static let nextGame = "NEXT GAME  "
    static let gameLabel = "GAME      "
    static let whiteLabel = "WHITE     "
    static let blackLabel = "BLACK     "
    static let turnLabel = "TURN      "
    static let lastLabel = "LAST "

    static func gameNumber(_ number: Int) -> String {
        padded(number, width: 3)
    }

    static func headerGame(_ number: Int) -> String {
        "GAME " + padded(number, width: 3)
    }

    static func seed(_ seed: UInt64) -> String {
        let hex = String(seed, radix: 16, uppercase: true)
        return "SEED 0x" + String(repeating: "0", count: max(16 - hex.count, 0)) + hex
    }

    static func colors(_ mode: ColorMode) -> String {
        switch mode {
        case .trueColor:
            return "24BIT"
        case .palette256:
            return "256C"
        }
    }

    static func side(_ color: Color) -> String {
        switch color {
        case .white:
            return "WHITE"
        case .black:
            return "BLACK"
        }
    }

    static func moveNumber(_ number: Int) -> String {
        " :: MOVE " + padded(number, width: 2)
    }

    static let noTurn = "--"

    static func glyphs(_ set: GlyphSet) -> String {
        switch set {
        case .letters:
            return "LETTERS"
        case .symbols:
            return "SYMBOLS"
        }
    }

    static let quitKey = "[q]"
    static let quitName = " QUIT   "
    static let glyphKey = "[g]"
    static let glyphName = " GLYPHS: "
    static let themeKey = "[t]"
    static let themeName = " THEME: "

    static func tooSmall(need: ScreenSize) -> String {
        "TERMINAL TOO SMALL (NEED \(need.columns)x\(need.rows))"
    }

    static func scoreTag(_ result: GameResult) -> String {
        switch result {
        case .whiteWins:
            return "W  "
        case .blackWins:
            return "B  "
        case .draw:
            return "=  "
        }
    }

    static func headline(_ termination: Termination) -> String {
        switch termination.result {
        case .whiteWins:
            return ">> 1-0   WHITE WINS"
        case .blackWins:
            return ">> 0-1   BLACK WINS"
        case .draw:
            return ">> 1/2   DRAW"
        }
    }

    static func reason(_ termination: Termination) -> String {
        switch termination {
        case .checkmate:
            return "CHECKMATE"
        case .stalemate:
            return "STALEMATE"
        case .threefoldRepetition:
            return "THREEFOLD REPETITION"
        case .fiftyMoveRule:
            return "FIFTY-MOVE RULE"
        case .insufficientMaterial:
            return "INSUFFICIENT MATERIAL"
        }
    }

    static func seconds(_ value: Int) -> String {
        "\(value)s"
    }

    static func padded(_ number: Int, width: Int) -> String {
        let digits = String(number)
        return String(repeating: "0", count: max(width - digits.count, 0)) + digits
    }
}
