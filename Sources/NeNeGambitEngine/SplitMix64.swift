/// シード付きの自前の乱数源（SplitMix64）。同じシードからは同じ列が出る（ARC-007）。
///
/// シードを決める（時計やシステムの乱数から読む）のは合成ルートだけで、Engine はこの値を `inout` で受け取って使う。
public struct SplitMix64: RandomNumberGenerator, Sendable {
    private var state: UInt64

    /// シードから作る。
    public init(seed: UInt64) {
        state = seed
    }

    /// 次の 64 ビット。
    public mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var mixed = state
        mixed = (mixed ^ (mixed >> 30)) &* 0xBF58_476D_1CE4_E5B9
        mixed = (mixed ^ (mixed >> 27)) &* 0x94D0_49BB_1331_11EB
        return mixed ^ (mixed >> 31)
    }
}
