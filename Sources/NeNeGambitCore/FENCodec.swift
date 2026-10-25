/// FEN（局面の 1 行の表記）の読み書き。局面と文字列を行き来する経路はここ 1 つ（ARC-001 / ARC-008）。
///
/// 6 欄（配置・手番・キャスリング権・アンパッサンの升・半手の時計・手数）がそろったものだけを読む。
/// 欄の足りない FEN を既定値で補わない。
public enum FENCodec {
    private static let letters: [(Character, Piece)] = [
        ("P", Piece(.white, .pawn)), ("N", Piece(.white, .knight)), ("B", Piece(.white, .bishop)),
        ("R", Piece(.white, .rook)), ("Q", Piece(.white, .queen)), ("K", Piece(.white, .king)),
        ("p", Piece(.black, .pawn)), ("n", Piece(.black, .knight)), ("b", Piece(.black, .bishop)),
        ("r", Piece(.black, .rook)), ("q", Piece(.black, .queen)), ("k", Piece(.black, .king)),
    ]
    private static let castlingLetters: [(Character, CastlingRight)] = [
        ("K", CastlingRight(color: .white, side: .kingside)), ("Q", CastlingRight(color: .white, side: .queenside)),
        ("k", CastlingRight(color: .black, side: .kingside)), ("q", CastlingRight(color: .black, side: .queenside)),
    ]
    private static let fileLetters: [Character] = ["a", "b", "c", "d", "e", "f", "g", "h"]

    /// FEN を読む。
    public static func decode(_ text: String) -> FENDecoding {
        let fields = text.split(separator: " ", omittingEmptySubsequences: false).map(String.init)
        guard fields.count == 6 else {
            return .rejected(.fieldCount)
        }
        guard let board = decodePlacement(fields[0]) else {
            return .rejected(.placement)
        }
        guard Color.allCases.allSatisfy({ color in Square.all.filter { board[$0] == Piece(color, .king) }.count == 1 })
        else {
            return .rejected(.kings)
        }
        guard let side = ["w": Color.white, "b": Color.black][fields[1]] else {
            return .rejected(.sideToMove)
        }
        guard let castling = decodeCastling(fields[2]) else {
            return .rejected(.castling)
        }
        guard let enPassant = decodeEnPassant(fields[3]) else {
            return .rejected(.enPassant)
        }
        guard let halfmove = Int(fields[4]), halfmove >= 0 else {
            return .rejected(.halfmoveClock)
        }
        guard let fullmove = Int(fields[5]), fullmove >= 1 else {
            return .rejected(.fullmoveNumber)
        }
        let rights = SpecialMoveRights(castling: castling, enPassant: enPassant.square)
        let clocks = MoveClocks(halfmove: halfmove, fullmove: fullmove)
        return .decoded(Position(board: board, sideToMove: side, rights: rights, clocks: clocks))
    }

    /// 局面を FEN に書く。`decode` で読んだ FEN は同じ文字列に戻る。
    public static func encode(_ position: Position) -> String {
        let castling = castlingLetters.filter { position.rights.castling.allows($0.1.color, $0.1.side) }.map {
            String($0.0)
        }.joined()
        return [
            encodePlacement(position.board),
            position.sideToMove == .white ? "w" : "b",
            castling.isEmpty ? "-" : castling,
            position.rights.enPassant.map(name) ?? "-",
            String(position.clocks.halfmove),
            String(position.clocks.fullmove),
        ].joined(separator: " ")
    }

    /// 升の名前（`e3` 等）。
    static func name(_ square: Square) -> String {
        "\(fileLetters[square.file])\(square.rank + 1)"
    }

    private static func decodePlacement(_ field: String) -> Board? {
        let ranks = field.split(separator: "/", omittingEmptySubsequences: false)
        guard ranks.count == 8 else {
            return nil
        }
        var board = Board.empty
        for (row, text) in ranks.enumerated() {
            var file = 0
            for character in text {
                if let skip = character.wholeNumberValue, (1...8).contains(skip) {
                    file += skip
                } else if let piece = letters.first(where: { $0.0 == character })?.1,
                    let square = Square.at(file: file, rank: 7 - row)
                {
                    board = board.placing(piece, at: square)
                    file += 1
                } else {
                    return nil
                }
            }
            guard file == 8 else {
                return nil
            }
        }
        return board
    }

    private static func encodePlacement(_ board: Board) -> String {
        (0..<8).reversed().map { rank in
            var text = ""
            var empty = 0
            for file in 0..<8 {
                let piece = Square.at(file: file, rank: rank).flatMap { board[$0] }
                if let piece, let letter = letters.first(where: { $0.1 == piece })?.0 {
                    text += empty > 0 ? "\(empty)\(letter)" : "\(letter)"
                    empty = 0
                } else {
                    empty += 1
                }
            }
            return empty > 0 ? text + "\(empty)" : text
        }.joined(separator: "/")
    }

    private static func decodeCastling(_ field: String) -> CastlingRights? {
        if field == "-" {
            return CastlingRights.none
        }
        var rights = CastlingRights.none
        for character in field {
            guard let entry = castlingLetters.first(where: { $0.0 == character }),
                !rights.allows(entry.1.color, entry.1.side)
            else {
                return nil
            }
            rights = rights.granting(entry.1.color, entry.1.side)
        }
        let canonical = castlingLetters.filter { rights.allows($0.1.color, $0.1.side) }.map { String($0.0) }.joined()
        return canonical == field ? rights : nil
    }

    /// アンパッサンの欄。`-` は「升が無い」として読めたことを表す（読めなかったときだけ nil）。
    private static func decodeEnPassant(_ field: String) -> EnPassantField? {
        if field == "-" {
            return EnPassantField(square: nil)
        }
        let characters = Array(field)
        guard characters.count == 2, let file = fileLetters.firstIndex(of: characters[0]),
            let rankNumber = characters[1].wholeNumberValue, [3, 6].contains(rankNumber)
        else {
            return nil
        }
        return EnPassantField(square: Square.at(file: file, rank: rankNumber - 1))
    }
}
