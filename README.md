# NeNe Gambit

端末の中で、白と黒の手作りのチェス AI が延々と指し続けるスクリーンセーバー（Swift 製・WSL2 の Ubuntu＋Windows Terminal 向け）。
1 局が終わると次の局を始め、`q` を押すまで続く。チェスの AI（合法手生成・評価関数・アルファベータ探索）は外部エンジンを使わず一から書く。

🚧 **いまの AI は合法手からランダムに選ぶだけ。** 評価関数とアルファベータ探索はこれから。
指し手の生成は、Chess Programming Wiki の 6 局面すべてで perft の深さ 5 まで公表値と一致する（`make check` で毎回確かめる）。

## 使い方

```bash
swift build -c release
.build/release/nene-gambit                       # q で終了・g で駒の字形（英字 ⇔ 駒記号）を切り替え
.build/release/nene-gambit --glyphs symbols      # 駒記号で始める（端末によっては幅がずれる）
.build/release/nene-gambit --seed 42             # 同じシードなら同じ対局の列
.build/release/nene-gambit --move-interval 0.3 --result-pause 5
```

端末は 67×15 以上が要る。24 ビットの色は `COLORTERM=truecolor` のときだけ使い、それ以外は 256 色で描く。

## 開発

```bash
make bootstrap   # clone 直後に 1 回（コミットフックと SwiftLint の静的バイナリ）
make check       # 唯一の完了定義（ローカルと CI で同じ）
```

- Swift 6.4.1（`.swift-version`）・SwiftPM のみ・製品の外部依存は 0
- 規約の入口は [CLAUDE.md](CLAUDE.md)（日本語）と [AGENTS.md](AGENTS.md)（英語）。いま機械が何を守っているかの正本は [docs/QUALITY_GATES.md](docs/QUALITY_GATES.md)

## ライセンス

MIT（[LICENSE](LICENSE)）
