# ADR 0002 — テスト枠組みは Swift Testing だけにする

- 状態: 受理
- 日付: 2026-10-25
- Issue: #1
- 影響する規則: SWF-016 / CNF-011 / QLT-008

## 文脈

指示書は「XCTest か Swift Testing の**どちらか一つ**を ADR で選ぶ」と求めている。
Swift 6.4.1 のツールチェーンには両方が同梱され、どちらも依存の宣言なしに import できる。
先行の NeNe Delve の実測では、両方を同じパッケージに置くと 1 回の `swift test` が両方を実行した（Delve ADR 0001）。
つまり「片方に決めた」ことはビルドが勝手には守らない。

本リポジトリでは、テスト target が 1 本も無い木の `swift test` が `error: no tests found; create a target in the 'Tests' directory` で
exit 1 になることを実測した（X-c）。Phase 1 では製品コードもテストも書かないので、`swift test` はまだゲートに結線できない。

## 決定

テストは Swift Testing（`import Testing`・`@Test`・`#expect` / `#require`）だけで書く。XCTest は使わない。

## 強制

- **planned** → CNF-011。依存グラフの正本（`docs/architecture/module-graph.txt`）でテスト target の標準モジュールの許可リストを `Testing` だけにし、
  `import XCTest` を拒否する。Phase 2 で negative proof を取ってから active にする
- `swift test` のゲートへの結線は、最初のテスト target が入る Phase 3 の PR で行う。意味の無いテストを足して先に結線しない

## 結果

- 枠組みが 1 つになり、「どちらで書くか」が書き手ごとに揺れない
- パラメータ化テスト（`@Test(arguments:)`）で perft の局面と深さの表をそのまま書ける
- 失うもの: XCTest の `measure` による性能計測。perft の速度の扱いは Phase 3 の ADR で別に決める

## 却下した選択肢

| 選択肢 | 却下の理由 |
| --- | --- |
| XCTest だけ | Swift 6 の並行性と相性の良い新しい枠組みがあるのに古い方を選ぶ理由が無い。先行の Delve・Sand とも揃わない |
| 両方を許す | 「一つの意味に一つの正典経路」（ARC-001）に反する。同じ `swift test` で両方が走るので、混ざっても気づかない |
| 空のテスト target を置いて Phase 1 から `swift test` を結線する | 意味の無いテストで緑を作ることになる。緑が何も証明しない |
