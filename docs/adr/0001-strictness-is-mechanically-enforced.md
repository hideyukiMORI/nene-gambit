# ADR 0001 — 厳格さは機械で強制する

- 状態: 受理
- 日付: 2026-10-25
- Issue: #1
- 影響する規則: すべて

## 文脈

本リポジトリの規約は、AYANE 厳格規約ポリシーと、先行する 5 リポジトリ（NENE-PIXEL＝Kotlin / nene-recall＝Go /
xi-tools＝Rust / NeNeCommander＝C# / NeNeClock＝Java）で確立された考え方を Swift 6 へ持ち込んだものである。
Swift への適用は NeNe Delve（2026-10-23）・NeNe Sand（2026-10-24）に続いて 3 回目になる。共通する中核は 1 つに要約できる。

> **一つの意味には一つの正典経路しか無い状態を作り、それを人の記憶ではなく機械に守らせる。**

規約は、破ったときに何も起きなければ、時間とともに必ず腐る。

### Swift 6.4.1 で実測したこと

先行の値を写さず、ポリシー第 3 節の M-1〜M-8 を 2026-10-25 に自分でコンパイルして確かめた。
実測は `eng/measure-language.py` が一時ディレクトリに swiftc の呼び出しと SwiftPM パッケージを作って行い、
終了コードと診断行を [docs/quality/phase0-results.json](../quality/phase0-results.json) にそのまま書く（56 ケース）。
判定はこの ADR で人が書く。再実行は `python3 eng/measure-language.py --swiftlint <swiftlint-static>`。

環境: Swift 6.4.1（swift-6.4.1-RELEASE・x86_64-unknown-linux-gnu）/ swift-format 6.4.1（ツールチェーン同梱）/
SwiftLint 0.65.1（`swiftlint-static`）/ WSL2 Ubuntu・glibc 2.35。swiftc の直接呼び出しは `-swift-version 6 -warnings-as-errors`、
SwiftPM は `// swift-tools-version: 6.2` の manifest に `swiftSettings: [.treatAllWarnings(as: .error)]` を置いた。

#### M-1 網羅性

```text
M1-a  ケース漏れ                         exit 1  error: switch must be exhaustive
M1-b  default:                           exit 0  診断なし
M1-c  case _:                            exit 0  診断なし
M1-d  case let other:（束縛する全捕捉）   exit 0  診断なし
M1-e  @unknown default で既知ケース漏れ   exit 0  warning: switch must be exhaustive（-warnings-as-errors でも warning のまま）
M1-h  同上を SwiftPM の treatAllWarnings(as: .error) で  exit 0  warning のまま
M1-g  タプルの位置の _                   exit 0  診断なし
```

🔑 `case let other:` は `default` とも `case _` とも書かずに網羅性検査を殺す。字句検査は 3 つとも拒否しなければならない。
タプルの位置の `_`（`case (.a, _):`）は「その位置を見ない」という意味で、全捕捉ではない。これは拒否しない。

#### M-2 公開状態の不変

```text
M2-a  他モジュールから public let へ代入          exit 1  error: cannot assign to property: 'size' is a 'let' constant
M2-b  他モジュールから public private(set) var へ  exit 1  error: cannot assign to property: 'moves' setter is inaccessible
M2-c  他モジュールから public var へ代入          exit 0
M2-d  返した配列に append                         exit 0  実行結果 owner=1 copy=2（配列は値の意味で複製される）
M2-e  let で持ったクラス参照の var を変更          exit 0
```

#### M-3 null・ゼロ値・未初期化

```text
M3-a  未初期化の let を返す（-typecheck）  exit 0  診断なし
M3-b  同じソースを本コンパイル（-c）        exit 1  error: constant 'x' used before being initialized
M3-c  暗黙アンラップ Optional（Int!）       exit 0
M3-d  強制アンラップ v!                    exit 0
M3-e  空 struct の Marker()・既定値つき struct の Score()  exit 0
M3-f  宣言だけの var を読む                exit 1  error: variable 'x' passed by reference before being initialized
```

暗黙のゼロ値は無い（M3-f）。`nil` を持てるのは Optional だけだが、IUO と強制アンラップはコンパイラが通す。

#### M-4 非公開コンストラクタ

```text
M4-a  private init を同一モジュールの別ファイルから   exit 1  error: 'Square' initializer is inaccessible due to 'private' protection level
M4-b  明示 init の無い public struct を他モジュールから  exit 1  error: ... due to 'internal' protection level
M4-c  明示 init の無い struct を同一モジュールの別ファイルから  exit 0（memberwise init）
M4-d  unsafeBitCast(99, to: Square.self)              exit 0
M4-e  Decodable の合成 init(from:)                    exit 0（private init を経ずに値ができる）
```

#### M-5 中核の決定性（依存を宣言しない SwiftPM target）

```text
M5-a  import Foundation; Date()              exit 0
M5-b  import Glibc; time(nil)                exit 0
M5-c  Int.random(in:)（import なし）          exit 0
M5-d  SystemRandomNumberGenerator（import なし）  exit 0
M5-e  ContinuousClock.now（import なし）      exit 0
M5-f  CommandLine.arguments（import なし）    exit 0
M5-g  import Dispatch; DispatchTime.now()    exit 0
M5-h  M5-a に --explicit-target-dependency-import-check error  exit 0（標準モジュールは対象外）
```

no_std に当たる仕組みは見つからなかった。時計・乱数・プロセス状態は**標準ライブラリだけで**読める。

#### M-6 依存方向

```text
M6-a  宣言していない兄弟 target を import（両方が同じ実行物の依存）  exit 1  error: no such module 'Engine'
M6-b  M6-a に --explicit-target-dependency-import-check error         exit 1  同上
M6-c  宣言していない target を import し、その target だけ build        exit 1  同上
M6-d  target の循環を宣言                                             exit 1  error: '<probe>': cyclic dependency declaration found: Core -> Engine -> Core
```

各ケースは 1 回ずつの clean build である。M6-a はビルド順に頼らず拒まれた。

#### M-7 抑制

```text
M7-a  @diagnose(DeprecatedDeclaration, as: ignored)        exit 0  -warnings-as-errors 下の警告が消える
M7-b  対照: 同じ呼び出しを抑制なしで                       exit 1  error: 'old()' is deprecated [#DeprecatedDeclaration]
M7-c  呼び出し側に @available(*, deprecated)               exit 0  非推奨の警告が消える
M7-d  manifest の .treatWarning("DeprecatedDeclaration", as: .warning)  exit 0  warning に戻る
M7-e  // swiftlint:disable:next force_unwrapping（理由なし）  exit 0
M7-f  対照: 抑制なし                                       exit 2  error: Force Unwrapping Violation ... (force_unwrapping)
M7-g  // swift-format-ignore（理由なし）                    exit 0
M7-h  対照: swift-format lint --strict                      exit 1  error: [AlwaysUseLowerCamelCase] ...
```

🔴 Swift 6.4.1 には**ソースの属性で警告を消す経路**（`@diagnose(<group>, as: ignored)`）がある。理由も規則 ID も要らない。

#### M-8 baseline・全面抑制

```text
M8-a  treatAllWarnings(as: .error) と unsafeFlags(["-suppress-warnings"])  exit 1  error: conflicting options '-warnings-as-errors' and '-suppress-warnings'
M8-g  unsafeFlags(["-suppress-warnings"]) だけ                exit 0  target 全体の警告が消える
M8-b  treatAllWarnings(as: .warning)                          exit 0  target 全体が warning に戻る
M8-c  対照: treatAllWarnings(as: .error)                      exit 1  error: 'old()' is deprecated
M8-h  swift build -Xswiftc -warnings-as-errors ＋ manifest の treatAllWarnings(as: .warning)  exit 0  manifest が勝つ
M8-i  swift build -Xswiftc -warnings-as-errors ＋ manifest の treatWarning(_:as: .warning)   exit 0  manifest が勝つ
M8-d  swiftlint --write-baseline → --baseline                 exit 0  既存違反が消える
M8-e  // swiftlint:disable all（ファイル先頭）                exit 0
M8-f  // swift-format-ignore-file                             exit 0
```

🔴 **ゲートのコマンド行で `-warnings-as-errors` を渡しても、`Package.swift` の設定がそれを上書きする**（M8-h・M8-i）。
警告をエラーにする設定は manifest に置き、manifest そのものを規約検査が読まなければ、警告のエラー化は守れない。

#### 補足（Phase 1 の判断材料）

```text
X-a  裸の protocol 型（any 無し）                       exit 0
X-b  .enableUpcomingFeature("ExistentialAny") を有効に  exit 1  error: use of protocol 'P' as a type must be written 'any P'
X-c  テスト target が無いパッケージで swift test        exit 1  error: no tests found; create a target in the 'Tests' directory
```

| 先行事例の規則 | Swift 6.4.1（本リポジトリの実測） |
| --- | --- |
| 不正状態を表現不能に・網羅性 | **不十分**。ケース漏れは error（M1-a）。`default:` / `case _:` / `case let x:` は診断なし。既知ケースを漏らす `@unknown default` は警告エラーでも warning で exit 0。字句検査で 4 つとも拒否する |
| 公開状態は不変 | **不十分**。`let` と `private(set)` は他モジュールからの代入を拒む。`public var` とクラス参照の中身は通る。配列は値の意味で複製される |
| `null` の意味は一つ（ゼロ値・未初期化の穴） | **不十分**。暗黙のゼロ値は無い。未初期化の `let` は本コンパイルで error（`-typecheck` では出ない）。IUO と強制アンラップは通る → SwiftLint で補う |
| 非公開コンストラクタ＋唯一のファクトリ（迂回経路） | **不十分**。`private init` は他ファイル・他モジュールから拒む。同一モジュールの memberwise、`unsafeBitCast`、`Decodable` の合成 init が迂回する |
| 中核の決定性を構文的に塞げるか | **無い**（言語では）。Foundation / Glibc / Dispatch は宣言なしで import でき、時計・乱数・`CommandLine` は標準ライブラリだけで読める。字句検査で補う |
| 依存方向をビルドが拒むか（標準同梱の枠組みの漏れ） | **ある**（target 間）。宣言の無い import は `no such module`、循環は `cyclic dependency`。標準モジュールは漏れる |
| 抑制を言語で封じられるか | **不十分**。`@diagnose(..., as: ignored)`・呼び出し側の `@available(*, deprecated)`・manifest の `treatWarning`・`swiftlint:disable`・`swift-format-ignore` がどれも理由なしで効く。waiver 台帳と字句検査で補う |
| baseline を作る経路が塞がっているか | **塞がっていない**。manifest の `treatAllWarnings(as: .warning)` / `unsafeFlags(["-suppress-warnings"])` が target 全体を緩め、コマンド行の指定に勝つ。SwiftLint に `--baseline` がある。規約検査が manifest と設定ファイルを読んで拒む |

### 先行の Swift 列（NeNe Delve 2026-10-23・NeNe Sand も 8 項目一致）との突き合わせ

Delve の公開リポの ADR 0001（`docs/adr/0001-strictness-is-mechanically-enforced.md`）と、ポリシー同梱の比較表の Swift 列を読んで比べた。
**判定（ある／無い／不十分）は 8 項目とも一致した。** 事実の記述では 1 項目が食い違い、4 項目で先行に無い穴が見つかった。

| # | 判定 | 事実の突き合わせ |
| --- | --- | --- |
| M-1 | 一致（不十分） | 一致: ケース漏れ error・`default` / `case _` 診断なし・`@unknown default` は warning のまま exit 0。**追加**: `case let x:` も診断なしで網羅性を殺す（M1-d）。先行の字句検査（`default` / `case _`）だけでは塞がらない |
| M-2 | 一致（不十分） | 一致: `let` / `private(set)` は拒否、`public var` は通る。**追加**: 返した配列は値の意味で複製される（M2-d）。クラス参照は `let` でも中身を変えられる（M2-e） |
| M-3 | 一致（不十分） | 一致: `-typecheck` では未初期化 `let` が出ず本コンパイルで error・IUO と強制アンラップは通る・空 struct は作れる |
| M-4 | 一致（不十分） | 一致: `private init`・memberwise・`unsafeBitCast` の結果。**追加**: `Decodable` の合成 `init(from:)` が `private init` を迂回する（M4-e） |
| M-5 | 一致（言語では塞げない） | 一致: Foundation / Glibc / Dispatch・`Int.random`・`ContinuousClock`・`SystemRandomNumberGenerator`。**追加**: `CommandLine.arguments` も標準ライブラリだけで読める（M5-f）。`--explicit-target-dependency-import-check error` は標準モジュールを拒まない（M5-h） |
| M-6 | 一致 | 一致: `no such module` / `cyclic dependency`・標準モジュールは漏れる |
| M-7 | 一致（不十分） | 🔴 **不一致**: 比較表の Swift 列は「コンパイラに警告抑制の pragma は無い」と書く。`#pragma` が無いことは本リポジトリでは測っていないが、**属性 `@diagnose(<group>, as: ignored)` で警告エラー下の警告を消せる**（M7-a・対照 M7-b）。「コンパイラに抑制の経路は無い」とは読めない。呼び出し側の `@available(*, deprecated)`（M7-c）と manifest の `treatWarning`（M7-d）も先行に無い経路 |
| M-8 | 一致（言語では塞がらない） | 一致: SwiftLint の `--baseline`・`-warnings-as-errors` と `-suppress-warnings` の衝突。**追加**: manifest の `treatAllWarnings(as: .warning)` / `treatWarning` はコマンド行の `-Xswiftc -warnings-as-errors` に勝つ（M8-h・M8-i）。ゲートのコマンド行では守れない |

3 回目でも判定は動かなかったので、Swift 列の**判定**は確定とみなせる。ただし M-7 の記述は「pragma は無い」から
「pragma は無いが `@diagnose` 属性がある」へ直すべきで、M-1・M-4・M-5・M-8 には上の追加を足すべきである。
比較表の正本は本リポジトリの外にあるので、ここでは書き換えず、食い違いとしてここに残す。

参考にした先行の箇所（コードは写していない）: Delve の ADR 0001 の実測の段落と比較表。Sand の公開リポは 2026-10-25 時点で
`LICENSE` だけだったので、Sand の値は比較表の注記（「8 項目一致」）でしか見ていない。

**そして、いま実装が空である。** 規則を後から被せる場合に必要になる baseline が、今は要らない。
違反ゼロから始められる時点は今しかない。

## 決定

**すべての規範規則に「機械強制の状態」を持たせ、その状態を文書の側で機械検査する。**

1. 規則の正本を `docs/ARCHITECTURE_CONSTITUTION.md` / `docs/CODING_RULES.md` / `docs/QUALITY_GATES.md` に置く。
   すべての規則に ID を与え、状態を **active / planned / 不能 / 不採用** で明示する。**planned を active と書かない**
2. `make check` を唯一の入口とする。CI は同じコマンドを呼ぶだけにし、CI 側にしか無い検査を作らない
3. baseline を持たない。例外は期限付きの狭い waiver だけ
4. 抑制には理由と規則 ID を要求する。Swift は抑制を言語で封じられない（M-7）ので **waiver 台帳を持つ**。
   SwiftLint の行単位の抑制（`swiftlint:disable:next` / `:this`）だけを、直前行の `// Waiver: WVR-NNNN` と有効な台帳の項目が
   そろったときに許す。`@diagnose`・`swift-format-ignore`・ファイル単位の抑制は waiver があっても拒否する
5. ゲートを弱める変更は ADR を要する
6. Swift の版は `.swift-version` だけが決める。SwiftLint の版と SHA-256 は `eng/swiftlint.lock` だけが決める。2 か所に書かない
7. **ゲートは意図的な違反で発火することを証明してから active と書く**（`docs/quality/gate-proofs.md`）
8. 規約検査（`eng/conformance.py`）は Python 3 の標準ライブラリだけで書く。自身の正例・反例テストをゲートから呼ぶ

実測から直接決まる Swift 固有の決定:

- **警告のエラー化は `Package.swift` の各 target の `swiftSettings: [.treatAllWarnings(as: .error), ...]` 1 か所に置く。**
  コマンド行の `-Xswiftc -warnings-as-errors` は manifest に負ける（M8-h）ので置かない（同じ規則を 2 か所に置かない）。
  規約検査が manifest を読み、全 target にこの設定があること、`treatWarning` / `treatAllWarnings(as: .warning)` /
  `unsafeFlags` が無いことを確かめる
- 網羅性を殺す `default` / `case _` / `case let <名前>:` / `case var <名前>:` / `@unknown default` を字句検査で拒否する（M-1）
- `@diagnose`・`@available(..., deprecated ...)`・`unsafeBitCast` 等の `unsafe` 系 API を字句検査で拒否する（M-4・M-7）
- Core と Engine は import を許可リスト（Core は無し、Engine は Core だけ）で縛り、時計・乱数・プロセス状態の API 名を字句検査で拒否する（M-5）
- 依存方向は SwiftPM の target グラフ（M-6）を正とし、機械可読の正本 `docs/architecture/module-graph.txt` と `Package.swift` の宣言を突き合わせる
- `ExistentialAny` を全 target で有効にする（X-b）
- 単体テストは `swift test` で回すが、テスト target が 1 本も無い木では `swift test` が exit 1 になる（X-c）。
  意味の無いテストを足して結線しない。最初のテスト target が入る Phase 3 の PR で `make check` に結線する

## 強制

- **active にする条件**: Phase 2 で negative proof を `docs/quality/gate-proofs.md` に記録したもの。強制マトリクス（`docs/QUALITY_GATES.md` 第 3 節）が正本
- **不能**: 「`planned` を勝手に `active` と書き換えないこと」そのもの。文書整合検査は active の行に証明行があることまでは見るが、
  証明が本物かどうかは人が見るしかない

## 結果

得られるもの:

- 規約が自分について嘘をつく経路が塞がる
- 新しい貢献者（人でも AI でも）が「何がいま守られているか」を 1 か所で読める
- 規約を緩めるコストが上がる

失うもの:

- 文書のメンテナンスコスト。規則を足すたびに 3 か所（本文・マトリクス・実装）が同期を要求される
- 検査の実装そのものの保守。Swift の構文を字句で見るので、文字列リテラルやコメントの中身を誤検出しないよう検査器が字句を剥がす
- 書き味の制約: `switch` に全捕捉を書けないので、整数や文字列での分岐は `if` で書くか閉じた enum に直すことになる。
  端末の termios / ioctl には `withUnsafeMutablePointer` 等が要るので、`unsafe` 系 API を許す区画を 1 つだけ作ることになる

**正直に記録しておくこと:**

- 🔴 字句検査は意味を見ない。`case let x:` を `case let (x):` のように書き換える迂回や、`typealias` で API 名を隠す迂回は、
  検査器が見る形を増やさない限り通る。見つけたら事故として規則に足す
- 🔴 `public var` とクラス参照の可変性は言語で塞げない。公開型を struct に寄せ、SwiftLint と規約検査で補えるところだけ補う
- 🔴 `swiftlint` の検査は静的バイナリの 0.65.1 に依存する。動的バイナリはこの環境の glibc 2.35 では起動しなかった（`GLIBC_2.38` が無い）
- **本 ADR の厳格さは、実装がまだ空である今だからこそ無傷で導入できた。** 緑であることは、規則が良いことの証明ではない。
  検査対象がまだ小さいことの結果でもある。実装で規則が邪魔になったとき、緩めるのではなく **ADR で判断を残すこと**が本 ADR の眼目である

## 却下した選択肢

| 選択肢 | 却下の理由 |
| --- | --- |
| 散文の規約だけを置く | 守られているかを確かめる手段が無く、時間とともに必ず腐る。**本 ADR の出発点そのもの** |
| 既製 lint の既定セットだけで済ませる | 既製ルールは「Swift として危ういこと」を見るが、「NeNe Gambit として守るべきこと」（Core が時計を読まない等）は見られない |
| 全 lint の一括有効化（SwiftLint の `opt_in_rules: all` 相当） | 相互に矛盾する規則が同時に入り、規則ではなく道具の機嫌に従うことになる |
| baseline を作って既存違反を後回しにする | 新規リポジトリなので既存違反が無い。ここで baseline を許すと、以後の違反も同じ入口から入ってくる |
| 実装が入ってから導入する | 既存違反を凍結する baseline が必要になる。今なら違反ゼロで始められる |
| 規約を `CLAUDE.md` にだけ書く | 人間と AI の遵守に依存する。前例（nene-recall）で、規約は CLAUDE.md にあったが守っていたのはテスト 10 ケースだけだった |
| 規則 ID を付けず散文で参照する | 「どの規則の話か」がレビューのたびに揺れる |
| 警告のエラー化をゲートのコマンド行（`-Xswiftc -warnings-as-errors`）に置く | manifest の設定に負ける（M8-h・M8-i）。守っているように見えて守れない |
| `--explicit-target-dependency-import-check error` で中核の import を縛る | 標準モジュール（Foundation）を拒まない（M5-h）。target 間は既定でも `no such module` になる（M6-a）ので足しても何も増えない |
| `-typecheck` を高速な検査としてゲートに使う | 未初期化 `let` を見逃す（M3-a）。ゲートは本コンパイルを使う |
| 規約検査を Swift で書く | 検査器が検査対象と同じパッケージのビルドに乗り、ビルドが壊れたときに検査器も動かなくなる。Python 3 の標準ライブラリは CI のランナーにも WSL にも入っている |

## 関連

- 先行: NENE-PIXEL `docs/ADR`、nene-recall ADR 0010、xi-tools ADR 0001、NeNeCommander ADR-0001、NeNeClock ADR 0001、NeNe Delve ADR 0001
- 実測: [docs/quality/phase0-results.json](../quality/phase0-results.json)・`eng/measure-language.py`
