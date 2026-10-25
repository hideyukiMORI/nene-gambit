#!/bin/bash
# NeNe Gambit のインストーラ: 最新の Release（または NENE_GAMBIT_VERSION）を落とし、SHA256SUMS で照合してから置く。
#
#   curl -fsSL https://raw.githubusercontent.com/hideyukiMORI/nene-gambit/main/install.sh | bash
#
# 置き場所は ~/.local/bin（NENE_GAMBIT_PREFIX で変えられる）。照合に失敗したら何も置かない。
set -euo pipefail

repo="hideyukiMORI/nene-gambit"
prefix="${NENE_GAMBIT_PREFIX:-$HOME/.local/bin}"

fail() {
    echo "nene-gambit install: $1" >&2
    exit 1
}

[ "$(uname -s)" = "Linux" ] && [ "$(uname -m)" = "x86_64" ] || fail "Linux の x86_64 だけに対応している（いまは $(uname -s) $(uname -m)）"
for tool in curl sha256sum tar install; do
    command -v "$tool" > /dev/null || fail "$tool が要る"
done

version="${NENE_GAMBIT_VERSION:-}"
if [ -z "$version" ]; then
    latest="$(curl -fsSLI -o /dev/null -w '%{url_effective}' "https://github.com/$repo/releases/latest")"
    version="${latest##*/v}"
fi
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || fail "版を読めない: $version"

name="nene-gambit-$version-linux-x86_64"
base="https://github.com/$repo/releases/download/v$version"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

echo "nene-gambit install: v$version を落とす"
curl -fsSL -o "$work/$name.tar.gz" "$base/$name.tar.gz"
curl -fsSL -o "$work/SHA256SUMS" "$base/SHA256SUMS"
(cd "$work" && sha256sum --check --quiet SHA256SUMS) || fail "SHA256SUMS と合わない。置かずにやめる"
tar -xzf "$work/$name.tar.gz" -C "$work"
install -Dm755 "$work/$name/nene-gambit" "$prefix/nene-gambit"

echo "nene-gambit install: $prefix/nene-gambit に置いた（$("$prefix/nene-gambit" --version)）"
case ":$PATH:" in
    *":$prefix:"*) echo "nene-gambit install: nene-gambit で起動（q で終了・g で駒の字形・t でテーマ）" ;;
    *) echo "nene-gambit install: $prefix が PATH に無い。端末を開き直すか export PATH=\"$prefix:\$PATH\"" ;;
esac
