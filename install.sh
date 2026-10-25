#!/bin/bash
# NeNe Gambit installer: downloads the latest release (or NENE_GAMBIT_VERSION), verifies it against SHA256SUMS, then installs it.
#
#   curl -fsSL https://raw.githubusercontent.com/hideyukiMORI/nene-gambit/main/install.sh | bash
#
# Installs into ~/.local/bin (override with NENE_GAMBIT_PREFIX). If verification fails, nothing is installed.
set -euo pipefail

repo="hideyukiMORI/nene-gambit"
prefix="${NENE_GAMBIT_PREFIX:-$HOME/.local/bin}"

fail() {
    echo "nene-gambit install: $1" >&2
    exit 1
}

[ "$(uname -s)" = "Linux" ] && [ "$(uname -m)" = "x86_64" ] || fail "only Linux on x86_64 is supported (this is $(uname -s) $(uname -m))"
for tool in curl sha256sum tar install; do
    command -v "$tool" > /dev/null || fail "$tool is required"
done

version="${NENE_GAMBIT_VERSION:-}"
if [ -z "$version" ]; then
    latest="$(curl -fsSLI -o /dev/null -w '%{url_effective}' "https://github.com/$repo/releases/latest")"
    version="${latest##*/v}"
fi
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || fail "could not determine the version: $version"

name="nene-gambit-$version-linux-x86_64"
base="https://github.com/$repo/releases/download/v$version"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

echo "nene-gambit install: downloading v$version"
curl -fsSL -o "$work/$name.tar.gz" "$base/$name.tar.gz"
curl -fsSL -o "$work/SHA256SUMS" "$base/SHA256SUMS"
(cd "$work" && sha256sum --check --quiet SHA256SUMS) || fail "checksum does not match SHA256SUMS; nothing was installed"
tar -xzf "$work/$name.tar.gz" -C "$work"
install -Dm755 "$work/$name/nene-gambit" "$prefix/nene-gambit"

echo "nene-gambit install: installed $prefix/nene-gambit ($("$prefix/nene-gambit" --version))"
case ":$PATH:" in
    *":$prefix:"*) echo "nene-gambit install: run nene-gambit (q quits, g switches piece glyphs, t switches themes)" ;;
    *) echo "nene-gambit install: $prefix is not on your PATH; open a new terminal or run export PATH=\"$prefix:\$PATH\"" ;;
esac
