# ADR 0006 — 並行は 1 本のループだけ、シグナルは原子的な旗、異常終了はハンドラが端末を戻す

- 状態: 受理
- 日付: 2026-10-25
- Issue: #5
- 影響する規則: SWF-013 / ARC-002 / ARC-004 / ARC-005 / ARC-006 / ARC-007 / SWF-008 / FR-08

## 文脈

SWF-013 は「合成ルートと Terminal の並行の形を Phase 3 の縦切りで 1 つに決め、ADR に書く」とした。
指示書: 「異常終了でも端末を必ず復元」「`SIGWINCH` でリサイズ追従」「探索は時間ではなく深さで打ち切る。Core と Engine は時計を知らない。
『何秒に 1 手指すか』は合成ルートが決める」。Swift 6 の言語モードでは、可変なグローバル変数はデータ競合の検査で拒まれる。

## 決定

1. **並行の形は 1 つ: 合成ルートの 1 本のループ**（`Screensaver.run`）。`Task` / `async` / スレッドを作らない。
   ループは `Console.waitForInput(milliseconds:)`（`poll(2)`）で「次の 1 歩の締め切り」まで入力を待ち、起きたら意図・シグナル・時計の順に見る
2. 終了と大きさの変化のシグナル（SIGINT・SIGTERM・SIGHUP・SIGWINCH）のハンドラは、`Synchronization.Atomic<UInt32>` の旗を立てるだけ。
   ループが `Console.takeSignals()` で旗を取り出す。そのために、依存グラフの正本で `NeNeGambitTerminal` の標準モジュールに `Synchronization` を足す
3. 異常終了のシグナル（SIGSEGV・SIGBUS・SIGILL・SIGFPE・SIGABRT・SIGTRAP。Swift の `precondition` の失敗もここに来る）のハンドラは、
   その場で端末を戻し（メモリを確保しない `write(2)` と `tcsetattr(3)` だけ）、既定の動作に戻して同じシグナルを送り直す
4. 端末の退避値（termios）は `ConsoleState` の 1 か所だけに置く。異常終了のハンドラからも読むので `nonisolated(unsafe)` のグローバル変数にする。
   これは `unsafe=allowed` の Terminal の中だけで許される（CNF-014）
5. Ctrl+C は termios の `ISIG` を残して SIGINT として受ける（生の入力にしても `q` と同じ経路で終わる）
6. 端末の外へのテキストの出力は `Console` だけが持つ。起動できなかった理由 1 行を何と書くかは合成ルートが決め、`Console.reportFailure` で出す
   （Swift 6 では C の `stderr` が並行性の検査で拒まれる。`nonisolated(unsafe)` を合成ルートに置くと CNF-014 に触れる）
7. 対局の列（`GameSeries`）は Engine の値型で、合成ルートの `Screensaver` が 1 つだけ持つ（ARC-004 の表を書き換える）。
   シードは合成ルートが起動オプションかシステムの乱数から決め、`SplitMix64` に渡す
8. 端末の確かめは 2 段: 端末を使わない単体テスト（差分のバイト列・キーの読み取り）と、実行ファイルを疑似端末で動かす `make smoke`
   （`eng/smoke-terminal.py`: `q`・Ctrl+C・SIGTERM・SIGSEGV・大きさの変化のそれぞれで端末が戻ること）
9. `NeNeGambitTerminalTests` の依存に `NeNeGambitEngine` を足す。差分のテストに要る格子は Render の `TableRenderer.render(GameSeries, …)` からしか作れず、
   テストのために `Grid` の生成を公開しない（SWF-008）
10. `MoveNotation.san` は Render の公開 API にする。表示用の表記は Render が出す値そのものだから（テストのためだけではない）

## 強制

- **active**（FR-08 の部分）: `make smoke` が終わり方ごとの端末の復元を見る。証明は P49（端末を戻す列を壊すと smoke が落ちる）
- **planned**（SWF-013）: `Task` / `async` / `Thread` を書かないことを見る字句検査はまだ無い。Dispatch は CNF-011 が import で拒む

## 結果

- 時計を読むのは合成ルートのループだけで、Core・Engine・Render・Terminal はどれも時計を知らない（ARC-007）
- 🔴 `kill -9`（SIGKILL）は捕まえられないので、端末は戻らない。これは塞げない
- 🔴 異常終了のハンドラの中で Swift の配列の `withUnsafeBufferPointer` を使っている。確保はしないが、Swift の実行時が非同期シグナル安全だという保証は無い
- `make check` が実行ファイルを release 構成で作り、疑似端末で 5 通り動かす（約 10 秒増える）

## 却下した選択肢

| 選択肢 | 却下の理由 |
| --- | --- |
| `Task` と `AsyncStream` でキー入力と時計を別々に待つ | 並行の形が 2 つになり、Swift 6 の隔離の注釈が増える。1 本の `poll` で足りる |
| シグナルを `signalfd` / self-pipe で受ける | 旗 1 つで足りる。ファイル記述子が増え、`poll` の相手が 2 つになる |
| シグナルのハンドラから直接描き直す | ハンドラの中でメモリを確保することになる（非同期シグナル安全でない） |
| `atexit` で端末を戻す | 異常終了のシグナルでは呼ばれない |
| 合成ルートに `nonisolated(unsafe) let errorStream = stderr` を置く | `unsafe` を Terminal の外へ広げることになる（CNF-014） |
| `Grid` の生成を公開して Terminal のテストで直接作る | テストのためだけの公開（SWF-008） |
