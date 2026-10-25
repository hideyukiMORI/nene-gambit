# いまのタスク — NeNe Gambit

> GitHub Issue が正。ここは要約であり、Markdown のチェックリストをタスク状態として扱わない。
> 更新は実測でだけ行う（「動くもの」は `make check` が通ったもの）。

## 段階

| 段階 | 状態 |
| --- | --- |
| Phase 0 言語の実測 | ✅ 2026-10-25（56 ケース・ADR 0001） |
| Phase 1 文書とゲートの足場 | ✅ 2026-10-25（Issue #1・PR #2） |
| Phase 2 negative proof | ✅ 2026-10-25（45 件・active 45 行・docs/quality/gate-proofs.md） |
| Phase 3-1 盤面と合法手生成・perft | ✅ 2026-10-25（Issue #3・PR #4） |
| Phase 3-2 ランダムに指す 2 者の自動対局を画面に出す | 🔧 Issue #5 |
| Phase 3-3 施主が Windows Terminal で見る | 🔲 |
| Phase 3-4 評価関数＋探索・序盤のばらつき・性格 | 🔲 施主の未決 Q7 の答え待ち |
| Phase 4 公開 | 🔲 別 Issue |

## 動くもの

- `make check`（道具の版・`swift build`・整形・lint・規約検査とその単体テスト・perft ほかのテスト・コミットの形）
- `NeNeGambitCore`: 盤・指し手・合法手生成・適用・FEN の読み書き・終局の 5 つの理由。perft は 6 局面×深さ 5 で公表値と一致
- `nene-gambit`: ランダムに指す 2 者の対局を端末に描き続ける（`--seed` / `--glyphs` / `--move-interval` / `--result-pause`・`q` で終了・`g` で駒の字形）。
  `make smoke` が疑似端末で `q`・Ctrl+C・SIGTERM・SIGSEGV・大きさの変化のそれぞれで端末が戻ることを見る

## 動かないもの

- 評価関数・探索・性格（手順 4・Q7）
- Windows Terminal での見え方の確認（手順 3。施主が見る）
- カバレッジの層（QLT-009。下限をまだ決めていない）

## 次の 1 手

Issue #5 を閉じたら、施主に Windows Terminal で `nene-gambit` を見てもらう（手順 3）。見る点: 盤の色・駒記号の幅のずれ・速さ・HUD を英語にしたこと。
評価と探索（手順 4）の前に、施主に Q7（白黒の性格の中身）を聞く。
