# ゲート発火の証明 — NeNe Gambit

> Status: 記録 / 最終実測 2026-10-25（`python3 eng/prove-gates.py`・結果の正本は [gate-proofs.json](gate-proofs.json)）
> 根拠となる規則: QLT-007（カスタムゲートには negative proof が要る）

**検査は「落ちること」を見るまで信用しない。** 各ゲートについて、最小の違反を仕込んだ状態で
意図した規則 ID によって失敗すること、そして元に戻すと `make check` が緑に戻ることを実測する。
ゲートを変えたら、この記録も同じ変更で更新する。

🔴 **この文書に結果を先に書かない。** 結果の列は実測するまで **未実測** のままにする。

証明は `eng/prove-gates.py` が行う。作業木を一時ディレクトリへ複製し、依存グラフの正本どおりの 5 target と規則に沿った最小のソース
（「足場」）を置いてから違反を **1 か所だけ** 仕込み、`make check`（P33・P34 だけはより狭いタスク）を回す。
**意図した規則 ID（または道具の規則名）が出力に現れて失敗したとき**だけ pass とする。別の理由で落ちたものは証明にならない
（実際に P12・P18・P31・P37・P44 は初回、意図しない理由で落ちたので、仕込みを直して取り直した。第 3 節）。
作業木そのものには触れない。足場は証明のための一時物で、リポジトリには入れていない。

環境: WSL2 Ubuntu（glibc 2.35）/ Swift 6.4.1（swiftly）/ swift-format 6.4.1 / SwiftLint 0.65.1（swiftlint-static）/ Python 3.10.12
CI: GitHub Actions `ubuntu-22.04` / Swift 6.4.1（固定の tarball・`eng/install-swift.sh`）

---

## 1. 実測結果

### 1-a. active の規則（規則 ID ごとの発火と復帰）

🔴 **文書整合検査（CNF-006）は「`| <規則 ID> |` で始まる行」を active の証明として読む。** active に書き換える規則は、
必ずこの表に規則 ID を行頭にして 1 行足す。
表は `python3 eng/prove-gates.py`（測り直す）か `--render`（測らずに作り直す）が gate-proofs.json と QUALITY_GATES.md の active の行から生成する。手で書かない。
規則を active に書き換えたら、**先に `--render` で表を作ってから**測り直す（複製の中で CNF-006 が「証明行が無い」で先に落ち、対照まで落ちる）。

<!-- proofs:active:start -->
| 規則 | 最小の違反 | 検証経路 | 実測 |
| --- | --- | --- | --- |
| ARC-002 | P01: Core が宣言していない Engine を import する<br>P02: Terminal が正本に無い Core への依存を宣言する（循環は作らない） | `make check` | P01: exit 2・`Sources/NeNeGambitCore/Probe.swift:1:8: error: no such module 'NeNeGambitEngine'`<br>P02: exit 2・`CNF-010 Package.swift:17: target NeNeGambitTerminal の依存が正本と違う（余分: NeNeGambitCore / 不足: なし）` |
| ARC-003 | P03: Core が Foundation を import する | `make check` | P03: exit 2・`CNF-011 Sources/NeNeGambitCore/Probe.swift:1: NeNeGambitCore は Foundation を import できない` |
| ARC-007 | P04: Engine が using: の無い Int.random を呼ぶ<br>P05: Core のテストが CommandLine.arguments を読む（テストにも禁止がかかる） | `make check` | P04: exit 2・`CNF-012 Sources/NeNeGambitEngine/Pick.swift:7: random(...) は using: で乱数源を受け取る`<br>P05: exit 2・`CNF-012 Tests/NeNeGambitCoreTests/ProbeTests.swift:3: 時刻・乱数・環境・プロセス状態は合成ルートだけが読む` |
| SWF-002 | P06: enum に case を足し、switch を直さない<br>P07: switch に default: を書く<br>P44: 有効にした SwiftLint の 16 規則それぞれの違反を 1 ファイルに置く（設定の全規則が実際に発火すること） | `make check` | P06: exit 2・`Sources/NeNeGambitCore/Side.swift:10:5: error: switch must be exhaustive`<br>P07: exit 2・`CNF-013 Sources/NeNeGambitCore/Side.swift:15: 全捕捉（default / @unknown default / case _ / case let x）は網羅性検査を殺す`<br>P44: exit 2・`Sources/NeNeGambitCore/Probe.swift:584:22: error: Blanket Disable Command Violation: Use 'next', 'this' or 'previous' in` |
| SWF-003 | P09: 公開の格納 var を置く | `make check` | P09: exit 2・`CNF-016 Sources/NeNeGambitRender/Cell.swift:3: public の格納 var は外から変更できる（let か private(set) にする）` |
| SWF-004 | P10: 強制アンラップを書く<br>P44: 有効にした SwiftLint の 16 規則それぞれの違反を 1 ファイルに置く（設定の全規則が実際に発火すること） | `make check` | P10: exit 2・`Sources/nene-gambit/main.swift:9:13: error: Force Unwrapping Violation: Force unwrapping should be avoided (force_unwrap`<br>P44: exit 2・`Sources/NeNeGambitCore/Probe.swift:584:22: error: Blanket Disable Command Violation: Use 'next', 'this' or 'previous' in` |
| SWF-005 | P11: 製品コードに throws を書く<br>P44: 有効にした SwiftLint の 16 規則それぞれの違反を 1 ファイルに置く（設定の全規則が実際に発火すること） | `make check` | P11: exit 2・`CNF-019 Sources/NeNeGambitCore/Probe.swift:4: 期待される失敗は閉じた結果型で返す（throw / try / catch は使えない）`<br>P44: exit 2・`Sources/NeNeGambitCore/Probe.swift:584:22: error: Blanket Disable Command Violation: Use 'next', 'this' or 'previous' in` |
| SWF-006 | P12: Any を使う<br>P13: 要素 3 つのタプルを返す<br>P44: 有効にした SwiftLint の 16 規則それぞれの違反を 1 ファイルに置く（設定の全規則が実際に発火すること） | `make check` | P12: exit 2・`CNF-020 Sources/NeNeGambitCore/Probe.swift:4: Any / AnyObject / AnyHashable / AnyClass は使えない`<br>P13: exit 2・`Sources/NeNeGambitCore/Probe.swift:4:29: error: Large Tuple Violation: Tuples should have at most 2 members (large_tuple`<br>P44: exit 2・`Sources/NeNeGambitCore/Probe.swift:584:22: error: Blanket Disable Command Violation: Use 'next', 'this' or 'previous' in` |
| SWF-009 | P14: Core で unsafeBitCast を使う | `make check` | P14: exit 2・`CNF-014 Sources/NeNeGambitCore/Probe.swift:3: unsafe 系の API は unsafe=allowed の target だけ` |
| SWF-010 | P15: 型を BoardHelper と名付ける | `make check` | P15: exit 2・`CNF-001 Sources/NeNeGambitCore/BoardHelper.swift:2: 総称名の型 BoardHelper` |
| SWF-011 | P16: 1 ファイルに最上位の型を 2 つ置く | `make check` | P16: exit 2・`CNF-002 Sources/NeNeGambitCore/Probe.swift:5: 主要宣言が 2 個ある: Probe, Other` |
| SWF-012 | P17: 引数 5 つの関数を書く<br>P18: 循環的複雑度 11 の関数を書く（SwiftLint は if 11 個を 11 と数える）<br>P44: 有効にした SwiftLint の 16 規則それぞれの違反を 1 ファイルに置く（設定の全規則が実際に発火すること） | `make check` | P17: exit 2・`Sources/NeNeGambitCore/Probe.swift:4:12: error: Function Parameter Count Violation: Function should have 4 parameters or`<br>P18: exit 2・`Sources/NeNeGambitCore/Probe.swift:4:5: error: Cyclomatic Complexity Violation: Function should have complexity 10 or le`<br>P44: exit 2・`Sources/NeNeGambitCore/Probe.swift:584:22: error: Blanket Disable Command Violation: Use 'next', 'this' or 'previous' in` |
| SWF-014 | P03: Core が Foundation を import する | `make check` | P03: exit 2・`CNF-011 Sources/NeNeGambitCore/Probe.swift:1: NeNeGambitCore は Foundation を import できない` |
| SWF-015 | P19: waiver 無しの swiftlint:disable:next で強制アンラップを抑制する<br>P20: @diagnose で非推奨の警告を消す<br>P21: 期限切れの active な waiver を台帳と索引に置く<br>P44: 有効にした SwiftLint の 16 規則それぞれの違反を 1 ファイルに置く（設定の全規則が実際に発火すること） | `make check` | P19: exit 2・`CNF-003 Sources/nene-gambit/main.swift:9: 直前行に有効な // Waiver: WVR-NNNN が無い`<br>P20: exit 2・`CNF-003 Sources/NeNeGambitCore/Probe.swift:3: @available(..., deprecated) は非推奨の警告を隠す`<br>P21: exit 2・`CNF-004 docs/waivers/WVR-0001:1: 期限切れの waiver（2026-10-24）`<br>P44: exit 2・`Sources/NeNeGambitCore/Probe.swift:584:22: error: Blanket Disable Command Violation: Use 'next', 'this' or 'previous' in` |
| SWF-016 | P22: テストで XCTest を import する | `make check` | P22: exit 2・`CNF-011 Tests/NeNeGambitCoreTests/ProbeTests.swift:1: NeNeGambitCoreTests は XCTest を import できない` |
| QLT-001 | P35: CI に make check 以外の run（swift build）を足す<br>P37: .swift-version を実際の版と違う 6.4.0 にする | `make check` | P35: exit 2・`CNF-018 .github/workflows/ci.yml:30: CI で許す run はツールチェーン導入とゲートの 1 行だけ: swift build`<br>P37: exit 2・`tools: swift は 6.4.0 が要るが、起動できない: The swift version file `.swift-version` requires toolchain version 6.4.0, which is not` |
| QLT-002 | P23: target の警告設定を treatAllWarnings(as: .warning) にして未使用の定数を置く（ビルドは警告で通る）<br>P24: 未使用のローカル定数を置く（警告がエラーになること） | `make check` | P23: exit 2・`CNF-009 Package.swift:8: target NeNeGambitCore に .treatAllWarnings(as: .error) が無い`<br>P24: exit 2・`Sources/NeNeGambitCore/Probe.swift:5:13: error: initialization of immutable value 'unused' was never used; consider repl` |
| QLT-003 | P25: 名前に baseline を含むファイルを置く<br>P26: .gitignore で Sources を検査から隠す | `make check` | P25: exit 2・`CNF-005 swiftlint-baseline.json:1: 名前に baseline を含むファイル`<br>P26: exit 2・`CNF-005 .gitignore:2: 検査の対象から外れる無視の指定 'Sources/NeNeGambitCore/Hidden.swift'（生成物の置き場だけを無視する）` |
| QLT-004 | P27: インデントを 2 桁にする<br>P28: Core のディレクトリに入れ子の .swiftlint.yml を置く | `make check` | P27: exit 2・`Sources/NeNeGambitRender/Cell.swift:3:1: error: [Indentation] indent by 2 spaces`<br>P28: exit 2・`CNF-007 Sources/NeNeGambitCore/.swiftlint.yml:1: ゲートが読まない場所の検査設定（入れ子の設定は道具が勝手に拾う）` |
| QLT-005 | P35: CI に make check 以外の run（swift build）を足す | `make check` | P35: exit 2・`CNF-018 .github/workflows/ci.yml:30: CI で許す run はツールチェーン導入とゲートの 1 行だけ: swift build` |
| QLT-006 | P02: Terminal が正本に無い Core への依存を宣言する（循環は作らない）<br>P03: Core が Foundation を import する | `make check` | P02: exit 2・`CNF-010 Package.swift:17: target NeNeGambitTerminal の依存が正本と違う（余分: NeNeGambitCore / 不足: なし）`<br>P03: exit 2・`CNF-011 Sources/NeNeGambitCore/Probe.swift:1: NeNeGambitCore は Foundation を import できない` |
| QLT-007 | P29: SourceKit が要る規則（statement_position）を有効にする（静的バイナリが黙って飛ばす）<br>P38: 規約検査の CNF-013 の検出を壊す（検査器の単体テストが落ちること） | `make check` | P29: exit 2・`lint: 有効にした規則が実行されていない（CNF-007）`<br>P38: exit 2・`FAILED (failures=1)` |
| QLT-011 | P33: 許可リストに無い外部パッケージを manifest に書く（解決に行かせないため狭い検査で）<br>P34: SwiftLint の lock の SHA-256 を 1 文字変え、道具を入れ直させる | `make conformance`<br>`make tools` | P33: exit 2・`CNF-009 Package.swift:7: 許可リストに無い外部パッケージ`<br>P34: exit 2・`/tmp/tmp.37udgxe7mj/swiftlint_linux_amd64.zip: FAILED` |
| QLT-012 | P45: CI のジョブに draft を飛ばす if: を書く（スキップは成功として数えられる）<br>P46: draft の PR に push する（CI のジョブはスキップでなく失敗し、PR はマージできない） | GitHub Actions run 40171721542（PR #2・head bb025a7・2026-10-25）<br>`make check` | P45: exit 2・`CNF-018 .github/workflows/ci.yml:16: if: は使えない（スキップされた必須 check は成功として数えられる）`<br>P46: step `eng/ci-require-ready.sh` が `ci: PR が draft なのでフルゲートを回さない。Ready にすると回る（QLT-012）` で exit 1。必須 check `check` は FAILURE・`mergeStateStatus` は `BLOCKED`。直す前（run 40171486988）はスキップで `CLEAN` だった |
| CNF-001 | P15: 型を BoardHelper と名付ける | `make check` | P15: exit 2・`CNF-001 Sources/NeNeGambitCore/BoardHelper.swift:2: 総称名の型 BoardHelper` |
| CNF-002 | P16: 1 ファイルに最上位の型を 2 つ置く | `make check` | P16: exit 2・`CNF-002 Sources/NeNeGambitCore/Probe.swift:5: 主要宣言が 2 個ある: Probe, Other` |
| CNF-003 | P19: waiver 無しの swiftlint:disable:next で強制アンラップを抑制する<br>P20: @diagnose で非推奨の警告を消す | `make check` | P19: exit 2・`CNF-003 Sources/nene-gambit/main.swift:9: 直前行に有効な // Waiver: WVR-NNNN が無い`<br>P20: exit 2・`CNF-003 Sources/NeNeGambitCore/Probe.swift:3: @available(..., deprecated) は非推奨の警告を隠す` |
| CNF-004 | P21: 期限切れの active な waiver を台帳と索引に置く | `make check` | P21: exit 2・`CNF-004 docs/waivers/WVR-0001:1: 期限切れの waiver（2026-10-24）` |
| CNF-005 | P25: 名前に baseline を含むファイルを置く<br>P26: .gitignore で Sources を検査から隠す | `make check` | P25: exit 2・`CNF-005 swiftlint-baseline.json:1: 名前に baseline を含むファイル`<br>P26: exit 2・`CNF-005 .gitignore:2: 検査の対象から外れる無視の指定 'Sources/NeNeGambitCore/Hidden.swift'（生成物の置き場だけを無視する）` |
| CNF-006 | P30: 未定義の規則 ID を文書に書く<br>P31: 証明行の無い規則をマトリクスで active にする（本文も合わせて書き換える） | `make check` | P30: exit 2・`CNF-006 docs/todo/current.md:25: 未定義の規則 ID ARC-0 99（仕込んだ未定義の ID。この文書自身が落ちないよう空白を入れて写した）`<br>P31: exit 2・`CNF-006 docs/QUALITY_GATES.md:1: active の QLT-008 に gate-proofs の証明行（｜ QLT-008 ｜）が無い` |
| CNF-007 | P28: Core のディレクトリに入れ子の .swiftlint.yml を置く<br>P29: SourceKit が要る規則（statement_position）を有効にする（静的バイナリが黙って飛ばす） | `make check` | P28: exit 2・`CNF-007 Sources/NeNeGambitCore/.swiftlint.yml:1: ゲートが読まない場所の検査設定（入れ子の設定は道具が勝手に拾う）`<br>P29: exit 2・`lint: 有効にした規則が実行されていない（CNF-007）` |
| CNF-008 | P32: Issue 番号の無い作業メモ（TODO）を書く | `make check` | P32: exit 2・`CNF-008 Sources/NeNeGambitCore/Square.swift:1: TODO / FIXME の直後に (#Issue番号) が無い` |
| CNF-009 | P23: target の警告設定を treatAllWarnings(as: .warning) にして未使用の定数を置く（ビルドは警告で通る）<br>P33: 許可リストに無い外部パッケージを manifest に書く（解決に行かせないため狭い検査で） | `make check`<br>`make conformance` | P23: exit 2・`CNF-009 Package.swift:8: target NeNeGambitCore に .treatAllWarnings(as: .error) が無い`<br>P33: exit 2・`CNF-009 Package.swift:7: 許可リストに無い外部パッケージ` |
| CNF-010 | P02: Terminal が正本に無い Core への依存を宣言する（循環は作らない） | `make check` | P02: exit 2・`CNF-010 Package.swift:17: target NeNeGambitTerminal の依存が正本と違う（余分: NeNeGambitCore / 不足: なし）` |
| CNF-011 | P03: Core が Foundation を import する<br>P22: テストで XCTest を import する | `make check` | P03: exit 2・`CNF-011 Sources/NeNeGambitCore/Probe.swift:1: NeNeGambitCore は Foundation を import できない`<br>P22: exit 2・`CNF-011 Tests/NeNeGambitCoreTests/ProbeTests.swift:1: NeNeGambitCoreTests は XCTest を import できない` |
| CNF-012 | P04: Engine が using: の無い Int.random を呼ぶ<br>P05: Core のテストが CommandLine.arguments を読む（テストにも禁止がかかる） | `make check` | P04: exit 2・`CNF-012 Sources/NeNeGambitEngine/Pick.swift:7: random(...) は using: で乱数源を受け取る`<br>P05: exit 2・`CNF-012 Tests/NeNeGambitCoreTests/ProbeTests.swift:3: 時刻・乱数・環境・プロセス状態は合成ルートだけが読む` |
| CNF-013 | P07: switch に default: を書く<br>P08: switch に case let other: を書く（default とも case _ とも書かない全捕捉） | `make check` | P07: exit 2・`CNF-013 Sources/NeNeGambitCore/Side.swift:15: 全捕捉（default / @unknown default / case _ / case let x）は網羅性検査を殺す`<br>P08: exit 2・`CNF-013 Sources/NeNeGambitCore/Side.swift:15: 全捕捉（default / @unknown default / case _ / case let x）は網羅性検査を殺す` |
| CNF-014 | P14: Core で unsafeBitCast を使う | `make check` | P14: exit 2・`CNF-014 Sources/NeNeGambitCore/Probe.swift:3: unsafe 系の API は unsafe=allowed の target だけ` |
| CNF-015 | P39: Decodable を使う | `make check` | P39: exit 2・`CNF-015 Sources/NeNeGambitCore/Probe.swift:2: Codable / Decodable / Encodable は使えない` |
| CNF-016 | P09: 公開の格納 var を置く | `make check` | P09: exit 2・`CNF-016 Sources/NeNeGambitRender/Cell.swift:3: public の格納 var は外から変更できる（let か private(set) にする）` |
| CNF-017 | P40: Core で print を呼ぶ | `make check` | P40: exit 2・`CNF-017 Sources/NeNeGambitCore/Probe.swift:5: print / readLine / exit 等は合成ルートだけ` |
| CNF-018 | P35: CI に make check 以外の run（swift build）を足す<br>P36: CI のアクションをタグで指す<br>P45: CI のジョブに draft を飛ばす if: を書く（スキップは成功として数えられる） | `make check` | P35: exit 2・`CNF-018 .github/workflows/ci.yml:30: CI で許す run はツールチェーン導入とゲートの 1 行だけ: swift build`<br>P36: exit 2・`CNF-018 .github/workflows/ci.yml:19: アクションを commit SHA で固定していない: actions/checkout@v7`<br>P45: exit 2・`CNF-018 .github/workflows/ci.yml:16: if: は使えない（スキップされた必須 check は成功として数えられる）` |
| CNF-019 | P11: 製品コードに throws を書く | `make check` | P11: exit 2・`CNF-019 Sources/NeNeGambitCore/Probe.swift:4: 期待される失敗は閉じた結果型で返す（throw / try / catch は使えない）` |
| CNF-020 | P12: Any を使う | `make check` | P12: exit 2・`CNF-020 Sources/NeNeGambitCore/Probe.swift:4: Any / AnyObject / AnyHashable / AnyClass は使えない` |
| GIT-003 | P41: 形の合わないコミット（--no-verify でフックを迂回）<br>P42: 形の合わないコミットをフック付きで作ろうとする（フックが拒む） | `git -c user.name=proof -c user.email=proof@example.invalid commit --allow-empty -m update stuff`<br>`make check` | P41: exit 2・`GIT-003 1969017: 件名は `<type>(<scope>): <日本語の説明> (#<issue番号>)` の形（type は feat / fix / docs / refactor / test / build / ci`<br>P42: exit 1・`GIT-003 件名は `<type>(<scope>): <日本語の説明> (#<issue番号>)` の形（type は feat / fix / docs / refactor / test / build / ci / chore）` |
| GIT-004 | P43: `main` へ PR を経ずに直接 push する（`git push origin HEAD:main`）・同じ commit を `--force` で push する | git push（使い捨ての clone から・2026-10-25） | P43: 2 回とも `remote rejected`・`GH013: Repository rule violations found for refs/heads/main`・`Changes must be made through a pull request.`・`Required status check "check" is expected.`。push 後も `refs/heads/main` は `57a01c0` のまま |
<!-- proofs:active:end -->

**復帰の確認**: 対照 P00（足場だけ・違反なし）と P00b（足場を置かない作業木そのまま）が、どちらも `make check` で exit 0（`make check: 緑`）。
各証明は対照と同じ足場に違反を 1 つ足しただけなので、「仕込みを戻すと緑」は P00 が示す。

**除外側の確認**: P00 の足場では、合成ルート `nene-gambit` が `ContinuousClock.now`・`SystemRandomNumberGenerator`・`CommandLine.arguments`・`print` を使い、
`NeNeGambitTerminal`（`unsafe=allowed`）が `withUnsafeMutablePointer` と `ioctl` を使っている。それでも `make check` は緑で、
同じ書き方を Core・Engine・テストに置くと P04・P05・P14・P40 で落ちる。

### 1-b. 証明の一覧

<!-- proofs:list:start -->
| # | 規則 | 仕込んだ違反 | 実行したタスク | 結果 | 判定 |
| --- | --- | --- | --- | --- | --- |
| P00 | 対照 | 対照: 足場だけ（違反なし）。合成ルートが時計・乱数・CommandLine・print を使い、Terminal が withUnsafe を使う | `make check` | exit 0 | pass |
| P00b | 対照 | 対照: 足場を置かない作業木そのまま | `make check` | exit 0 | pass |
| P01 | ARC-002 | Core が宣言していない Engine を import する | `make check` | exit 2 | pass |
| P02 | ARC-002, CNF-010, QLT-006 | Terminal が正本に無い Core への依存を宣言する（循環は作らない） | `make check` | exit 2 | pass |
| P03 | ARC-003, CNF-011, SWF-014, QLT-006 | Core が Foundation を import する | `make check` | exit 2 | pass |
| P04 | ARC-007, CNF-012 | Engine が using: の無い Int.random を呼ぶ | `make check` | exit 2 | pass |
| P05 | ARC-007, CNF-012 | Core のテストが CommandLine.arguments を読む（テストにも禁止がかかる） | `make check` | exit 2 | pass |
| P06 | SWF-002 | enum に case を足し、switch を直さない | `make check` | exit 2 | pass |
| P07 | SWF-002, CNF-013 | switch に default: を書く | `make check` | exit 2 | pass |
| P08 | CNF-013 | switch に case let other: を書く（default とも case _ とも書かない全捕捉） | `make check` | exit 2 | pass |
| P09 | SWF-003, CNF-016 | 公開の格納 var を置く | `make check` | exit 2 | pass |
| P10 | SWF-004 | 強制アンラップを書く | `make check` | exit 2 | pass |
| P11 | SWF-005, CNF-019 | 製品コードに throws を書く | `make check` | exit 2 | pass |
| P12 | SWF-006, CNF-020 | Any を使う | `make check` | exit 2 | pass |
| P13 | SWF-006 | 要素 3 つのタプルを返す | `make check` | exit 2 | pass |
| P14 | SWF-009, CNF-014 | Core で unsafeBitCast を使う | `make check` | exit 2 | pass |
| P15 | SWF-010, CNF-001 | 型を BoardHelper と名付ける | `make check` | exit 2 | pass |
| P16 | SWF-011, CNF-002 | 1 ファイルに最上位の型を 2 つ置く | `make check` | exit 2 | pass |
| P17 | SWF-012 | 引数 5 つの関数を書く | `make check` | exit 2 | pass |
| P18 | SWF-012 | 循環的複雑度 11 の関数を書く（SwiftLint は if 11 個を 11 と数える） | `make check` | exit 2 | pass |
| P19 | SWF-015, CNF-003 | waiver 無しの swiftlint:disable:next で強制アンラップを抑制する | `make check` | exit 2 | pass |
| P20 | SWF-015, CNF-003 | @diagnose で非推奨の警告を消す | `make check` | exit 2 | pass |
| P21 | SWF-015, CNF-004 | 期限切れの active な waiver を台帳と索引に置く | `make check` | exit 2 | pass |
| P22 | SWF-016, CNF-011 | テストで XCTest を import する | `make check` | exit 2 | pass |
| P23 | QLT-002, CNF-009 | target の警告設定を treatAllWarnings(as: .warning) にして未使用の定数を置く（ビルドは警告で通る） | `make check` | exit 2 | pass |
| P24 | QLT-002 | 未使用のローカル定数を置く（警告がエラーになること） | `make check` | exit 2 | pass |
| P25 | QLT-003, CNF-005 | 名前に baseline を含むファイルを置く | `make check` | exit 2 | pass |
| P26 | QLT-003, CNF-005 | .gitignore で Sources を検査から隠す | `make check` | exit 2 | pass |
| P27 | QLT-004 | インデントを 2 桁にする | `make check` | exit 2 | pass |
| P28 | QLT-004, CNF-007 | Core のディレクトリに入れ子の .swiftlint.yml を置く | `make check` | exit 2 | pass |
| P29 | CNF-007, QLT-007 | SourceKit が要る規則（statement_position）を有効にする（静的バイナリが黙って飛ばす） | `make check` | exit 2 | pass |
| P30 | CNF-006 | 未定義の規則 ID を文書に書く | `make check` | exit 2 | pass |
| P31 | CNF-006 | 証明行の無い規則をマトリクスで active にする（本文も合わせて書き換える） | `make check` | exit 2 | pass |
| P32 | CNF-008 | Issue 番号の無い作業メモ（TODO）を書く | `make check` | exit 2 | pass |
| P33 | QLT-011, CNF-009 | 許可リストに無い外部パッケージを manifest に書く（解決に行かせないため狭い検査で） | `make conformance` | exit 2 | pass |
| P34 | QLT-011 | SwiftLint の lock の SHA-256 を 1 文字変え、道具を入れ直させる | `make tools` | exit 2 | pass |
| P35 | QLT-001, CNF-018, QLT-005 | CI に make check 以外の run（swift build）を足す | `make check` | exit 2 | pass |
| P36 | CNF-018 | CI のアクションをタグで指す | `make check` | exit 2 | pass |
| P45 | QLT-012, CNF-018 | CI のジョブに draft を飛ばす if: を書く（スキップは成功として数えられる） | `make check` | exit 2 | pass |
| P37 | QLT-001 | .swift-version を実際の版と違う 6.4.0 にする | `make check` | exit 2 | pass |
| P38 | QLT-007 | 規約検査の CNF-013 の検出を壊す（検査器の単体テストが落ちること） | `make check` | exit 2 | pass |
| P39 | CNF-015 | Decodable を使う | `make check` | exit 2 | pass |
| P40 | CNF-017, ARC-006 | Core で print を呼ぶ | `make check` | exit 2 | pass |
| P41 | GIT-003 | 形の合わないコミット（--no-verify でフックを迂回） | `make check` | exit 2 | pass |
| P44 | SWF-002, SWF-004, SWF-005, SWF-006, SWF-012, SWF-015 | 有効にした SwiftLint の 16 規則それぞれの違反を 1 ファイルに置く（設定の全規則が実際に発火すること） | `make check` | exit 2 | pass |
| P42 | GIT-003 | 形の合わないコミットをフック付きで作ろうとする（フックが拒む） | `git -c user.name=proof -c user.email=proof@example.invalid commit --allow-empty -m update stuff` | exit 1 | pass |
| P43 | GIT-004 | `main` へ PR を経ずに直接 push する（`git push origin HEAD:main`）・同じ commit を `--force` で push する | git push（使い捨ての clone から・2026-10-25） | 第 1-a 節 | pass |
| P46 | QLT-012 | draft の PR に push する（CI のジョブはスキップでなく失敗し、PR はマージできない） | GitHub Actions run 40171721542（PR #2・head bb025a7・2026-10-25） | 第 1-a 節 | pass |
<!-- proofs:list:end -->

---

## 2. 出力の抜粋（実行結果からの引用）

各証明の出力から、期待した行（`evidence`）と末尾の数行（`tail`）を [gate-proofs.json](gate-proofs.json) に残している。代表例:

```text
P07  CNF-013 Sources/NeNeGambitCore/Side.swift:15: 全捕捉（default / @unknown default / case _ / case let x）は網羅性検査を殺す
P01  error: no such module 'NeNeGambitEngine'
P06  error: switch must be exhaustive
P24  error: initialization of immutable value 'unused' was never used
P29  lint: 有効にした規則が実行されていない（CNF-007）
P34  sha256sum: WARNING: 1 computed checksum did NOT match
P37  tools: swift は 6.4.0 が要るが、起動できない: The swift version file `.swift-version` requires toolchain version 6.4.0, which is not installed.
P42  GIT-003 件名は `<type>(<scope>): <日本語の説明> (#<issue番号>)` の形（type は feat / fix / docs / refactor / test / build / ci / chore）
```

---

## 3. 事故から生まれた検査・証明の取り直し

Issue #1 の Phase 1〜2 で、証明の手順が次を見つけた。

| 見つけたこと | 対処 |
| --- | --- |
| CNF-006 が文書をリポジトリのルートではなくカレントディレクトリから探していた（検査器の単体テストで発覚） | `ctx.root` から探すよう直し、単体テストをゲートに結線した（QLT-007） |
| 規約検査の除外リストに作業用の非公開ディレクトリ名を書いていた | ファイルの列挙を `git ls-files --cached --others --exclude-standard` に変えた。そのせいで `.gitignore` 1 行でソースを隠せるようになったので、`.gitignore` の中身を生成物の置き場だけに縛った（CNF-005・P26） |
| `eng/install-tools.sh` は swift が起動できないとき何も言わずに exit 1 していた（P37 の初回） | swiftly が `.swift-version` の版を要求して起動を拒んだ理由を 1 行出すようにした |
| P12 の初回: `[Int: Any]` の static 定数が Swift 6 の並行性で先にビルドエラーになった | `Any` を返す関数に変えて、CNF-020 で落ちることを取り直した |
| P18 の初回: if 10 個の関数が通った。SwiftLint は分岐 10 個を複雑度 10 と数える（`+1` しない） | if を 11 個にして取り直した（`currently complexity is 11`）。CODING_RULES SWF-012 に数え方を書いた |
| P31 の初回: 文書の置換が CNF 表の行（`| QLT-008 | planned |` を含む）にも当たった | マトリクスの行だけに当たる置換に直した |
| 🔴 PR #2: push の直後に Ready にしたら、`ready_for_review` が push の反映より先に届いて古い head（b54cd58）で CI が走り、新しい head（d2d5adf）には draft 時の**スキップ**だけが付いた。GitHub はスキップされた必須 check を成功として数えるので、フルゲートを通っていない head が `CLEAN`（マージ可能）になった（2026-10-25 07:05 UTC・run 40171485758 / 40171486988） | すぐ Draft に戻した。ジョブの `if:` をやめ、draft なら**失敗する**最初の step（`eng/ci-require-ready.sh`）に替えた。CNF-018 が `if:` を拒否する（P45） |
| P44 の初回: swift-format の `FileScopedDeclarationPrivacy` が SwiftLint の `private_over_fileprivate` と同じことを見ていた | SwiftLint 側を外して不採用表に理由を書いた（P-04: 同じ規則を 2 か所に置かない） |

---

## 4. リポジトリ設定（ruleset）

| 設定 | 値 | 確認日 |
| --- | --- | --- |
| ruleset | `main`（id 25812149）・enforcement `active`・対象 `~DEFAULT_BRANCH`・bypass なし | 2026-10-25 |
| PR 必須 | `pull_request`（承認 0 件・未解決スレッドで止める） | 2026-10-25 |
| 必須 check | `required_status_checks`: context `check`・integration 15368（GitHub Actions） | 2026-10-25 |
| strict up-to-date | `strict_required_status_checks_policy: true` | 2026-10-25 |
| force push / ブランチ削除の禁止 | `non_fast_forward`・`deletion` | 2026-10-25 |
| squash のみ | ruleset の `allowed_merge_methods: ["squash"]`＋リポジトリ設定（merge commit・rebase は無効、squash の件名は PR タイトル） | 2026-10-25 |

読み戻しは `gh api repos/hideyukiMORI/nene-gambit/rulesets/25812149`。直接 push と force push が拒否されることは P43（第 1 節）で見た。
ブランチの削除の拒否は試していない（既定ブランチの削除は GitHub 自体も拒むので、試しても ruleset の証明にならない）。

🔴 **設定していないものを「必須になっている」と書かない。** 設定したら `gh api` で読み戻して記録する。

---

## 5. 環境依存の確認（QLT-013）

（まだ無い。端末の表示の確認は Phase 3 の手順 3 で Windows Terminal を使って記録する）
