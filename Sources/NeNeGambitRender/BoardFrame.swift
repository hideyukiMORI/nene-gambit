import NeNeGambitCore

/// 盤を格子のどこに、1 升何桁×何行で描くか。大きな盤は 7×3、縮小版は 3×1（ADR 0007）。
struct BoardFrame: Sendable {
    let column: Int
    let row: Int
    let squareWidth: Int
    let squareHeight: Int

    /// 盤・段の数字・筋の文字を描く。直前の手の 2 升は駒を `[ ]` で囲み、詰まされた王の升は色を替える。
    func draw(_ game: Game, options: DisplayOptions, into grid: inout Grid) {
        let theme = options.theme
        let last = game.moves.last
        let mated = matedKing(game)
        for square in Square.all {
            let isLight = (square.file + square.rank) % 2 == 1
            let background = square == mated ? theme.matedSquare : (isLight ? theme.lightSquare : theme.darkSquare)
            let piece = game.position.board[square]
            let hot = square == last?.from || square == last?.to
            drawSquare(
                square, SquareLook(piece: piece, hot: hot, background: background), options: options, into: &grid)
        }
        let labels = CellColors(foreground: theme.dim, background: theme.ground)
        for square in Square.all where square.file == 0 {
            let top = row + (7 - square.rank) * squareHeight + squareHeight / 2
            grid.write(String(square.name.suffix(1)), column: column - 2, row: top, colors: labels)
        }
        for square in Square.all where square.rank == 0 {
            let left = column + square.file * squareWidth + squareWidth / 2
            grid.write(String(square.name.prefix(1)), column: left, row: row + 8 * squareHeight, colors: labels)
        }
    }

    private func drawSquare(_ square: Square, _ look: SquareLook, options: DisplayOptions, into grid: inout Grid) {
        let theme = options.theme
        let background = look.background
        let left = column + square.file * squareWidth
        let top = row + (7 - square.rank) * squareHeight
        let blank = String(repeating: " ", count: squareWidth)
        for line in 0..<squareHeight {
            grid.write(
                blank, column: left, row: top + line, colors: CellColors(foreground: theme.text, background: background)
            )
        }
        let middle = top + squareHeight / 2
        let center = left + squareWidth / 2
        if let piece = look.piece {
            let color = piece.color == .white ? theme.whitePiece : theme.blackPiece
            grid.write(
                String(options.glyphs.glyph(for: piece.kind)), column: center, row: middle,
                colors: CellColors(foreground: color, background: background))
        }
        if look.hot {
            let bracket = CellColors(foreground: theme.accent, background: background)
            grid.write("[", column: center - 1, row: middle, colors: bracket)
            grid.write("]", column: center + 1, row: middle, colors: bracket)
        }
    }

    /// チェックメイトで終わった局の、詰まされた側の王の升。
    private func matedKing(_ game: Game) -> Square? {
        guard case .finished(.checkmate(let winner)) = game.status else {
            return nil
        }
        return Square.all.first { game.position.board[$0] == Piece(winner.opponent, .king) }
    }
}
