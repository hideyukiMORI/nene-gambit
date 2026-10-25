# NeNe Gambit

端末の中で、白と黒の手作りのチェス AI が延々と指し続けるスクリーンセーバー（Swift 製・WSL2 の Ubuntu＋Windows Terminal 向け）。
1 局が終わると次の局を始め、`q` を押すまで続く。チェスの AI（合法手生成・評価関数・アルファベータ探索）は外部エンジンを使わず一から書く。

🚧 **まだ画面に出るものは無い。** いま動くのはチェスの中核（`NeNeGambitCore`: 合法手の生成・指し手の適用・FEN の読み書き・
チェックメイトとステイルメイトの判定）だけで、perft は Chess Programming Wiki の 6 局面すべてで深さ 5 まで公表値と一致する（`make check` で毎回確かめる）。
次は、施主に画面の見せ方を確かめてから、ランダムに指す 2 者の自動対局を端末に出す。

## 開発

```bash
make bootstrap   # clone 直後に 1 回（コミットフックと SwiftLint の静的バイナリ）
make check       # 唯一の完了定義（ローカルと CI で同じ）
```

- Swift 6.4.1（`.swift-version`）・SwiftPM のみ・製品の外部依存は 0
- 規約の入口は [CLAUDE.md](CLAUDE.md)（日本語）と [AGENTS.md](AGENTS.md)（英語）。いま機械が何を守っているかの正本は [docs/QUALITY_GATES.md](docs/QUALITY_GATES.md)

## ライセンス

MIT（[LICENSE](LICENSE)）
