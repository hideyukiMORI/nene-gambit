# 用語集 — NeNe Gambit

> Status: normative（規範）/ 2026-10-25 初版
> ここに載っている語は、コード・ドキュメント・Issue で**同じ意味**で使う。同義語を発明しない。

| 語 | 意味 | 型／場所 |
| --- | --- | --- |
| 結果（outcome） | 期待される成功・失敗を表す閉じた型 | `*Outcome` |
| 拒否理由（rejection / failure） | 結果に添える閉じた理由の集合 | `*Rejection` / `*Failure` |
| 合成ルート | 依存を結ぶ唯一の場所。時計・乱数・環境を読み、標準入出力と終了コードを持つ | `nene-gambit`（executable target） |
| 描画（render） | 局面と HUD の値から文字セルの格子という値を作ること。端末への書き出しは含まない | `NeNeGambitRender` |
| 隔離区画 | 可変性を許した唯一の場所 | ARC-005 の表 |
| 規約検査（conformance） | NeNe Gambit 固有の自作ゲート | `eng/conformance.py`（CNF-NNN） |
| waiver | 1 つの規則に対する期限付きの狭い例外 | `docs/waivers/WVR-NNNN-*.md` |
| 機械強制の状態 | active / planned / 不能 / 不採用 | `docs/QUALITY_GATES.md` の強制マトリクス |
| negative proof | ゲートが意図した規則で落ちることの実測 | `docs/quality/gate-proofs.md` |
| 局面（position） | 盤上の駒・手番・キャスリング権・アンパッサンの升・手数を合わせた値 | `NeNeGambitCore` |
| 指し手（move） | 局面を次の局面へ進める 1 手。内部表記は 1 つ（Phase 3 の ADR で決める） | `NeNeGambitCore` |
| 合法手（legal move） | ルール上指せる指し手。自分の王を王手に晒す手は含まない | `NeNeGambitCore` |
| perft | 局面から深さ N までの合法手の列の数。指し手生成の正しさを公表値と突き合わせる | Core のテスト |
| FEN | 局面を 1 行の文字列で表す標準の記法。読み書きは Core の 1 経路だけ | `NeNeGambitCore` |
| 局（game） | 初期局面から終局までの 1 回の対局 | 合成ルート |
| 終局の理由 | チェックメイト・ステイルメイト・同一局面 3 回・50 手ルール・駒不足の閉じた集合 | Core の enum |
| 性格（personality） | 白黒それぞれの AI の強さと評価の重みの組（FR-06。中身は施主の未決 Q7） | `NeNeGambitEngine` |
| シード（seed） | 自前の PRNG の初期値。同じシードからは同じ対局の列が出る | 合成ルートが読み、Engine に渡す |
| セル格子 | 端末の 1 画面分の文字セルの 2 次元配列。Render が作り、Terminal が差分で書く | `NeNeGambitRender` |

## 使ってはいけない語

`Manager` / `Helper` / `Util` / `Utils` / `Common` を型名の語尾に使わない（SWF-010）。
役割を語る名前が思いつかないときは、その型が 2 つの責務を持っている可能性が高い。
