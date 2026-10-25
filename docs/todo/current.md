# いまのタスク — NeNe Gambit

> GitHub Issue が正。ここは要約であり、Markdown のチェックリストをタスク状態として扱わない。
> 更新は実測でだけ行う（「動くもの」は `make check` が通ったもの）。

## 段階

| 段階 | 状態 |
| --- | --- |
| Phase 0 言語の実測 | ✅ 2026-10-25（56 ケース・ADR 0001） |
| Phase 1 文書とゲートの足場 | 🔧 Issue #1 |
| Phase 2 negative proof | 🔲 Issue #1 |
| Phase 3 縦切り（指し手生成と perft から） | 🔲 別 Issue |
| Phase 4 公開 | 🔲 別 Issue |

## 動くもの

- `make check`（道具の版・`swift build`・整形・lint・規約検査とその単体テスト・コミットの形）。target は 0 本で、製品コードは無い

## 動かないもの

- 製品そのもの（盤面・指し手生成・探索・描画・端末は Phase 3）
- `swift test`（テスト target が無いので結線していない・ADR 0002）

## 次の 1 手

Issue #1 を閉じたあと、Phase 3 の手順 1「盤面と合法手生成（Core だけ・画面なし）」の Issue を立てる。
画面に出す手順 2 の前に、施主に未決の Q4（駒記号の切り替え方）・Q5（HUD）・Q6（速さ・終局表示の時間）・Q8（配色・テーマ）を聞く。
