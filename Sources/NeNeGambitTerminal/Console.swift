import Glibc
import NeNeGambitRender
import Synchronization

/// 端末そのもの（termios・alternate screen・シグナル・キー入力・大きさ）。可変性の隔離区画（ARC-005）で、
/// `unsafe` 系 API を使ってよい唯一の target の中にある（SWF-009）。
///
/// 並行の形は 1 つ（ADR 0006）: 合成ルートの 1 本のループが `waitForInput` で待ち、シグナルハンドラは原子的な旗を立てるだけ。
/// 例外は「異常終了のシグナル」で、ハンドラがその場で端末を戻してから既定の動作で死ぬ（FR-08）。
public enum Console {
    /// 端末を対局の画面にする（生の入力・エコーなし・alternate screen・カーソル非表示）。
    public static func open() -> ConsoleOpening {
        guard isatty(STDIN_FILENO) == 1, isatty(STDOUT_FILENO) == 1 else {
            return .notATerminal
        }
        var attributes = termios()
        guard tcgetattr(STDIN_FILENO, &attributes) == 0 else {
            return .failed
        }
        consoleState.saved = attributes
        attributes.c_lflag &= ~tcflag_t(ICANON | ECHO)
        guard tcsetattr(STDIN_FILENO, TCSANOW, &attributes) == 0 else {
            return .failed
        }
        consoleState.active = true
        installHandlers()
        write(Array("\u{1B}[?1049h\u{1B}[?25l\u{1B}[2J".utf8))
        return .opened
    }

    /// 端末を元に戻す。何度呼んでもよい。
    public static func close() {
        guard consoleState.active else {
            return
        }
        restoreTerminal()
    }

    /// いまの大きさ。読めなければ 0×0。
    public static func size() -> ScreenSize {
        var size = winsize()
        let status = withUnsafeMutablePointer(to: &size) { pointer in
            ioctl(STDOUT_FILENO, UInt(TIOCGWINSZ), pointer)
        }
        return status == 0
            ? ScreenSize(columns: Int(size.ws_col), rows: Int(size.ws_row)) : ScreenSize(columns: 0, rows: 0)
    }

    /// バイト列を標準出力へ 1 回で書く（書き切るまで続ける）。
    public static func write(_ bytes: [UInt8]) {
        bytes.withUnsafeBufferPointer { buffer in
            var offset = 0
            while offset < buffer.count, let base = buffer.baseAddress {
                let written = Glibc.write(STDOUT_FILENO, base + offset, buffer.count - offset)
                if written <= 0 {
                    return
                }
                offset += written
            }
        }
    }

    /// 標準エラーへ 1 行書く。起動できなかった理由を合成ルートが出すためだけに使う（ARC-006）。
    public static func reportFailure(_ line: String) {
        let bytes = Array((line + "\n").utf8)
        bytes.withUnsafeBufferPointer { buffer in
            _ = Glibc.write(STDERR_FILENO, buffer.baseAddress, buffer.count)
        }
    }

    /// キー入力を最大 `milliseconds` だけ待ち、届いたバイトを返す。シグナルで起きたら空で返る。
    public static func waitForInput(milliseconds: Int32) -> [UInt8] {
        var request = pollfd(fd: STDIN_FILENO, events: Int16(POLLIN), revents: 0)
        guard poll(&request, 1, max(milliseconds, 0)) > 0 else {
            return []
        }
        var buffer = [UInt8](repeating: 0, count: 64)
        let count = buffer.withUnsafeMutableBytes { raw in read(STDIN_FILENO, raw.baseAddress, raw.count) }
        return count > 0 ? Array(buffer.prefix(count)) : []
    }

    /// 前回から届いたシグナルを取り出す（取り出すと消える）。
    public static func takeSignals() -> ConsoleSignals {
        let bits = pendingSignals.exchange(0, ordering: .acquiringAndReleasing)
        return ConsoleSignals(
            interrupted: bits & SignalBit.interrupt != 0, resized: bits & SignalBit.resize != 0)
    }

    private enum SignalBit {
        static let interrupt: UInt32 = 1
        static let resize: UInt32 = 2
    }

    private static func installHandlers() {
        for number in [SIGINT, SIGTERM, SIGHUP] {
            signal(number) { _ in pendingSignals.bitwiseOr(SignalBit.interrupt, ordering: .relaxed) }
        }
        signal(SIGWINCH) { _ in pendingSignals.bitwiseOr(SignalBit.resize, ordering: .relaxed) }
        for number in [SIGSEGV, SIGBUS, SIGILL, SIGFPE, SIGABRT, SIGTRAP] {
            signal(number) { received in
                restoreTerminal()
                signal(received, SIG_DFL)
                raise(received)
            }
        }
    }
}

/// シグナルハンドラから書いてよいのは、この旗（`Console.SignalBit` のビット）と `restoreTerminal` だけ。
private let pendingSignals = Atomic<UInt32>(0)
