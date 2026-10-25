#!/usr/bin/env python3
"""実行ファイルを疑似端末（pty）の中で動かし、描画・キー・終わり方ごとの端末の復元を確かめる（FR-07・FR-08）。

    python3 eng/smoke-terminal.py <nene-gambit の実行ファイル>

見ること:
- alternate screen に入り、24 ビットの色で盤と HUD（`Game 1`）を描く
- `g` で駒記号に替わる
- `q`・Ctrl+C・SIGTERM のどれで終わっても exit 0 で、出力の最後が端末を戻す列で、termios の lflag が起動前と同じ
- SIGSEGV（異常終了）でも端末を戻してから、そのシグナルで死ぬ
- 端末を小さくすると落ちずに 1 行の文言を出し、戻すと盤を描き直す
- 間違った起動オプションは exit 2、端末の外から起動すると exit 1（どちらも理由を 1 行）

標準ライブラリだけで書く。Windows Terminal での見え方の代わりにはならない（QLT-013）。
"""

from __future__ import annotations

import fcntl
import os
import pty
import select
import signal
import struct
import subprocess
import sys
import termios
import time

ENTER, LEAVE, SHOW, KING = "\x1b[?1049h", "\x1b[?1049l", "\x1b[?25h", "♚"


def run(binary: str, keys: list[bytes], send: int | None = None, shrink: bool = False) -> tuple[str, int, bool]:
    master, slave = pty.openpty()
    fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack("HHHH", 30, 100, 0, 0))
    before = termios.tcgetattr(slave)
    pid = os.fork()
    if pid == 0:
        os.setsid()
        fcntl.ioctl(slave, termios.TIOCSCTTY, 0)
        for fd in (0, 1, 2):
            os.dup2(slave, fd)
        os.execve(binary, [binary, "--seed", "1", "--move-interval", "0.05"], dict(os.environ, COLORTERM="truecolor"))
    chunks: list[bytes] = []

    def pump(seconds: float) -> None:
        end = time.time() + seconds
        while time.time() < end:
            ready, _, _ = select.select([master], [], [], 0.05)
            if ready:
                try:
                    chunks.append(os.read(master, 65536))
                except OSError:
                    return

    pump(1.5)
    if shrink:
        # 大きさを変えると、端末は前面のプロセスに SIGWINCH を送る
        fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack("HHHH", 10, 40, 0, 0))
        pump(0.5)
        fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack("HHHH", 30, 100, 0, 0))
        pump(0.5)
    for key in keys:
        os.write(master, key)
        pump(0.5)
    if send is not None:
        os.kill(pid, send)
        pump(0.5)
    _, status = os.waitpid(pid, 0)
    pump(0.2)
    restored = termios.tcgetattr(slave)[3] == before[3]
    os.close(master)
    os.close(slave)
    return b"".join(chunks).decode("utf-8", "replace"), status, restored


def check(name: str, ok: bool, failures: list[str]) -> None:
    print(f"smoke: {'ok ' if ok else 'NG '} {name}")
    if not ok:
        failures.append(name)


def main() -> int:
    binary = sys.argv[1]
    failures: list[str] = []
    for label, keys, send, expect in (
        ("q", [b"g", b"q"], None, ("exit", 0)),
        ("Ctrl+C", [b"\x03"], None, ("exit", 0)),
        ("SIGTERM", [], signal.SIGTERM, ("exit", 0)),
        ("SIGSEGV", [], signal.SIGSEGV, ("signal", signal.SIGSEGV)),
        ("resize", [b"q"], None, ("exit", 0)),
    ):
        text, status, restored = run(binary, keys, send, shrink=label == "resize")
        actual = ("exit", os.WEXITSTATUS(status)) if os.WIFEXITED(status) else ("signal", os.WTERMSIG(status))
        check(f"{label}: 終わり方 {actual}", actual == expect, failures)
        check(f"{label}: alternate screen に入って盤と HUD を 24 ビットの色で描く",
              ENTER in text and "Game 1" in text and "38;2;" in text, failures)
        check(f"{label}: 最後に端末を戻す（カーソルを出し alternate screen を抜ける）",
              SHOW in text and text.rstrip().endswith(LEAVE), failures)
        check(f"{label}: termios の lflag が起動前と同じ", restored, failures)
        if label == "q":
            check("g: 駒記号に替わる", KING in text, failures)
        if label == "resize":
            check("resize: 小さくすると 1 行の文言を出し、戻すと盤を描き直す",
                  "Terminal too small" in text and text.rfind("Game 1") > text.find("Terminal too small"), failures)
    bad = subprocess.run([binary, "--speed", "3"], capture_output=True, text=True, stdin=subprocess.DEVNULL)
    check("間違った起動オプションは exit 2 で理由を 1 行", bad.returncode == 2 and bad.stderr.count("\n") == 1, failures)
    off = subprocess.run([binary], capture_output=True, text=True, stdin=subprocess.DEVNULL)
    check("端末の外からは exit 1 で理由を 1 行", off.returncode == 1 and off.stderr.count("\n") == 1, failures)
    print(f"smoke: 失敗 {len(failures)} 件")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
