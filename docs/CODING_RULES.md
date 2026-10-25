# Swift コーディング規約 — NeNe Gambit

> Status: normative（規範）/ 2026-10-25 初版
> 判断の根拠は [ADR 0001](adr/0001-strictness-is-mechanically-enforced.md)。
> 本書は Swift 6（言語モード 6・strict concurrency）を本リポジトリで承認された部分集合に狭めるためのものであり、
> ここが沈黙している領域は公式の Swift 標準に従う。

読み方（**active / planned / 不能 / 不採用**）と強制の層は
[ARCHITECTURE_CONSTITUTION.md](ARCHITECTURE_CONSTITUTION.md) 第 0 節と同じ。
括弧の中の M1-a 等は [phase0-results.json](quality/phase0-results.json) の実測ケースの番号である。

---

## 1. 型と状態（SWF-0xx）

### SWF-001 — 境界でのプリミティブ執着を禁じる

升・駒・指し手・探索の深さ・シードのように**単位や不変条件を持つ値**は専用の型にする。生の `Int` や `String` を深いところまで運ばない。
検証は生成時に行う。文字列キーの辞書で型を代用しない。

- 機械強制: **planned**（「専用型にすべき値かどうか」はレビュー事項）
- 補助: SWF-007（唯一のファクトリ）により、型を作れば必ず検証される

### SWF-002 — 閉じた選択肢は閉じた型で表し、網羅性検査を殺さない

駒の種類・色・終局の理由・意図のように閉じた選択肢は `enum` で表す。boolean の組み合わせ・マジック整数・裸の文字列で表さない。
`switch` に `default:` / `@unknown default` / `case _:` / `case let x:` / `case var x:` を書かない。**書いた瞬間に検査は死ぬ**（M1-b〜M1-e）。
整数や文字列で分岐したいときは `if` で書くか、閉じた enum に直してから `switch` する。`fallthrough` も使わない。

タプルの位置の `_`（`case (.white, _):`）は「その位置を見ない」という意味で、全捕捉ではないので許す。

- 機械強制: **active** → コンパイラ（ケース漏れは error・M1-a）＋CNF-013（全捕捉を字句で拒否）＋SwiftLint `fallthrough`

### SWF-003 — 公開状態は不変

`public var` の格納プロパティを持たない（他モジュールから代入できる・M2-c）。公開する格納プロパティは `let` か `private(set) var`。
`open` を使わない。公開型は値の意味を持つ `struct` / `enum` に寄せる（配列は値の意味で複製される・M2-d）。クラスについては SWF-018。

- 機械強制: **active** → コンパイラ（`let` / `private(set)` への代入は error・M2-a / M2-b）＋CNF-016（公開の格納 `var` と `open` を拒否）

### SWF-004 — `nil` の意味は一つ

`nil` が意味してよいのは「省略可能な値が無い」だけ。無効・未読込・失敗・未知を表さない。
強制アンラップ `!`・暗黙アンラップ Optional（`T!`）・`as!`・Optional の Bool とコレクションを書かない（M3-c・M3-d）。

- 機械強制: **active** → SwiftLint `force_unwrapping` / `implicitly_unwrapped_optional` / `force_cast` / `discouraged_optional_boolean` / `discouraged_optional_collection`
- 補足: 暗黙のゼロ値は無い（M3-f）。未初期化の `let` は本コンパイルでだけ error になる（M3-a / M3-b）ので、ゲートは `-typecheck` を使わない

### SWF-005 — 期待される失敗は例外で表さない

検証エラー・合法でない指し手・読めない FEN は閉じた結果型（`enum`）で返す。製品コードに `throws` / `throw` / `try` / `catch` を書かない。
`try!` も書かない。プログラム上の欠陥は `precondition` / `fatalError` で止める。

- 機械強制: **active** → CNF-019（製品コードの例外を拒否）＋SwiftLint `force_try`
- 補足: テストは Swift Testing の `#require` が `throws` を要るので CNF-019 の対象外

### SWF-006 — 汎用データバッグを禁じる

`Any` / `AnyObject` / `AnyHashable` / `AnyClass` と、3 つ以上の要素のタプルで型を代用しない。名前付きの型を作る。

- 機械強制: **active** → CNF-020（`Any` 系を拒否）＋SwiftLint `large_tuple`（要素 3 以上を拒否）

### SWF-007 — 構築が不変条件を守る

不変条件を持つ型は `init` を `private` にし、生成経路を**唯一のファクトリ**（結果型を返す `static func`）に集約する（M4-a）。
明示 `init` の無い struct は同一モジュールの他ファイルから memberwise init で作れてしまう（M4-c）ので、不変条件を持つ型には必ず `private init` を書く。
`Codable` / `Decodable` / `Encodable` を使わない（合成された `init(from:)` がファクトリを迂回する・M4-e）。

- 機械強制: **planned**（`private init` を書き忘れないことはレビュー事項。補助: CNF-015 が `Codable` を、CNF-014 が `unsafeBitCast` を拒否する）

---

## 2. 構築と可視性

### SWF-008 — 可視性は最小

既定は `internal` 以下。他の target から実際に使うものだけ `public`。テストのためだけに `public` にしない（`@testable import` を使う）。
`fileprivate` より `private` を使う。

- 機械強制: **planned**（「実際に使うか」はレビュー事項。補助: swift-format の `FileScopedDeclarationPrivacy` がファイル直下の `fileprivate` を拒否する）

### SWF-009 — 言語マジックを制限する

`unsafe` 系 API（`unsafeBitCast`・`Unsafe*Pointer`・`withUnsafe*`・`Unmanaged`・`@unchecked Sendable`・`nonisolated(unsafe)`）は、
termios / ioctl のために依存グラフの正本で `unsafe=allowed` を宣言した `NeNeGambitTerminal` だけで使える。
リフレクション（`Mirror`）・下線付き属性（`@_…`）・動的呼び出し（`@dynamicMemberLookup` / `@dynamicCallable`）・マクロ・
`dlopen`・`@objc`・SwiftPM のビルドプラグインは、どこでも使わない（使うなら ADR）。

- 機械強制: **active** → CNF-014＋CNF-009（manifest の `plugins:`）

### SWF-010 — 名前が役割を語る

常に禁止する型名の語尾: `Manager` / `Helper` / `Util` / `Utils` / `Common`。
常に禁止するディレクトリ・target 名: `utils` / `helpers` / `managers` / `misc` / `common`。

承認された役割の語尾は `Port` / `Adapter` / `Query` / `Command` / `Handler` / `Policy` / `Factory` / `Codec` / `Mapper` / `Renderer` / `Reducer` / `Outcome` / `Rejection`。
**その型がその役割そのものであるときだけ**使う。`Processor` や `Data` のように文脈次第で妥当な語は機械では拒否しない。

- 機械強制: **active** → CNF-001

### SWF-011 — 1 ファイル 1 主要宣言

ファイルの最上位に置く型（`class` / `struct` / `enum` / `protocol` / `actor`）は 1 つまでとし、ファイル名は型名と一致させる。
拡張だけのファイルは `型名+役割.swift` とする。寄せ集めのファイルを作らない。

- 機械強制: **active** → CNF-002

### SWF-012 — 複雑度に上限を置く

| 指標 | 上限 | 道具 |
| --- | --- | --- |
| 循環的複雑度（関数・`case` も数える。SwiftLint は分岐 11 個を 11 と数える） | 10 | SwiftLint `cyclomatic_complexity` |
| 関数の長さ | 60 行 | SwiftLint `function_body_length` |
| 型の入れ子・関数の入れ子 | 型 1 段・関数 2 段 | SwiftLint `nesting` |
| 引数の数（既定値つきも数える） | 4 | SwiftLint `function_parameter_count` |
| ファイルの長さ | 400 行（コメントだけの行を除く） | SwiftLint `file_length` |
| 型の長さ | 300 行 | SwiftLint `type_body_length` |

閾値を満たすためだけに意味のある処理を割るのは目的に反する。超える必要があるときは**測定可能な理由**を添えて ADR にする。
（盤面の指し手生成は駒の種類ごとに関数を分けるので 60 行に収まる見込みだが、収まらなければ ADR で判断する。）

- 機械強制: **active** → SwiftLint の 6 規則

### SWF-017 — 制御構造のネストは 4 段まで・公開 API に bool の制御引数を置かない

`if` / `for` / `while` / `switch` / `guard` のネストは 4 段まで。公開 API の関数に、振る舞いを切り替えるための `Bool` 引数を置かない（閉じた enum にする）。

- 機械強制: **不能**（SwiftLint の `nesting` は型と関数の入れ子だけを数え、制御構造のネストと bool の制御引数を測る規則は無い。字句検査で波括弧を数える案は、クロージャと区別できないので採らない。レビュー事項）

---

## 3. 実行時の規律

### SWF-013 — 並行性の形は一つ

並行の形は 1 つ: 合成ルートの 1 本のループが `poll(2)` で入力と締め切りを待つ（ADR 0006）。どの target でも `Task` / `actor` / `async` /
スレッド / Dispatch を使わない。シグナルのハンドラは原子的な旗を立てるだけで、例外は異常終了のシグナルで端末を戻すことだけ。

- 機械強制: **planned**（Dispatch は CNF-011 の import 許可リストで拒否される。`Task` / `async` / `Thread` を見る字句検査はまだ無い）

### SWF-014 — 日時・数値・文字集合の扱いを一つに固定する

Foundation をどの target からも import しない（許可リストに無い）。日時は合成ルートの `ContinuousClock` だけ。
ロケール依存の整形をしない。文字は Swift の `String` / `Character` で扱い、端末へ出すときに UTF-8 にするのは Terminal だけ。
駒記号を出すときの 1 升の桁数は Render の 1 か所で決め、その前提を ADR に書く（East Asian Ambiguous 幅の問題）。

- 機械強制: **active** → CNF-011（Foundation を許可リストに入れない）＋CNF-012（`Locale` / `TimeZone` / `Date` の名前を拒否）

### SWF-015 — 抑制は例外であって道具ではない

Swift は抑制を言語で封じられない（`@diagnose(..., as: ignored)`・呼び出し側の `@available(*, deprecated)`・manifest の `treatWarning`・
`swiftlint:disable`・`swift-format-ignore` が理由なしで効く・M7-a〜M7-g）。そこで:

- 書ける抑制は SwiftLint の**行単位**の `swiftlint:disable:next <規則>` / `swiftlint:disable:this <規則>` だけで、
  **直前行の `// Waiver: WVR-NNNN`** と、そのファイルを Scope に持つ active な waiver 台帳の項目が両方そろっているときに限る
- `swiftlint:disable`（範囲）・`swiftlint:enable`・`all`・`swift-format-ignore`（行・ファイル）・`@diagnose` / `@warn`・
  `@available(..., deprecated)` は waiver があっても書けない
- 腐った抑制（もう違反が無いのに残っている）は SwiftLint `superfluous_disable_command` が落とす
- 期限切れの waiver は CNF-004 がゲートを落とす

- 機械強制: **active** → CNF-003 / CNF-004＋SwiftLint `superfluous_disable_command` / `blanket_disable_command`

### SWF-018 — 公開 API でクラスを返さない

クラス参照の中身は `let` で持っても変更できる（M2-e）。公開 API が返す・受け取る型は値の意味を持つ `struct` / `enum` にし、クラスを返さない。

- 機械強制: **planned**（レビュー事項。公開の格納 `var` と `open` は CNF-016 が拒否する）

### SWF-016 — テスト枠組みは Swift Testing だけ

テストは Swift Testing（`import Testing`）で書く。XCTest を import しない（[ADR 0002](adr/0002-swift-testing-only.md)）。

- 機械強制: **active** → CNF-011（テスト target の許可リストは `Testing` だけ）

---

## 4. 端末 UI 規約

NeNe Gambit の UI は端末の文字セルである。画面の構成は ADR 0005、端末の扱いは ADR 0006。憲章の ARC-011（Render は値を作るだけ・
Terminal は差分を書くだけ）に加えて、次を設計の前提にしている。どれもまだ規則 ID と機械の検査を持たない（手順 3 で施主が実機を見た後に、
規則にするかを決める）。

- 1 つの `Character` が 1 桁を占める。HUD の文言は ASCII の英語（ADR 0005）。罫線の文字は、端末が 1 桁で描くと測れたときだけ使う（ADR 0007）
- 色の値を持つのは `Theme` だけ、画面の枠や見出しの文言を持つのは `Wording` だけ。キャラクターの名前とセリフは Engine の `Persona` が持つ（ADR 0007）
- 前フレームとの差分セルだけを書き、1 フレーム 1 回の `write` にする

---

## 5. 依存の方針

新しい依存を足すときは、次の 3 つを揃える。**1 つでも欠けたら足していない。**

1. ADR を 1 本立てる
2. 許可リスト（`eng/dependency-allowlist.txt`）に 1 行足す
3. 下の表に 1 行足す

| 依存 | 用途 | 根拠 |
| --- | --- | --- |
| — | — | 現在の実行時依存は 0（標準ライブラリと Glibc だけ） |

チェスのエンジン・チェスのライブラリは使わない（施主決定）。ncurses も使わない。
版は lock ファイルで固定し、manifest に範囲を書かない。規約検査（CNF-009）は許可リストに無い `.package(...)` を拒む。

---

## 6. 採用しなかった検査と、その理由

**「有効にしなかった」ことも決定である。** 再提案するときは、ここに書かれた理由への反論から始めること。

| 検査 | 不採用の理由 |
| --- | --- |
| SwiftLint の既定規則の一括有効化・`opt_in_rules` の一括 | 相互に矛盾する規則が同時に入り、規則ではなく道具の機嫌に従うことになる。`only_rules` で 1 つずつ名指しする |
| SwiftLint の `private_over_fileprivate` | swift-format の `FileScopedDeclarationPrivacy` が同じことを見る（P-04: 同じ規則を 2 か所に置かない。実測: 証明 P44 で swift-format が先に落とした） |
| SwiftLint の `identifier_name` / `type_name` | 盤面の座標（`rank` / `file` の 1 文字の添字）など、短い名前が意味を持つ領域で誤検出が多い。総称名の禁止は CNF-001 が見る |
| SwiftLint の `explicit_acl` | `internal` の既定を毎回書かせるだけで、可視性を小さくする方向には働かない（SWF-008 はレビュー事項） |
| SwiftLint の `unused_import` / `unused_declaration` | `analyze` サブコマンドとコンパイラのログが要り、静的バイナリの単独実行では回らない。未使用のローカル変数はコンパイラの警告（エラー化済み）が拾うが、未使用の `private` 宣言はどの道具も拾わない（不能として残す） |
| SwiftLint の `statement_position` ほか SourceKit が要る規則 | 静的バイナリでは SourceKit が使えず、規則が黙って飛ばされる（実測: `Skipping enabled rule 'statement_position'`）。飛ばされたら `eng/lint.sh` が落とす |
| `--explicit-target-dependency-import-check error` | 標準モジュールを拒まない（M5-h）。target 間は既定で拒まれる（M6-a） |
| XCTest | Swift Testing と同じパッケージに置くと 1 回の `swift test` が両方を回す（Delve の実測）。枠組みを 1 つにする（ADR 0002） |
| Foundation | 決定性の穴（`Date` / `Locale` / `ProcessInfo`）の入口で、製品に要る機能が無い。依存を 0 にする |

---

## 7. 規約に違反したくなったとき

1. **まず、規約が間違っている可能性を検討する。** 規約は実装より新しくない
2. 規約が正しいなら、設計を変える。抑制で通さない
3. どうしても抑制が要るなら、規則 ID と理由を伴う最小スコープの抑制を書く（SWF-015）
4. **規則そのものを緩めるなら ADR を書く**（QLT-010）。旧規則のどの部分が今も有効かを明記すること
