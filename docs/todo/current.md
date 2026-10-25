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
| Phase 3-2 ランダムに指す 2 者の自動対局を画面に出す | ✅ 2026-10-25（Issue #5・PR #6） |
| Phase 3-2b サイバー HUD・12 テーマ・キャラクターの発言 | ✅ 2026-10-25（Issue #7・PR #8） |
| 手順 3 の指摘への対応（24 ビット色・駒記号の幅・1.0 秒） | ✅ 2026-10-25（Issue #9・PR #10） |
| Phase 3-3 施主が Windows Terminal で見る | ✅ 2026-10-25（罫線は出た・駒記号の右寄り・速さ → Issue #9） |
| Phase 3-4 評価関数＋探索・序盤のばらつき・性格ごとの指し方 | ✅ 2026-10-25（Issue #11・PR #12。16 局中 15 局がチェックメイト） |
| 駒記号の位置と背景 | ✅ 2026-10-25（Issue #13・#15） |
| Phase 4 公開 | ✅ 2026-10-25 v0.1.0（Issue #17・PR #18） |
| README（英語が正・日本語版・実機の画面写真・install.sh） | ✅ 2026-10-25（Issue #21・#23） |

## 動くもの

- `make check`（道具の版・`swift build`・整形・lint・規約検査とその単体テスト・perft ほかのテスト・コミットの形）
- `NeNeGambitCore`: 盤・指し手・合法手生成・適用・FEN の読み書き・終局の 5 つの理由。perft は 6 局面×深さ 5 で公表値と一致
- `nene-gambit`: キャスト 4 名が評価と探索で指しながら話す対局を、サイバー HUD で描き続ける（`--seed` / `--glyphs` / `--theme` / `--move-interval` / `--result-pause`・`q` で終了・`g` で駒の字形・`t` でテーマ）。
  `make smoke` が疑似端末で `q`・Ctrl+C・SIGTERM・SIGSEGV・大きさの変化のそれぞれで端末が戻ることを見る

## 動かないもの

- Windows Terminal での見え方の確認（手順 3。施主が見る）
- カバレッジの層（QLT-009。下限をまだ決めていない）

## 公開の記録

| 版 | タグの対象 | 配布物の SHA-256 | 確認 |
| --- | --- | --- | --- |
| v0.1.0（2026-10-25） | bbfb0780b702ae875a54751c3541b35bb61c6c9b（PR #18） | `fd225428b03d054adb13df6c0006c0aee383d306b068e0670ad34b74cd84f9a5` | clean な main から `make release`・展開して `--version` と smoke・Release から落とし直して照合と一致 |

## 次の 1 手

- 駒記号のポーン ♟ が Windows Terminal で絵文字の色になり、白と黒の区別が付かない（Issue #24）
- 施主がしばらく放置して見た結果（キャストの強さの差・決着の付き方）を待つ
