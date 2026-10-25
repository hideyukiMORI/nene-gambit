# NeNe Gambit

> *Four snarky AIs play chess in your terminal. Forever. Press `q` to make them stop.*

端末の中で、4 名のキャストが一から書いたチェス AI で延々と指し続け、指しながら英語で減らず口を叩くスクリーンセーバー。
1 局終われば次の局。あなたは何もしなくていい。眺めて、たまにニヤッとするだけ。

[![release](https://img.shields.io/github/v/release/hideyukiMORI/nene-gambit)](https://github.com/hideyukiMORI/nene-gambit/releases/latest)
![platform](https://img.shields.io/badge/platform-Linux%20x86__64%20%2F%20WSL2-555)
![license](https://img.shields.io/badge/license-MIT-555)

```text
 ▌NENE//GAMBIT  │  GAME 001  │  SEED 0x00000000000007C1  │  24BIT

                                                             ┌─[ MATCH ]─────────────────────────┐
 8                  B     [ ]                          R     │ GAME      001                     │
                                                             │ WHITE     GRANNY.DLL              │
                                                             │ BLACK     NULL_PTR                │
 7    R      N                   [K]            B      P     │ TURN      WHITE :: MOVE 17        │
                                                             ├─[ SCORE ]─────────────────────────┤
                                                             │ W  ▕░░░░░░░░░░░░░░░░░░░░▏  00     │
 6    P             P                           N      N     │ B  ▕░░░░░░░░░░░░░░░░░░░░▏  00     │
                                                             │ =  ▕░░░░░░░░░░░░░░░░░░░░▏  00     │
                                                             ├─[ LOG ]───────────────────────────┤
 5                         P                           Q     │ 05.  f4       Ng6                 │
                                                             │ 06.  e3       e5                  │
                                                             │ 07.  d4       f6                  │
 4                                B      P                   │ 08.  gxf6     e4                  │
                                                             │ 09.  fxg7     Qh4+                │
                                                             │ 10.  Kf1      Bxg7                │
 3                                P      N                   │ 11.  Bxe4     c6                  │
                                                             │ 12.  Nf3      Qh5                 │
                                                             │ 13.  Nc4      Nh6                 │
 2    P      P      P                                  P     │ 14.  Nxd6+    Kd8                 │
                                                             │ 15.  d5       Ra7                 │
                                                             │ 16.  Nxb7+    Ke7                 │
 1    R             B      Q             K             R     │ 17.  ▌                            │
                                                             └───────────────────────────────────┘
      a      b      c      d      e      f      g      h
▌ W  GRANNY.DLL ^_^  Check. Shall I call someone? A priest, perhaps?
▌ W  GRANNY.DLL ^_^  Your king looks chilly, sweetie. Let me show him out.
 [q] QUIT   [g] GLYPHS: LETTERS   [t] THEME: NEON   │   LAST Ke7  d8 > e7
```

<sub>↑ v0.1.0 の実行ファイルを 100×30 の疑似端末で動かし、画面をそのまま写したもの（`--seed 1985`・色は省略）。
おばあちゃんが混沌の王を追い回している。実際の画面は 24 ビットの色とネオンの枠で描かれる。</sub>

---

## 入れる

```bash
curl -fsSL https://raw.githubusercontent.com/hideyukiMORI/nene-gambit/main/install.sh | bash
```

最新の [Release](https://github.com/hideyukiMORI/nene-gambit/releases/latest) を落とし、`SHA256SUMS` で照合してから `~/.local/bin/nene-gambit` に置く。
照合に失敗したら何も置かない。中身は [install.sh](install.sh) の 45 行。読んでから流しても 1 分かからない。

- 動作環境: x86_64 の Linux で glibc 2.35 以上（Ubuntu 22.04 以降）。WSL2 の Ubuntu＋Windows Terminal で確かめている
- Swift は要らない（標準ライブラリを静的にリンクした 1 ファイル。動的に依存するのは libc・libm・libstdc++・libgcc_s だけ）
- 消すときは `rm ~/.local/bin/nene-gambit`

<details>
<summary>手で入れる</summary>

```bash
v=0.1.0
curl -fsSL -O https://github.com/hideyukiMORI/nene-gambit/releases/download/v$v/nene-gambit-$v-linux-x86_64.tar.gz \
           -O https://github.com/hideyukiMORI/nene-gambit/releases/download/v$v/SHA256SUMS
sha256sum --check SHA256SUMS
tar -xzf nene-gambit-$v-linux-x86_64.tar.gz
./nene-gambit-$v-linux-x86_64/nene-gambit
```
</details>

## 遊び方（というか、眺め方）

```bash
nene-gambit
```

| キー | |
| --- | --- |
| `q` | 終了（Ctrl+C でも。どんな終わり方でも端末は元に戻る） |
| `g` | 駒の字形を切り替える（英字 `K Q R B N P` ⇔ 駒記号 `♚♛♜♝♞♟`） |
| `t` | カラーテーマを次へ（12 種類） |

| 起動オプション | |
| --- | --- |
| `--theme NAME` | `NEON` `PHOSPHOR` `AMBER` `SYNTHWAVE` `GLACIER` `BLOODMOON` `VAPOR` `MONO` `TOXIC` `GILDED` `ABYSS` `PAPER` |
| `--glyphs symbols` | 駒記号で始める |
| `--seed N` | 同じシードなら、同じ対局と**同じ会話**になる |
| `--move-interval SEC` | 1 手の間隔（既定 1.0 秒） |
| `--result-pause SEC` | 終局後に結果を見せる時間（既定 3 秒） |
| `--version` | 版を出して終わる |

端末は 67×15 以上（駒記号なら 75×15）。**100×30 以上で大きな盤**（1 升 3 行）になる。小さすぎると、盤の代わりに必要な大きさを 1 行で教えてくれる。

### 画面の見かた

- **盤**: 直前の手の 2 升は `[ ]` で囲まれる。詰まされた王の升は暗い色に沈む
- **MATCH**: 何局目か・白黒それぞれのキャスト・手番と手数
- **SCORE**: 通算の白勝ち・黒勝ち・引き分けの棒グラフ
- **LOG**: 直近の棋譜（SAN）。カーソル `▌` が次に指す側の欄で点いている
- **RESULT**: 終局すると現れる。勝敗・理由（チェックメイト・ステイルメイト・同一局面 3 回・50 手ルール・駒不足）・次の局までの秒読み
- **COMMS**: 盤の下の 2 行。キャストの最新の発言。明るい方が新しい

## キャスト

局が始まるたびに、4 名から 2 名がランダムに選ばれて白と黒に座る。強さも、口の悪さも、それぞれ違う。

| | 指し方 | ひとこと |
| --- | --- | --- |
| **VEX.EXE** `>:)` | 自信過剰な攻め屋。駒を相手の王に寄せるのが好き。3 手先まで読む | *"Initializing arrogance... 100%."* |
| **MORT.SH** `x_x` | 穏やかな葬儀屋。王の囲いとポーンの形を大事にする。3 手先まで読む | *"Another game. Sixty-four tiny graves."* |
| **NULL_PTR** `o_O` | 計画ゼロの混沌。1 手先しか読まず、良さそうな手から大きくばらつく。只の駒は取る | *"I have no plan. Soon, neither will you."* |
| **GRANNY.DLL** `^_^` | 優しくて容赦ない、根に持つおばあちゃん。いちばん深く、4 手先まで読む | *"Shall we, dear? I've baked cookies for your king's wake."* |

セリフは 1 人 50 本、出来事（取る・取られる・王手・昇格・キャスリング・アンパッサン・静かな局面・勝ち・負け・引き分け…）ごとに用意してある。
いくつか抜き出すと:

> **VEX.EXE**（クイーンを取られて）*"That queen was a decoy. I'll explain later. Never."*<br>
> **MORT.SH**（駒を取られて）*"He knew the risks. He was a pawn."*<br>
> **NULL_PTR**（負けて）*"Segmentation fault (core dumped). Emotionally."*<br>
> **GRANNY.DLL**（負けて）*"Well done, dear. I'll be telling everyone you cheated."*

残りの 196 本は、眺めて集めてほしい。

## 12 のテーマ

`t` で巡る。`NEON`（既定）・`PHOSPHOR`（緑の CRT）・`AMBER`（琥珀の CRT）・`SYNTHWAVE`・`GLACIER`・`BLOODMOON`・`VAPOR`・`MONO`・`TOXIC`・`GILDED`・`ABYSS`・`PAPER`（唯一の明るいテーマ）。

どのテーマでも、画面の文字は背景に対してコントラスト 4.5:1 以上、白と黒の駒は色だけでなく明るさでも見分けられる（2.2:1 以上）。
これは人の目ではなく、描いた画面のセルの色から毎回テストが計算している（後述）。

---

## ソースコードのこだわり（読み物）

NeNe Gambit は「チェスのスクリーンセーバー」の顔をした、**規約を機械に守らせる実験**でもある。
Issue #1 から v0.1.0 の公開まで、すべて 2026-10-25 の 1 日の記録。以下はその中で実際に起きたこと。数字は全部、リポジトリの記録（ADR・テスト・証明）に残っている。

### 1. チェスは全部、一から書いた

外部のチェスエンジンもライブラリも使っていない。製品の外部依存は 0。
合法手の生成が正しいかは、**perft**（ある局面から深さ N までにあり得る手順の数）を、Chess Programming Wiki に公表されている値と突き合わせて確かめる。

- 6 局面（初期局面・有名な "Kiwipete" ほか）すべてを **深さ 5 まで、合計 480,105,445 局面**数えて、1 つも狂わない
- これを `make check` のたびに毎回やる。release 構成で約 34 秒（CI では約 45 秒）。デバッグ構成だと遅すぎるので、その判断は [ADR 0004](docs/adr/0004-perft-runs-in-release-configuration.md) に書いた
- 盤は Swift 6.4 の `InlineArray<64, Piece?>`。値型なので、手を指すと**新しい局面ができて元は変わらない**。「手を戻す」処理が要らない（[ADR 0003](docs/adr/0003-board-and-move-representation.md)）

### 2. 最初の AI はランダムで、ほとんど引き分けだった

最初の版のキャストは、合法手からランダムに選んでいた。施主が 1 時間ほど流して見て、一言:

> ほとんど引き分けになるよね。キングとあと何か数個のコマだけになると、ずっと逃げ続けて終わらないみたい。

ランダムな指し手は駒得しても詰ませ方を知らないので、50 手ルールまで王を追い回す。
そこで評価関数とアルファベータ探索を入れ、勝っている側には **mop-up**（相手の王を盤の端へ追い込み、自分の王を近づける）を足した。結果、計測した 16 局のうち **15 局がチェックメイトで決着**した。
王とクイーン対王、王とルーク対王を 50 手ルールより前に詰ませることは、テストが毎回確かめている（[ADR 0009](docs/adr/0009-evaluation-search-and-personas.md)）。

### 3. 時計を読まない AI

探索は「何秒考えるか」ではなく「何手先まで、何局面まで読むか」で打ち切る。
盤・AI・描画のコードは、現在時刻も乱数も環境変数も**読めない**。読んだら、自作の規約検査がビルドを落とす。乱数はシード付きの自前の SplitMix64 で、
キャストの選び方もセリフの選び方も同じ乱数から引く。だから `--seed 42` は、何度起動しても同じ対局、同じ減らず口になる。

### 4. 規約は「書く」ものではなく「守らせる」もの

このリポジトリには 69 個の規則があり、それぞれに ID と「機械が守っているか」の状態が付いている。
いま **47 個が active**（破ると `make check` が落ちる）で、残りは「まだ機械が見ていない（planned）」か「機械では塞げない（不能）」と正直に書いてある（[品質ゲート](docs/QUALITY_GATES.md)）。

たとえば、Swift の `switch` に `default:` を書くとビルドが落ちる。選択肢を増やしたのに分岐を直し忘れたら、コンパイラに気づいてほしいからだ。
最初に Swift 6.4.1 を 56 通り実測したとき（[phase0-results.json](docs/quality/phase0-results.json)）、`default:` と `case _:` だけでなく
**`case let other:` も網羅の検査をすり抜ける**こと、`@diagnose(..., as: ignored)` という属性で**警告をエラーにする設定の下でも警告を黙らせられる**こと、
`Package.swift` の設定が**コマンド行の `-warnings-as-errors` を上書きする**ことが分かった。どれも規約検査が塞いでいる（[ADR 0001](docs/adr/0001-strictness-is-mechanically-enforced.md)）。

そして、検査は「落ちるのを見るまで信用しない」。わざと違反を 1 つずつ仕込んで、意図した規則で落ちることを **53 件**記録している（[ゲート発火の証明](docs/quality/gate-proofs.md)）。

### 5. 自分の CI の穴を自分で踏んだ話

draft の PR では重いゲートを回さないよう、CI のジョブを「スキップ」にしていた。ある日、push の直後に Ready にしたら、
古い commit で CI が走り、新しい commit にはスキップだけが付き、**GitHub はスキップを成功と数えて、ゲートを通っていない PR をマージ可能にした**。
すぐ draft に戻し、「draft ならスキップではなく失敗させる」に変え、ワークフローに `if:` を書くこと自体を規約検査で禁止した。この顛末も証明の記録の「事故から生まれた検査」に残っている。

### 6. 端末は必ず元に戻す

スクリーンセーバーが落ちて端末が壊れたままになるのが、いちばん許せない。だから:

- `q`・Ctrl+C・SIGTERM で終わっても、**SIGSEGV で落ちても**、端末を元に戻してから死ぬ（シグナルハンドラはメモリを確保しない書き込みだけを使う）
- これを人の目ではなく、実行ファイルを**疑似端末の中で本当に動かして**確かめる（`make smoke`）。5 通りの終わり方と、端末を縮めたり戻したりしたときに落ちないことを毎回見ている

### 7. 駒記号が真ん中に来るまでの 3 往復

`♚` のような駒記号は、端末によって 1 桁にも 2 桁にもなる厄介な文字だ。

1. まず、起動時に端末に「この文字を書いたらカーソルは何桁進んだ？」と問い合わせて、幅を測るようにした
2. 施主の Windows Terminal のスクリーンショットを測ると、**端末は「1 桁」と答えるのに、実際には約 2 桁の幅で描いていた**（フォントに駒記号が無く、代わりのフォントの字形が広い）。
   問い合わせでは見分けられない。そこで駒記号のときは升を偶数桁にし、字形を中央の 2 桁に置いた
3. 次のスクリーンショットでは、駒の右に暗い縦の帯が出ていた。2 桁目のセルに何も書かなかったので、升の色で塗られていなかったのだ。施主の見立ては「背景色があってればいいのかな」。そのとおりだった

英字（既定）は奇数桁の升のちょうど真ん中に、駒記号は偶数桁の升の真ん中の 2 桁に入る（[ADR 0010](docs/adr/0010-symbols-occupy-two-cells.md)・[ADR 0011](docs/adr/0011-paint-the-cell-beside-symbols.md)）。
罫線の枠も同じ方法で幅を測り、2 桁で描く端末では自動で ASCII の枠（`+-|`）に落ちる。

### 8. 色は人の目ではなく計算で決める

12 テーマ × 11 色の組み合わせを、毎回目で確かめることはできない。テストは、テーマごとに実際の画面を描き、**文字の入っているすべてのセル**について、前景と背景のコントラストを WCAG の式で計算する。
1 つでも 4.5:1 を割ったらビルドが落ちる。Windows Terminal で `COLORTERM` が無いせいで 256 色に落ちていた件も、施主のスクリーンショットの色（黄土色と暗い赤）から見つけた。

---

## 開発

```bash
make bootstrap   # clone 直後に 1 回（コミットのフックと SwiftLint の静的バイナリ）
make check       # 唯一の完了の定義。ローカルと CI で同じ（ビルド・テスト・整形・lint・規約検査・perft・端末の smoke・コミットの形）
make release TAG=v<版>   # 配布物を作る（検査に通ったものだけ）
```

- Swift 6.4.1（`.swift-version`）・SwiftPM だけ・製品の外部依存 0。ソースは約 3,600 行、テストは約 900 行
- 入口は [CLAUDE.md](CLAUDE.md)（日本語）と [AGENTS.md](AGENTS.md)（英語）。設計の判断は [ADR](docs/adr/README.md) に 12 本、要件と施主の決定は [REQUIREMENTS.md](docs/REQUIREMENTS.md)
- 人も AI も、同じ規約・同じゲートで書く。このリポジトリのコードの大半は Claude Code が書き、施主がデザインと決定と実機の確認をした

## ライセンス

MIT（[LICENSE](LICENSE)）
