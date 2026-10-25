/// 合法手の生成。指し手を生成する経路はここ 1 つ（ARC-001）。
extension Position {
    /// 手番の側の合法手。自分の王を王手に晒す手は含まない。
    public func legalMoves() -> [Move] {
        pseudoLegalMoves().filter { !applying($0).isKingAttacked(sideToMove) }
    }

    /// 駒の動き方の上では指せる手（自分の王が王手に晒されるかはまだ見ていない）。
    private func pseudoLegalMoves() -> [Move] {
        var moves: [Move] = []
        moves.reserveCapacity(64)
        for square in Square.all {
            guard let piece = board[square], piece.color == sideToMove else {
                continue
            }
            switch piece.kind {
            case .pawn:
                appendPawnMoves(from: square, into: &moves)
            case .knight:
                appendSteps(from: square, Self.knightSteps, into: &moves)
            case .bishop:
                appendSlides(from: square, Self.bishopDirections, into: &moves)
            case .rook:
                appendSlides(from: square, Self.rookDirections, into: &moves)
            case .queen:
                appendSlides(from: square, Self.rookDirections + Self.bishopDirections, into: &moves)
            case .king:
                appendSteps(from: square, Self.kingSteps, into: &moves)
                appendCastling(from: square, into: &moves)
            }
        }
        return moves
    }

    /// 行き先が空か相手の駒なら指せる。
    private func canLand(on square: Square) -> Bool {
        board[square]?.color != sideToMove
    }

    private func appendSteps(from square: Square, _ steps: [(Int, Int)], into moves: inout [Move]) {
        for step in steps {
            if let target = square.offset(file: step.0, rank: step.1), canLand(on: target) {
                moves.append(Move(from: square, to: target))
            }
        }
    }

    private func appendSlides(from square: Square, _ directions: [(Int, Int)], into moves: inout [Move]) {
        for direction in directions {
            var current = square.offset(file: direction.0, rank: direction.1)
            while let target = current, canLand(on: target) {
                moves.append(Move(from: square, to: target))
                if board[target] != nil {
                    break
                }
                current = target.offset(file: direction.0, rank: direction.1)
            }
        }
    }

    private func appendPawnMoves(from square: Square, into moves: inout [Move]) {
        let forward = sideToMove.forward
        if let one = square.offset(file: 0, rank: forward), board[one] == nil {
            appendPawnMove(from: square, to: one, into: &moves)
            let startRank = sideToMove.homeRank + forward
            if square.rank == startRank, let two = one.offset(file: 0, rank: forward), board[two] == nil {
                moves.append(Move(from: square, to: two))
            }
        }
        for fileStep in [-1, 1] {
            guard let target = square.offset(file: fileStep, rank: forward) else {
                continue
            }
            if board[target]?.color == sideToMove.opponent || target == rights.enPassant {
                appendPawnMove(from: square, to: target, into: &moves)
            }
        }
    }

    /// 最終段に着くなら昇格の 4 種に分ける。
    private func appendPawnMove(from square: Square, to target: Square, into moves: inout [Move]) {
        if target.rank == sideToMove.opponent.homeRank {
            for kind in PromotionKind.allCases {
                moves.append(Move(from: square, to: target, promotion: kind))
            }
        } else {
            moves.append(Move(from: square, to: target))
        }
    }

    /// キャスリング。王手されていない・間が空いている・王が通る升に利きが無いことをここで見る（行き先は合法手の絞り込みが見る）。
    private func appendCastling(from square: Square, into moves: inout [Move]) {
        let home = sideToMove.homeRank
        guard square == Square.at(file: 4, rank: home), !isAttacked(square, by: sideToMove.opponent) else {
            return
        }
        for side in CastlingSide.allCases where rights.castling.allows(sideToMove, side) {
            let rookFile = side.rookHomeFile
            guard let rookSquare = Square.at(file: rookFile, rank: home), board[rookSquare] == Piece(sideToMove, .rook)
            else {
                continue
            }
            let between = min(rookFile, 4) + 1..<max(rookFile, 4)
            let empty = between.allSatisfy { file in Square.at(file: file, rank: home).map { board[$0] == nil } ?? false
            }
            let passing = Square.at(file: side.rookTargetFile, rank: home)
            let target = Square.at(file: side.kingTargetFile, rank: home)
            if empty, let passing, !isAttacked(passing, by: sideToMove.opponent), let target {
                moves.append(Move(from: square, to: target))
            }
        }
    }
}
