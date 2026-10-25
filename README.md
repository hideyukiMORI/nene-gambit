# NeNe Gambit

端末の中で、白と黒の手作りのチェス AI が延々と指し続けるスクリーンセーバー（Swift 製・WSL2 の Ubuntu＋Windows Terminal 向け）。
1 局が終わると次の局を始め、`q` を押すまで続く。チェスの AI（合法手生成・評価関数・アルファベータ探索）は外部エンジンを使わず一から書く。

🚧 **まだ動くものは無い。** いまは製品コードを書く前に、規約とゲートの足場を作っている段階（Issue #1）。
最初の製品コードは「指し手生成と perft（画面なし）」で、perft が深さ 5 まで公表値と一致するまで画面には出さない。

## 開発

```bash
make bootstrap   # clone 直後に 1 回（コミットフックと SwiftLint の静的バイナリ）
make check       # 唯一の完了定義（ローカルと CI で同じ）
```

- Swift 6.4.1（`.swift-version`）・SwiftPM のみ・製品の外部依存は 0
- 規約の入口は [CLAUDE.md](CLAUDE.md)（日本語）と [AGENTS.md](AGENTS.md)（英語）。いま機械が何を守っているかの正本は [docs/QUALITY_GATES.md](docs/QUALITY_GATES.md)

## ライセンス

MIT（[LICENSE](LICENSE)）
