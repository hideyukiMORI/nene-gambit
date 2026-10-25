import NeNeGambitCore
import NeNeGambitEngine
import Testing

/// 乱数源と対局の列（FR-05 の決定性・ARC-007）。
struct GameSeriesTests {
    /// 参照値は、SplitMix64 の同じ式を Python で別に計算した値（記憶では書いていない）。
    @Test(arguments: [
        (UInt64(0), [UInt64(16_294_208_416_658_607_535), 7_960_286_522_194_355_700, 487_617_019_471_545_679]),
        (UInt64(42), [UInt64(13_679_457_532_755_275_413), 2_949_826_092_126_892_291, 5_139_283_748_462_763_858]),
    ])
    func splitMixMatchesTheReferenceValues(seed: UInt64, expected: [UInt64]) {
        var generator = SplitMix64(seed: seed)
        #expect((0..<3).map { _ in generator.next() } == expected)
    }

    /// 同じシードからは同じ対局の列（指した手の列と通算）が出る。違うシードからは違う列が出る。
    @Test func sameSeedGivesTheSameSeries() {
        let first = Self.games(seed: 7, count: 3)
        let again = Self.games(seed: 7, count: 3)
        let other = Self.games(seed: 8, count: 3)
        #expect(first == again)
        #expect(first != other)
    }

    /// 終局した局は通算に 1 回だけ数え、次の 1 歩で初期局面の次の局を始める。
    @Test func finishedGameIsCountedOnceAndTheNextGameStarts() {
        var generator = SplitMix64(seed: 3)
        var series = GameSeries.starting(using: &generator)
        while case .ongoing = series.game.status {
            series = series.advanced(using: &generator)
        }
        #expect(series.tally.finishedGames == 1)
        #expect(series.gameNumber == 1)
        let next = series.advanced(using: &generator)
        #expect(next.gameNumber == 2)
        #expect(next.tally == series.tally)
        #expect(next.game.position == Position.initial)
    }

    /// シードから `count` 局を最後まで指し、各局の手の列を返す。
    static func games(seed: UInt64, count: Int) -> [[Move]] {
        var generator = SplitMix64(seed: seed)
        var series = GameSeries.starting(using: &generator)
        var finished: [[Move]] = []
        while finished.count < count {
            series = series.advanced(using: &generator)
            if case .finished = series.game.status {
                finished.append(series.game.moves)
                series = series.advanced(using: &generator)
            }
        }
        return finished
    }
}
