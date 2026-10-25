# ADR 0004 — perft は深さ 5 まで全部を release 構成のテストでゲートに回す

- 状態: 受理
- 日付: 2026-10-25
- Issue: #3
- 影響する規則: QLT-001 / QLT-002 / QLT-008 / SWF-008 / SWF-016

## 文脈

指示書: 「perft 深さ 5 は 4,865,609 局面。デバッグビルドで遅すぎるなら、ゲートでの扱い（release 構成で回す・深さの割り振り）を ADR で決める。
**深さを黙って下げない**」。ADR 0002 は、最初のテスト target が入る PR で `swift test` をゲートに結線すると決めていた。

実測（WSL2 Ubuntu・Swift 6.4.1・2026-10-25）。テストは Chess Programming Wiki「Perft Results」の 6 局面（初期局面・Position 2〜6）を
それぞれ深さ 1〜5 まで数え、公表値と比べる:

| 構成 | 回したもの | テストの所要（壁時計） | `swift test` 全体 |
| --- | --- | --- | --- |
| デバッグ（`swift test`） | 初期局面は深さ 5、ほかは深さ 4（最初の試し） | 65.8 秒 | 1 分 11 秒（CPU 5 分 10 秒） |
| release（`swift test -c release`） | 同上 | 1.4 秒 | 8.0 秒 |
| release（`swift test -c release`） | **6 局面すべて深さ 5**（Kiwipete は 193,690,690 局面） | 34.3 秒 | 36.5 秒 |

すべての局面・すべての深さで公表値と一致した。

## 決定

1. `make check` の `test` 段は `swift test -c release` を回す。**6 局面すべてを深さ 5 まで**数える（深さを下げない）
2. テストは公開 API だけを使う（`@testable import` を使わない）。release 構成では `@testable` が使えないので、これが前提になる。
   テストのために API を公開しない（SWF-008）ことと両立する
3. デバッグ構成のビルドは `make check` の `build` 段（`swift build`）が見る。警告のエラー化は両方の構成で manifest が効く
4. ゲートの段は安い順に並べ、`test` は規約検査の後ろに置く（違反がある木で 34 秒待たない）
5. `swift build` と `swift test` は `eng/swift-strict.sh` から呼び、SwiftPM 自身が出す警告も失敗にする（下の「結果」の穴）

## 強制

- **active**（QLT-001 の一部）: 証明 P48（perft の期待値を 1 つ変えると `make check` の `test` 段が `✘ Test matchesPublishedCounts` で落ちる）
- **active**（QLT-002 の一部）: 証明 P47（SwiftPM の警告で `make check` の `build` 段が落ちる）

## 結果

- 指し手生成の正しさを公表値の 480,105,445 局面ぶん（6 局面 × 深さ 1〜5 の合計）で確かめてから探索に進める
- `make check` は 1 回に約 45 秒かかるようになった（そのうち perft が約 34 秒）。CI のランナーはこれより遅い可能性がある
- 🔴 見つけた穴: `treatAllWarnings(as: .error)` はコンパイラの警告だけをエラーにする。SwiftPM が manifest を解釈して出す警告
  （`warning: 'nene-gambit': Source files for target NeNeGambitCoreTests should be located under 'Tests/NeNeGambitCoreTests'`）は exit 0 で通った。
  `eng/swift-strict.sh` が出力の `warning:` を見て落とす
- 失うもの: デバッグ構成でしか出ない不具合（`assert` の発火）をテストで見ない。製品コードは `assert` を使わず、欠陥は `precondition` で止める
  （`precondition` は release でも効く）

## 却下した選択肢

| 選択肢 | 却下の理由 |
| --- | --- |
| デバッグ構成で深さ 5 を回す | 初期局面の深さ 5 だけで約 1 分。6 局面の深さ 5 では数分かかり、毎回のゲートに向かない |
| デバッグ構成のまま深さを 4 に下げる | 指示書が禁じる「深さを黙って下げる」そのもの。公表値の大半（480,105,445 局面のうち深さ 5 の 469,080,960）を見なくなる |
| 深さ 5 は別の重いゲート（CI だけ・夜間）に回す | ゲートは一つ（QLT-001）・CI にしか無い検査を作らない（QLT-005） |
| `-Ounchecked` で回す | 整数の桁あふれと配列の範囲外の検査が消え、perft が正しく数えていても製品と違う構成を試すことになる |
