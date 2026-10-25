# NeNe Gambit

> *Four snarky AIs play chess in your terminal. Forever. Press `q` to make them stop.*

4 人のキャストが、一から手作りしたチェス AI でひたすら対局を続ける、ターミナル用のスクリーンセーバーです。指しながら、英語で減らず口を叩き合います。
1 局が終われば、すぐ次の対局が始まります。あなたは何もしなくて大丈夫。眺めて、ときどきニヤッとしてください。

[![release](https://img.shields.io/github/v/release/hideyukiMORI/nene-gambit)](https://github.com/hideyukiMORI/nene-gambit/releases/latest)
![platform](https://img.shields.io/badge/platform-Linux%20x86__64%20%2F%20WSL2-555)
![license](https://img.shields.io/badge/license-MIT-555)

[English](README.md) · **日本語**

![NEON テーマで GRANNY.DLL が NULL_PTR を詰ませた画面](docs/images/checkmate-neon.png)

<sub>実機の画面です。WSL2 の Windows Terminal で v0.1.0 を動かしました（`--seed 1985`・120×30）。
28 手目でおばあちゃんがチェックメイト。NULL_PTR は「わざと負けた」と言い張っています。</sub>

---

## インストール

```bash
curl -fsSL https://raw.githubusercontent.com/hideyukiMORI/nene-gambit/main/install.sh | bash
```

最新の [Release](https://github.com/hideyukiMORI/nene-gambit/releases/latest) をダウンロードし、`SHA256SUMS` でチェックサムを確かめてから `~/.local/bin/nene-gambit` にインストールします。
チェックサムが合わなければ、何もインストールしません。スクリプトは [install.sh](install.sh) の 45 行ほどなので、実行する前に目を通しても 1 分かかりません。

- 動作環境: x86_64 の Linux で glibc 2.35 以上（Ubuntu 22.04 以降）。WSL2 の Ubuntu と Windows Terminal で動作を確認しています
- Swift のインストールは不要です。標準ライブラリを静的リンクした単一の実行ファイルで、動的に依存するのは libc・libm・libstdc++・libgcc_s だけです
- アンインストールは `rm ~/.local/bin/nene-gambit` だけです

<details>
<summary>手動でインストールする</summary>

```bash
v=0.1.0
curl -fsSL -O https://github.com/hideyukiMORI/nene-gambit/releases/download/v$v/nene-gambit-$v-linux-x86_64.tar.gz \
           -O https://github.com/hideyukiMORI/nene-gambit/releases/download/v$v/SHA256SUMS
sha256sum --check SHA256SUMS
tar -xzf nene-gambit-$v-linux-x86_64.tar.gz
./nene-gambit-$v-linux-x86_64/nene-gambit
```
</details>

## 遊び方（というより、眺め方）

```bash
nene-gambit
```

| キー | |
| --- | --- |
| `q` | 終了（Ctrl+C でも終われます。どう終わっても、ターミナルは元の状態に戻ります） |
| `g` | 駒の表示を切り替える（アルファベット `K Q R B N P` ⇔ 駒記号 `♚♛♜♝♞♟`） |
| `t` | 次のカラーテーマへ（全 12 種類） |

| 起動オプション | |
| --- | --- |
| `--theme NAME` | `NEON` `PHOSPHOR` `AMBER` `SYNTHWAVE` `GLACIER` `BLOODMOON` `VAPOR` `MONO` `TOXIC` `GILDED` `ABYSS` `PAPER` |
| `--glyphs symbols` | 駒記号で始める |
| `--seed N` | 同じシードなら、同じ対局と**同じ会話**が再現されます |
| `--move-interval SEC` | 1 手ごとの間隔（既定は 1.0 秒） |
| `--result-pause SEC` | 終局後に結果を表示しておく時間（既定は 3 秒） |
| `--version` | バージョンを表示して終了 |

ターミナルの大きさは 67×15 以上（駒記号なら 75×15 以上）が必要です。**100×30 以上あれば大きな盤**（1 マス 3 行）で表示されます。
小さすぎるときは、盤の代わりに必要な大きさを 1 行で教えてくれます。

### 画面の見かた

![NEON テーマで王手がかかった場面](docs/images/check-neon.png)

- **盤**: 直前の手の 2 マスが `[ ]` で囲まれます。詰まされたキングのマスは暗い色に沈みます
- **MATCH**: 何局目か、白と黒それぞれのキャスト、手番と手数
- **SCORE**: これまでの白の勝ち・黒の勝ち・引き分けの数を棒グラフで
- **LOG**: 直近の棋譜（SAN 表記）。次に指す側の欄でカーソル `▌` が点滅します
- **RESULT**: 終局すると現れます。勝敗と理由（チェックメイト・ステイルメイト・同一局面 3 回・50 手ルール・駒不足）、次の対局までのカウントダウン
- **COMMS**: 盤の下の 2 行。キャストの最新の発言で、明るいほうが新しい発言です

## キャスト

対局のたびに、4 人のうち 2 人がランダムに選ばれて白と黒に座ります。強さも口の悪さも、人それぞれです。

| | 指し方 | ひとこと |
| --- | --- | --- |
| **VEX.EXE** `>:)` | 自信過剰な攻め屋。相手のキングに駒を寄せるのが好き。3 手先まで読みます | *"Initializing arrogance... 100%."* |
| **MORT.SH** `x_x` | 穏やかな葬儀屋。キングの守りとポーンの形を大切にします。3 手先まで読みます | *"Another game. Sixty-four tiny graves."* |
| **NULL_PTR** `o_O` | 計画ゼロの混沌。1 手先しか読まず、良さそうな手から大きく外れた手も指します。タダで取れる駒は取ります | *"I have no plan. Soon, neither will you."* |
| **GRANNY.DLL** `^_^` | 優しくて容赦のない、根に持つおばあちゃん。いちばん深く、4 手先まで読みます | *"Shall we, dear? I've baked cookies for your king's wake."* |

セリフは 1 人 50 本。駒を取る・取られる・王手・成り・キャスリング・アンパッサン・静かな局面・勝ち・負け・引き分けなど、場面ごとに用意しています。
いくつか紹介すると:

> **VEX.EXE**（クイーンを取られて）*"That queen was a decoy. I'll explain later. Never."*<br>
> **MORT.SH**（駒を取られて）*"He knew the risks. He was a pawn."*<br>
> **NULL_PTR**（負けて）*"Segmentation fault (core dumped). Emotionally."*<br>
> **GRANNY.DLL**（負けて）*"Well done, dear. I'll be telling everyone you cheated."*

残りの 196 本は、眺めながら集めてみてください。

## 12 のテーマ

`t` キーで切り替わります。`NEON`（既定）・`PHOSPHOR`（緑の CRT）・`AMBER`（琥珀色の CRT）・`SYNTHWAVE`・`GLACIER`・`BLOODMOON`・`VAPOR`・`MONO`・`TOXIC`・`GILDED`・`ABYSS`・`PAPER`（唯一の明るいテーマ）。

| SYNTHWAVE | PHOSPHOR |
| --- | --- |
| ![SYNTHWAVE](docs/images/synthwave.png) | ![PHOSPHOR](docs/images/phosphor.png) |
| **BLOODMOON** | **PAPER** |
| ![BLOODMOON](docs/images/bloodmoon.png) | ![PAPER](docs/images/paper.png) |

どのテーマでも、文字と背景のコントラスト比は 4.5:1 以上。白と黒の駒は、色合いだけでなく明るさでも見分けられます（2.2:1 以上）。
これは人が目で確かめているのではなく、実際に描いた画面のセルの色から、テストが毎回計算しています（後述）。

---

## ソースコードのこだわり（読み物）

NeNe Gambit は「チェスのスクリーンセーバー」の顔をしていますが、同時に**ルールを機械に守らせる実験**でもあります。
Issue #1 から v0.1.0 の公開まで、すべて 2026-10-25 の 1 日の出来事です。以下はその中で実際に起きたことで、数字はすべてリポジトリの記録（ADR・テスト・証明）に残っています。

### 1. チェスはすべて一から書いた

外部のチェスエンジンもライブラリも使っていません。製品の外部依存はゼロです。
合法手の生成が正しいかどうかは、**perft**（ある局面から深さ N までに起こりうる手順の数）を、Chess Programming Wiki で公表されている値と突き合わせて確かめています。

- 6 つの局面（初期局面や有名な "Kiwipete" など）を、すべて**深さ 5 まで、合計 480,105,445 局面**数えて、1 つも狂いません
- これを `make check` のたびに毎回実行します。release 構成で約 34 秒（CI では約 45 秒）。デバッグ構成では遅すぎるため、その判断を [ADR 0004](docs/adr/0004-perft-runs-in-release-configuration.md) に残しました
- 盤は Swift 6.4 の `InlineArray<64, Piece?>` です。値型なので、手を指すと**新しい局面が作られ、元の局面は変わりません**。「手を戻す」処理そのものが要りません（[ADR 0003](docs/adr/0003-board-and-move-representation.md)）

### 2. 最初の AI はランダムで、ほとんど引き分けだった

最初のキャストは、合法手の中からランダムに選んで指していました。施主が 1 時間ほど流して眺めた感想はこうです:

> ほとんど引き分けになるよね。キングとあと何か数個のコマだけになると、ずっと逃げ続けて終わらないみたい。

ランダムに指すと、駒得はできても詰ませ方を知らないので、50 手ルールまでキングを追い回してしまいます。
そこで評価関数とアルファベータ探索を入れ、勝っている側には **mop-up**（相手のキングを盤の端へ追い込み、自分のキングを近づける）を加えました。その結果、計測した 16 局のうち **15 局がチェックメイトで決着**しました。
キング＋クイーン対キング、キング＋ルーク対キングを 50 手ルールより前に詰ませられることは、テストで毎回確かめています（[ADR 0009](docs/adr/0009-evaluation-search-and-personas.md)）。

### 3. 時計を見ない AI

探索は「何秒考えるか」ではなく、「何手先まで、何局面まで読むか」で打ち切ります。
盤・AI・描画のコードからは、現在時刻も乱数も環境変数も**読めません**。読もうとすると、自作の規約検査がビルドを落とします。乱数はシード付きの自前の SplitMix64 で、
キャストの組み合わせもセリフの選び方も、同じ乱数から決まります。だから `--seed 42` で起動すれば、何度でも同じ対局、同じ減らず口が再現されます。

### 4. ルールは「書く」ものではなく「守らせる」もの

このリポジトリには 69 個のルールがあり、それぞれに ID と「機械が守っているかどうか」の状態が付いています。
現在 **47 個が active**（破ると `make check` が落ちる）で、残りは「まだ機械が見ていない（planned）」か「機械では塞げない（不能）」と正直に書いてあります（[品質ゲート](docs/QUALITY_GATES.md)）。

たとえば、Swift の `switch` に `default:` を書くとビルドが落ちます。選択肢を増やしたのに分岐の直し忘れがあれば、コンパイラに気づいてほしいからです。
最初に Swift 6.4.1 の挙動を 56 通り実測したところ（[phase0-results.json](docs/quality/phase0-results.json)）、`default:` や `case _:` だけでなく
**`case let other:` も網羅性チェックをすり抜ける**こと、`@diagnose(..., as: ignored)` という属性を使うと**警告をエラーにする設定でも警告を黙らせられる**こと、
`Package.swift` の設定が**コマンドラインの `-warnings-as-errors` を上書きしてしまう**ことが分かりました。どれも規約検査で塞いでいます（[ADR 0001](docs/adr/0001-strictness-is-mechanically-enforced.md)）。

そして、検査は「実際に落ちるところを見るまで信用しない」。違反をわざと 1 つずつ仕込み、狙ったルールで落ちたことを **53 件**記録しています（[ゲート発火の証明](docs/quality/gate-proofs.md)）。

### 5. 自分で作った CI の穴に、自分で落ちた話

Draft の PR では重いゲートを回さないよう、CI のジョブを「スキップ」にしていました。ある日、push の直後に Ready にしたところ、
古いコミットで CI が走り、新しいコミットにはスキップだけが付きました。**GitHub はスキップを成功とみなし、ゲートを通っていない PR をマージできる状態にしてしまった**のです。
すぐに Draft に戻し、「Draft ならスキップではなく失敗させる」形に変え、ワークフローに `if:` を書くこと自体を規約検査で禁止しました。この顛末は、証明の記録の「事故から生まれた検査」に残っています。

### 6. ターミナルは必ず元に戻す

スクリーンセーバーが落ちて、ターミナルが壊れたまま残る。これだけは絶対に許せません。そこで:

- `q`・Ctrl+C・SIGTERM で終わっても、**SIGSEGV で落ちても**、ターミナルを元に戻してから終了します（シグナルハンドラでは、メモリを確保しない書き込みだけを使います）
- これを人の目ではなく、実行ファイルを**疑似端末の中で実際に動かして**確かめています（`make smoke`）。5 通りの終わり方と、ウィンドウを縮めたり戻したりしても落ちないことを毎回チェックします

### 7. 駒記号をマスの中央に置くまでの 3 往復

`♚` のような駒記号は、ターミナルによって 1 文字分の幅にも 2 文字分の幅にもなる厄介な文字です。

1. 最初は、起動時にターミナルへ「この文字を書いたら、カーソルは何文字分進んだ？」と問い合わせて、幅を測っていました
2. ところが施主の Windows Terminal のスクリーンショットを測ると、**ターミナルは「1 文字分」と答えるのに、実際には約 2 文字分の幅で描いていました**（フォントに駒記号がなく、代わりのフォントの字形が広いため）。
   問い合わせでは見分けられません。そこで駒記号のときはマスの幅を偶数にし、字形を中央の 2 文字分に置くようにしました
3. 次のスクリーンショットでは、駒の右側に暗い縦の帯が出ていました。2 文字目のセルに何も書いていなかったので、マスの色で塗られていなかったのです。施主の見立ては「背景色があってればいいのかな」。まさにそのとおりでした

アルファベット（既定）は幅が奇数のマスのちょうど中央に、駒記号は幅が偶数のマスの中央 2 文字分に収まります（[ADR 0010](docs/adr/0010-symbols-occupy-two-cells.md)・[ADR 0011](docs/adr/0011-paint-the-cell-beside-symbols.md)）。
罫線の枠も同じ方法で幅を測り、2 文字分で描くターミナルでは自動的に ASCII の枠（`+-|`）に切り替わります。

### 8. 色は目ではなく、計算で決める

12 テーマ × 11 色の組み合わせを、毎回目で確かめることはできません。そこでテストは、テーマごとに実際の画面を描き、**文字が入っているすべてのセル**について、文字色と背景色のコントラストを WCAG の式で計算します。
1 つでも 4.5:1 を下回れば、ビルドが落ちます。Windows Terminal で `COLORTERM` が設定されていないために 256 色に落ちていた問題も、施主のスクリーンショットの色（黄土色と暗い赤）から見つけました。

---

## 開発

```bash
make bootstrap           # clone 直後に 1 回（コミットフックと SwiftLint の静的バイナリ）
make check               # 唯一の完了の定義。ローカルと CI で同じ（ビルド・テスト・整形・lint・規約検査・perft・端末の smoke・コミットの形式）
make release TAG=v<版>   # 配布物を作る（検査に通ったものだけ）
```

- Swift 6.4.1（`.swift-version`）・SwiftPM のみ・製品の外部依存ゼロ。ソースは約 3,600 行、テストは約 900 行です
- 入口は [CLAUDE.md](CLAUDE.md)（日本語）と [AGENTS.md](AGENTS.md)（英語）。設計の判断は [ADR](docs/adr/README.md) に 12 本、要件と施主の決定は [REQUIREMENTS.md](docs/REQUIREMENTS.md) にあります
- 人も AI も、同じルール・同じゲートのもとで書いています。このリポジトリのコードの大半は Claude Code が書き、施主がデザインと決定、実機での確認を担いました

## ライセンス

MIT（[LICENSE](LICENSE)）
