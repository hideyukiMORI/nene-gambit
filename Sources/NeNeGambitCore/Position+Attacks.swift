/// 升への利きの判定。
extension Position {
    static let knightSteps = [(1, 2), (2, 1), (2, -1), (1, -2), (-1, -2), (-2, -1), (-2, 1), (-1, 2)]
    static let kingSteps = [(1, 0), (1, 1), (0, 1), (-1, 1), (-1, 0), (-1, -1), (0, -1), (1, -1)]
    static let rookDirections = [(1, 0), (0, 1), (-1, 0), (0, -1)]
    static let bishopDirections = [(1, 1), (-1, 1), (-1, -1), (1, -1)]

    /// その色の王が、相手の駒の利きの中にあるか。
    func isKingAttacked(_ color: Color) -> Bool {
        guard let king = board.kingSquare(of: color) else {
            return false
        }
        return isAttacked(king, by: color.opponent)
    }

    /// 升が attacker の色の駒の利きの中にあるか。
    func isAttacked(_ square: Square, by attacker: Color) -> Bool {
        attackedByPawn(square, attacker)
            || attackedByStep(square, attacker, Self.knightSteps, .knight)
            || attackedByStep(square, attacker, Self.kingSteps, .king)
            || attackedBySlider(square, attacker, Self.rookDirections, .rook)
            || attackedBySlider(square, attacker, Self.bishopDirections, .bishop)
    }

    private func attackedByPawn(_ square: Square, _ attacker: Color) -> Bool {
        [-1, 1].contains { fileStep in
            guard let from = square.offset(file: fileStep, rank: -attacker.forward) else {
                return false
            }
            return board[from] == Piece(attacker, .pawn)
        }
    }

    private func attackedByStep(_ square: Square, _ attacker: Color, _ steps: [(Int, Int)], _ kind: PieceKind) -> Bool {
        steps.contains { step in
            guard let from = square.offset(file: step.0, rank: step.1) else {
                return false
            }
            return board[from] == Piece(attacker, kind)
        }
    }

    /// 直線の利き。`kind` はその向きに走る駒（ルークかビショップ）で、クイーンも同じ向きに走る。
    private func attackedBySlider(_ square: Square, _ attacker: Color, _ directions: [(Int, Int)], _ kind: PieceKind)
        -> Bool
    {
        directions.contains { direction in
            var current = square.offset(file: direction.0, rank: direction.1)
            while let target = current {
                if let piece = board[target] {
                    return piece.color == attacker && (piece.kind == kind || piece.kind == .queen)
                }
                current = target.offset(file: direction.0, rank: direction.1)
            }
            return false
        }
    }
}
