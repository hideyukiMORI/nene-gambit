# 単一ゲート（QLT-001）。ローカルと CI はどちらも `make check` だけを呼ぶ。
# 個別のターゲットは反復中の狭い検査として使ってよいが、完了の定義は `make check` だけである。
# 段は安い順に並べる（いちばん重い perft のテストは後ろ）。

BASE ?= origin/main
SWIFTLINT := .tools/swiftlint

.PHONY: check bootstrap tools build test smoke format lint conformance conformance-test commits

check: tools build format lint conformance conformance-test test smoke commits
	@echo "make check: 緑"

bootstrap: tools
	git config core.hooksPath .githooks

tools:
	eng/install-tools.sh

build:
	eng/swift-strict.sh swift build

# perft の深さ 5 はデバッグ構成で約 66 秒・release 構成で約 34 秒（ADR 0004）。テストは公開 API だけを使うので release で回せる
test:
	eng/swift-strict.sh swift test -c release

format:
	eng/swift-sources.sh | xargs -0 swift-format lint --strict --configuration .swift-format

lint:
	eng/lint.sh $(SWIFTLINT) --config .swiftlint.yml

# 実行ファイルを疑似端末で動かし、キーと終わり方ごとの端末の復元を見る（FR-08）。release 構成の実行ファイルを使う
smoke:
	eng/swift-strict.sh swift build -c release --product nene-gambit
	python3 eng/smoke-terminal.py .build/release/nene-gambit

conformance:
	python3 eng/conformance.py

conformance-test:
	python3 -m unittest discover -s eng/tests -q

commits:
	python3 eng/validate-commit-message.py --range "$(BASE)..HEAD"
