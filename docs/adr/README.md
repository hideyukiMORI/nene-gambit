# アーキテクチャ決定記録（ADR）

トレードオフのある判断を、**理由ごと**残す場所。正本ドキュメントが「いま何が規範か」を書くのに対し、
ADR は「なぜそう決めたか」「何を却下したか」を書く。

## 書き方

- 連番 4 桁 ＋ kebab の題名: `NNNN-short-kebab-title.md`
- `0000-template.md` を複製して書く
- 状態は `提案` / `受理` / `却下` / `置換（→ NNNN）`
- **却下した選択肢を必ず書く。** 再提案は、その理由への反論から始めること
- 受理された ADR を後から書き換えない。変えるときは新しい ADR で置き換える
- 文脈は可能な限り実データ（コード・履歴・計測・コンパイラの出力）で裏を取る

## 一覧

| ADR | 題名 | 状態 |
| --- | --- | --- |
| [0001](0001-strictness-is-mechanically-enforced.md) | 厳格さは機械で強制する | 受理 |
| [0002](0002-swift-testing-only.md) | テスト枠組みは Swift Testing だけにする | 受理 |
| [0003](0003-board-and-move-representation.md) | 盤は 64 升の値型の配列、指し手は「元・先・昇格先」の 1 表記、適用は新しい局面を返す | 受理 |
| [0004](0004-perft-runs-in-release-configuration.md) | perft は深さ 5 まで全部を release 構成のテストでゲートに回す | 受理 |
| [0005](0005-screen-layout-and-glyph-width.md) | 画面は 1 文字 1 桁の格子で、盤は 1 升 3 桁、HUD の文言は ASCII の英語 | 受理 |
| [0006](0006-terminal-loop-and-signals.md) | 並行は 1 本のループだけ、シグナルは原子的な旗、異常終了はハンドラが端末を戻す | 受理 |
