/// 指し手の適用。局面を変える経路はここ 1 つ（ARC-004）。
extension Position {
    /// 合法手を適用した次の局面。元の局面は変わらない（値型）。
    ///
    /// `move` は `legalMoves()` が返した手でなければならない。それ以外を渡すのはプログラムの欠陥で、
    /// 動かす駒が無ければ止める。
    public func applying(_ move: Move) -> Position {
        guard let piece = board[move.from] else {
            preconditionFailure("空の升からの指し手: \(move)")
        }
        let captured = board[move.to] ?? capturedEnPassant(by: piece, move)
        let landed = move.promotion.map { Piece(piece.color, $0.pieceKind) } ?? piece
        var next = board.placing(nil, at: move.from).placing(landed, at: move.to)
        next = removingEnPassantVictim(from: next, by: piece, move)
        next = movingCastlingRook(on: next, by: piece, move)
        let resetsClock = piece.kind == .pawn || captured != nil
        return Position(
            board: next,
            sideToMove: sideToMove.opponent,
            rights: SpecialMoveRights(
                castling: castlingAfter(move, by: piece),
                enPassant: enPassantAfter(move, by: piece)
            ),
            clocks: MoveClocks(
                halfmove: resetsClock ? 0 : clocks.halfmove + 1,
                fullmove: sideToMove == .black ? clocks.fullmove + 1 : clocks.fullmove
            )
        )
    }

    private func isEnPassantCapture(by piece: Piece, _ move: Move) -> Bool {
        piece.kind == .pawn && move.to == rights.enPassant && move.from.file != move.to.file
    }

    /// アンパッサンで取られるポーン（行き先の升ではなく、その後ろにいる）。
    private func capturedEnPassant(by piece: Piece, _ move: Move) -> Piece? {
        isEnPassantCapture(by: piece, move) ? Piece(piece.color.opponent, .pawn) : nil
    }

    private func removingEnPassantVictim(from next: Board, by piece: Piece, _ move: Move) -> Board {
        guard isEnPassantCapture(by: piece, move), let victim = move.to.offset(file: 0, rank: -piece.color.forward)
        else {
            return next
        }
        return next.placing(nil, at: victim)
    }

    private func movingCastlingRook(on next: Board, by piece: Piece, _ move: Move) -> Board {
        guard piece.kind == .king, abs(move.to.file - move.from.file) == 2 else {
            return next
        }
        let side: CastlingSide = move.to.file > move.from.file ? .kingside : .queenside
        let rank = move.from.rank
        guard let rookFrom = Square.at(file: side.rookHomeFile, rank: rank),
            let rookTo = Square.at(file: side.rookTargetFile, rank: rank)
        else {
            return next
        }
        return next.placing(nil, at: rookFrom).placing(Piece(piece.color, .rook), at: rookTo)
    }

    /// 王が動けば両方の権利、ルークの元の升から動くか、その升で取られれば片方の権利を失う。
    private func castlingAfter(_ move: Move, by piece: Piece) -> CastlingRights {
        var result = rights.castling
        if piece.kind == .king {
            result = result.revoking(piece.color, .kingside).revoking(piece.color, .queenside)
        }
        for color in Color.allCases {
            for side in CastlingSide.allCases {
                let corner = Square.at(file: side.rookHomeFile, rank: color.homeRank)
                if corner == move.from || corner == move.to {
                    result = result.revoking(color, side)
                }
            }
        }
        return result
    }

    /// ポーンが 2 升進んだら、通り過ぎた升がアンパッサンの升になる。
    private func enPassantAfter(_ move: Move, by piece: Piece) -> Square? {
        guard piece.kind == .pawn, abs(move.to.rank - move.from.rank) == 2 else {
            return nil
        }
        return move.from.offset(file: 0, rank: piece.color.forward)
    }
}
