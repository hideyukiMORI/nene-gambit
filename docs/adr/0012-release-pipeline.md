# ADR 0012 — 版の入力は Version.swift の 1 か所、配布物は静的リンクの 1 経路で作り、検査してから梱包する

- 状態: 受理
- 日付: 2026-10-25
- Issue: #17
- 影響する規則: ARC-006 / QLT-011 / QLT-014

## 文脈

指示書 Phase 4: 版の入力 1 か所・公開スクリプト 1 本・成果物検査・SHA256SUMS。Linux x86_64 の実行ファイルを GitHub Release に置く。
SwiftPM の manifest には製品の版の欄が無い。既定の `swift build -c release` は Swift のランタイム（libswiftCore.so 等 6 つ）に動的に依存し、
Swift の入っていない WSL では起動しない（実測: `readelf -d` の NEEDED）。

## 決定

1. 版の入力は `Sources/nene-gambit/Version.swift` の `Version.current` の 1 か所。`nene-gambit --version` はそこから `nene-gambit <版>` の 1 行を出す
   （ARC-006 の「合成ルートが出してよい 1 行」に `--version` を足す）。公開スクリプトはこの値をソースから読み、タグ・`--version` の出力と突き合わせる
2. 配布物は `eng/package-release.sh [v<版>]`（`make release TAG=v<版>`）だけが作る。単一ゲートとは別のビルドディレクトリ（`.release/build`）で
   規約検査・release 構成のテスト・`--static-swift-stdlib` のビルドを通し、`strip` してから検査する:
   x86-64 の ELF・動的依存が `ld-linux-x86-64.so.2` `libc.so.6` `libgcc_s.so.1` `libm.so.6` `libstdc++.so.6` の中だけ・
   `--version` が版と一致・タグが版と一致・同梱物が `nene-gambit` `README.txt` `LICENSE` の 3 つと完全一致
3. 梱包は再現できる形（tar の並び・時刻・持ち主を固定、gzip の時刻を入れない）。`SHA256SUMS` をスクリプトが書く
4. 利用者向けの `README.txt`（ダウンロード → 照合 → 展開 → 起動）は `eng/release/README.txt` に置き、版を埋めて同梱する
5. 公開は squash 統合後の clean な `main` から同じスクリプトで作り直し、短い起動を確かめてから `v<版>` のタグと同名の Release に配布物と
   `SHA256SUMS` を添付し、再ダウンロードして照合する。**公開は施主の確認を取ってから行う**

## 強制

- **active**（QLT-014）: 証明 P51（タグの不一致）・P52（静的リンクを外すと Swift のランタイムへの動的依存で落ちる）・P53（余計な同梱物）・
  P54（`--version` の不一致）

## 結果

実測（2026-10-25・WSL2 Ubuntu 22.04・Swift 6.4.1）:

- 公開スクリプトは約 2 分（テストとビルド）。tar.gz の SHA-256 は 2 回作って同じ（`677656a8…`）
- 実行ファイルは `strip` 後 7.4 MB。要求する glibc は 2.35（`GLIBC_2.35`）・libstdc++ は `GLIBCXX_3.4.29`。つまり Ubuntu 22.04 以降
- 失うもの: 公開スクリプトの中でテストをもう一度回すので、公開に 2 分かかる。これはフルゲートの代わりではない

## 却下した選択肢

| 選択肢 | 却下の理由 |
| --- | --- |
| 版を `VERSION` ファイルに置き、ビルド時に読む | SwiftPM でビルド時にファイルを読むにはビルドプラグインが要る（SWF-009 で禁止） |
| 版を git のタグから取る | タグの無い木で `--version` が決まらない。ソースが版を知らないことになる |
| Swift のランタイムを同梱して動的リンクのまま配る | 同梱物と `LD_LIBRARY_PATH` の扱いが増える。静的リンクなら 1 ファイルで動く |
| 完全な静的リンク（`--static-executable` 相当） | glibc の静的リンクは名前解決などで警告が出る経路があり、得るものが少ない。Ubuntu 22.04 以降の glibc に依存する方が素直 |
