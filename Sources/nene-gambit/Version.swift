/// 製品の版。版の入力はここ 1 か所だけ（Phase 4・ADR 0012）。公開スクリプトはこの値と `--version` の出力とタグを突き合わせる。
enum Version {
    static let current = "0.1.0"
}
