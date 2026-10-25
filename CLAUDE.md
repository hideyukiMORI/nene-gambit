# CLAUDE.md — NeNe Gambit

Claude Code / AI エージェントがこのリポジトリで作業するための**中核ハンドブック**。
簡潔な英語版の入口は [AGENTS.md](AGENTS.md)。詳細の正本は `docs/` にあり、ここには複製しない。

---

## 0. まず読むもの（production コードに触れる前に必ず）

1. [docs/ARCHITECTURE_CONSTITUTION.md](docs/ARCHITECTURE_CONSTITUTION.md) — 憲章（ARC-NNN）
2. [docs/PROJECT_LAYOUT.md](docs/PROJECT_LAYOUT.md) — モジュールと依存方向
3. [docs/CODING_RULES.md](docs/CODING_RULES.md) — Swift 6 規約（SWF-NNN）
4. [docs/QUALITY_GATES.md](docs/QUALITY_GATES.md) — **いま何が機械で守られているか**（QLT-NNN / CNF-NNN）
5. [docs/DEVELOPMENT_WORKFLOW.md](docs/DEVELOPMENT_WORKFLOW.md) — 手順
6. [docs/COMMIT_CONVENTIONS.md](docs/COMMIT_CONVENTIONS.md) — Issue・ブランチ・コミット・PR（GIT-NNN）
7. [docs/GLOSSARY.md](docs/GLOSSARY.md) — 用語
8. 該当する ADR（`docs/adr/`）と有効な waiver（`docs/waivers/`）

---

## 1. このリポジトリの統治原則

> **一つのことを実現する方法を 1 つに固定し、そのことを人の記憶ではなく機械に守らせる。**

その帰結として、次の 3 つを常に守る。

1. **正典の経路を先に特定してから編集する。** 「ここで書いたほうが早いから」で第 2 の経路を作らない（ARC-001 / ARC-012）
2. **ゲートを弱めて通さない。** 検査が落ちたらコードを直す。閾値・除外・重大度を触るのは ADR 相当の判断（QLT-010）
3. **`planned` を `active` と書かない。** 未実装の強制を実装済みに見せるのは、この規約体系で唯一「壊す」行為（[ADR 0001](docs/adr/0001-strictness-is-mechanically-enforced.md)）

---

## 2. このプロジェクトで間違えやすい所

### 現在時刻・乱数・環境を読む場所は 1 つしかない

時計・乱数・環境変数・起動オプション（`CommandLine`）を読んでよいのは **合成ルート `nene-gambit`** だけである（ARC-007）。
Swift ではどれも標準ライブラリだけで書けてしまう（`Int.random`・`ContinuousClock.now`・`CommandLine.arguments`）ので、規約検査（CNF-012）が字句で落とす。
乱数が要る関数は乱数源を `inout` で受け取り、`random(in:using:)` のように `using:` を付けて呼ぶ。**テストにも同じ禁止がかかる。**

### 網羅性検査を殺す分岐を書かない

`switch` に `default:` / `@unknown default` / `case _:` / `case let x:` を書かない（SWF-002・CNF-013）。
既知ケースを漏らす `@unknown default` は警告エラーでも warning のまま通ってしまう（M1-e）。選択肢が増えたらコンパイルが落ちるのが正しい状態。

### 警告のエラー化は `Package.swift` にある

target を足すときは `swiftSettings: [.treatAllWarnings(as: .error), .enableUpcomingFeature("ExistentialAny")]` を必ず付ける（CNF-009）。
コマンド行の `-Xswiftc -warnings-as-errors` は manifest の設定に負ける（M8-h）ので、そこに頼らない。

### 期待される失敗は例外にしない

FEN が読めない・合法でない指し手などは閉じた enum の結果型で返す。製品コードに `throw` / `try` / `catch` を書かない（ARC-010 / SWF-005・CNF-019）。

### テストは release 構成で回り、公開 API だけを使う

`make check` は `swift test -c release` を回す（perft の深さ 5 がデバッグでは遅すぎる・ADR 0004）。release では `@testable import` が使えないので、
テストは公開 API だけで書く。テストのために API を公開しない（SWF-008）。

### SwiftPM 自身の警告も失敗になる

`eng/swift-strict.sh` が `swift build` / `swift test` の出力の `warning:` を見て落とす。テスト target を足したらソースも同じ PR で足す（空のテスト target は警告になる）。

### 文字列で分岐するなら `if`

`switch` を `String` や `Int` に使うと全捕捉が要るが、`default:` / `case _:` / `case let x:` は CNF-013 が落とす。
`case _ where true:` は全捕捉にならず、コンパイラが `switch must be exhaustive` で拒む（証明 P50。Issue #5 で書きかけて確かめた）。
文字列での分岐は `if` で書く（`LaunchOptions.setting` の形）。

### 状態はループの値の中に置く

Swift 6 ではトップレベルの可変な変数は main actor に隔離され、トップレベルの関数から触れない。ループの状態は `Screensaver` の 1 つの値にまとめる（ADR 0006）。

### SwiftLint は静的バイナリ

動的バイナリは glibc 2.35 では起動しない。`make bootstrap`（または `make check` の `tools` 段）が `.tools/swiftlint` に静的バイナリを入れる。

## 3. 検証コマンド

```bash
make bootstrap      # clone 直後に 1 回（コミットフックと SwiftLint）
make check          # 唯一の完了定義（ローカルと CI で同じ）
```

開発中は最も狭い検査を使ってよい。フルゲートは **PR を Draft → Ready にする直前**に必ず通す。

🔴 **`make check` が通っていないものを「できた」と報告しない。**
実行していないコマンドの結果を書かない。テストの失敗を隠さない。
テストが本当の欠陥を見つけたら、期待値ではなく production コードを直す。

---

## 4. 変更の進め方

[docs/DEVELOPMENT_WORKFLOW.md](docs/DEVELOPMENT_WORKFLOW.md) が正本。要約すると:

Issue → 正典経路の特定 → ブランチ → （設計を変えるなら先に ADR）→ 最小の実装 →
テスト → 狭い検査 → `make check` → 規則 ID ごとの自己レビュー → PR（draft）→ Ready → squash merge。

コミットは Conventional Commits（`type` と `scope` は英語、説明は日本語、末尾に `(#N)`）。形の正本は GIT-003。

---

## 5. 完了報告の形

作業を終えたら必ず次を報告する。

```text
Issue / 規則 ID:
変更したファイルと振る舞い:
実行した検証コマンドと結果:
ドキュメント・スキーマの変更:
Waivers: none | WVR-NNNN
残るリスク:
```

調査だけを頼まれたときは、編集・コミット・push・PR 作成・外部状態の変更を行わない。

---

## 6. いまの状況

現在のタスクは [docs/todo/current.md](docs/todo/current.md)。GitHub Issue が正で、そこは要約。

- 動くもの: `make check`・`nene-gambit`（キャスト 4 名がランダムに指しながら話す対局をサイバー HUD で描き続ける）・`NeNeGambitCore`（perft は 6 局面×深さ 5 で公表値と一致）
- 動かないもの: 評価・探索・性格ごとの指し方（手順 4）
- 施主の未決（指示書の Q4〜Q10）を自分で埋めない。画面に出す前に Q4 の切り替え方・Q5・Q6・Q8 を、評価と探索の前に Q7 を聞く
