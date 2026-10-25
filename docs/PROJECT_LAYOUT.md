# モジュール構成と依存規則 — NeNe Gambit

> Status: normative（規範）/ 2026-10-25 初版
> パッケージ: SwiftPM `NeNeGambit`（`Package.swift`）

モジュールグラフはアーキテクチャの一部である。**ディレクトリの命名規約だけでは依存の境界にならない。**
承認された一覧の機械可読な正本は `docs/architecture/module-graph.txt` で、規約検査が `Package.swift` の宣言と突き合わせる（ARC-002・CNF-010）。

---

## 1. 承認されたモジュール

空の「将来用 target」を作らない。下の一覧の target は Issue #3（Core）と Issue #5（残り）ですべて `Package.swift` に入った。

```text
nene-gambit (executable)
    合成ルート。時計・乱数（シード）・環境・起動オプションを読み、Core・Engine・Render・Terminal を組み立てて
    対局の列を回す。標準入出力への直書きと終了コードを持つ唯一の場所（ARC-006 / ARC-007）

NeNeGambitTerminal
    セル格子 → ANSI の差分出力・termios・SIGWINCH・キー入力の解析。unsafe 系 API を許す唯一の区画（SWF-009）

NeNeGambitRender
    局面＋HUD の値 → 文字セルの格子（配色・駒の字形・棋譜の表示）。端末を知らない。出力は値

NeNeGambitEngine
    評価関数・アルファベータ探索・序盤のばらつき・白黒の性格。乱数は引数で受け取る。時計を知らない

NeNeGambitCore
    盤面・駒・指し手・合法手生成・指し手の適用・終局判定・FEN の読み書き。
    時刻・乱数源・端末・Foundation・ファイルを知らない。値型＋純粋関数
```

テスト target は `<target>Tests`（`NeNeGambitCoreTests` 等）で、Swift Testing だけを import できる（SWF-016）。
`NeNeGambitTerminalTests` だけは、差分のテストに要る格子を作るために Engine にも依存する（ADR 0006）。

---

## 2. 許可された依存グラフ

```text
NeNeGambitCore      -> （無し）
NeNeGambitEngine    -> NeNeGambitCore
NeNeGambitRender    -> NeNeGambitCore, NeNeGambitEngine
NeNeGambitTerminal  -> NeNeGambitRender                         ＋ 標準モジュール Glibc, Synchronization（ADR 0006）
nene-gambit         -> 上の 4 つすべて（明示的な合成のためだけに） ＋ 標準モジュール Glibc
```

ここに無い依存はすべて禁止である。とくに:

- Core / Engine / Render -> Foundation・Glibc・Dispatch: **禁止**（標準モジュールはビルドグラフでは塞げないので CNF-011 が塞ぐ）
- Core -> Engine、Engine -> Render 等の逆向き: 禁止（SwiftPM が `no such module` で拒み、CNF-010 が宣言を拒む）
- Terminal -> Core / Engine: 禁止（Terminal はセル格子しか知らない）
- 何か -> 合成ルート: 禁止
- Foundation: どの target からも禁止（SWF-014）

---

## 3. 各モジュールの責務

### `NeNeGambitCore`

意味の正本を持つ。駒・色・升・指し手・局面・終局の理由（閉じた enum）・FEN の拒否理由。
「終局したか」を判定する経路は Core の 1 つだけ。指し手の内部表記は 1 つ（どれにするかは Phase 3 の ADR で決める）。

### `NeNeGambitEngine`

評価関数（駒の価値と駒ごとの位置の表は 1 か所のデータ）・アルファベータ探索（深さかノード数で打ち切る）・序盤のばらつき・性格。
乱数は `inout` で受け取った乱数源からだけ引く（CNF-012 は `using:` の無い `random(...)` を拒む）。

### `NeNeGambitRender`

局面と HUD の値から文字セルの 2 次元配列を作る。色は Render の配色表だけが持つ。指し手の表示用の表記への変換は Render だけが持つ。

### `NeNeGambitTerminal`

alternate screen・カーソル非表示・24bit カラー（無ければ 256 色）・前フレームとの差分・1 フレーム 1 回の `write`・SIGWINCH・
**異常終了でも端末を必ず復元**。キー入力を閉じた enum の意図に変える。可変性の隔離区画（ARC-005）。

### `nene-gambit`

依存を結ぶ。「何秒に 1 手指すか」はここが決める。端末出力（起動できなかった理由 1 行）と終了コードを扱ってよい唯一の場所（ARC-006）。

---

## 4. ソースの置き場

| 種類 | 置き場 |
| --- | --- |
| production | `Sources/<target>/`（`path:` で変えない・CNF-009） |
| テスト | `Tests/<target>Tests/`（規約検査の対象。決定性・網羅性の禁止も適用する） |
| 検査設定 | `.swiftlint.yml`・`.swift-format`（直下の 2 つだけ・CNF-007） |
| 規約検査とその単体テスト | `eng/conformance.py`・`eng/tests/` |
| 依存グラフの正本 | `docs/architecture/module-graph.txt` |
| 生成コード | 無い（SwiftPM のビルドプラグインを使わない・SWF-009） |
| 道具の置き場 | `.tools/`（git 管理外。`eng/install-tools.sh` が lock の SHA-256 で入れる） |
