#!/usr/bin/env python3
"""Phase 2: ゲートの negative proof（QLT-007）。docs/quality/gate-proofs.json に結果を書く。

作業木を一時ディレクトリへ複製し、証明ごとに最小の違反を 1 つだけ仕込んで `make check`（またはそれより狭いタスク）を回す。
「意図した規則 ID（または道具の規則名）で落ちること」を出力から確かめる。仕込まない複製（対照）では `make check` が
exit 0 になることも確かめる。作業木そのものには触れない。

違反を仕込むには Swift のソースが要るので、どの証明も同じ「足場」（依存グラフの正本どおりの 5 target・
規則に沿った最小のソース）を置いてから 1 か所だけ壊す。足場は証明のための一時物で、作業木には入れない。

    python3 eng/prove-gates.py [--only P01 P02 ...]
"""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
from dataclasses import dataclass, field
from pathlib import Path
from typing import Callable

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "docs" / "quality" / "gate-proofs.json"
SETTINGS = 'swiftSettings: [.treatAllWarnings(as: .error), .enableUpcomingFeature("ExistentialAny")]'

TARGETS = {
    "NeNeGambitCore": ("target", ""),
    "NeNeGambitEngine": ("target", '"NeNeGambitCore"'),
    "NeNeGambitRender": ("target", '"NeNeGambitCore", "NeNeGambitEngine"'),
    "NeNeGambitTerminal": ("target", '"NeNeGambitRender"'),
    "nene-gambit": ("executableTarget",
                    '"NeNeGambitCore", "NeNeGambitEngine", "NeNeGambitRender", "NeNeGambitTerminal"'),
}

SOURCES = {
    "Sources/NeNeGambitCore/Square.swift": """\
/// 盤の升。証明用の最小の型。
public struct Square: Hashable, Sendable {
    public let index: Int

    private init(index: Int) {
        self.index = index
    }

    /// 0〜63 の升を作る。範囲外なら nil。
    public static func make(_ index: Int) -> Square? {
        (0..<64).contains(index) ? Square(index: index) : nil
    }
}
""",
    "Sources/NeNeGambitEngine/Pick.swift": """\
import NeNeGambitCore

/// 注入された乱数源から升を選ぶ。証明用の最小の型。
public enum Pick {
    /// 0..<count から 1 つ選ぶ。
    public static func square(count: Int, using generator: inout some RandomNumberGenerator) -> Square? {
        Square.make(Int.random(in: 0..<count, using: &generator))
    }
}
""",
    "Sources/NeNeGambitRender/Cell.swift": """\
/// 文字セル 1 つ。証明用の最小の型。
public struct Cell: Sendable {
    public let glyph: Character

    /// セルを作る。
    public init(glyph: Character) {
        self.glyph = glyph
    }
}
""",
    "Sources/NeNeGambitTerminal/Screen.swift": """\
import Glibc

/// 端末の大きさを読む。unsafe 系 API を許す区画の証明用。
public enum Screen {
    /// 端末の桁数。読めなければ 0。
    public static func columns() -> Int {
        var size = winsize()
        let status = withUnsafeMutablePointer(to: &size) { pointer in
            ioctl(STDOUT_FILENO, UInt(TIOCGWINSZ), pointer)
        }
        return status == 0 ? Int(size.ws_col) : 0
    }
}
""",
    "Sources/nene-gambit/main.swift": """\
import NeNeGambitCore
import NeNeGambitEngine
import NeNeGambitTerminal

let start = ContinuousClock.now
var generator = SystemRandomNumberGenerator()
let square = Pick.square(count: 64, using: &generator)
let arguments = CommandLine.arguments.count
print(square?.index ?? -1, Screen.columns(), arguments, ContinuousClock.now - start >= .zero)
""",
}


def package_swift(extra: dict[str, str] | None = None) -> str:
    """足場の Package.swift。extra は target 名 → 置き換える `.target(...)` の本文。"""
    lines = []
    for name, (kind, deps) in TARGETS.items():
        default = f'.{kind}(name: "{name}", dependencies: [{deps}], {SETTINGS})'
        lines.append((extra or {}).get(name, default))
    body = ",\n        ".join(lines)
    return (
        "// swift-tools-version: 6.2\n\nimport PackageDescription\n\nlet package = Package(\n"
        '    name: "NeNeGambit",\n    targets: [\n        ' + body + "\n    ],\n"
        "    swiftLanguageModes: [.v6]\n)\n"
    )


@dataclass
class Proof:
    id: str
    rules: list[str]
    violation: str
    mutate: Callable[[Path], None]
    expect: str  # 出力に現れるべき正規表現（意図した規則 ID か道具の規則名）
    command: list[str] = field(default_factory=lambda: ["make", "check"])
    scaffold: bool = True
    expect_exit_zero: bool = False
    expect_all: list[str] = field(default_factory=list)  # 追加で、出力にすべて現れるべき正規表現


def write(root: Path, rel: str, text: str) -> None:
    path = root / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def edit(root: Path, rel: str, old: str, new: str) -> None:
    path = root / rel
    text = path.read_text(encoding="utf-8")
    if old not in text:
        raise ValueError(f"{rel} に {old!r} が無い")
    path.write_text(text.replace(old, new, 1), encoding="utf-8")


def core_file(name: str, text: str) -> Callable[[Path], None]:
    return lambda root: write(root, f"Sources/NeNeGambitCore/{name}", text)


def nothing(root: Path) -> None:
    del root


def git_commit(root: Path, message: str, no_verify: bool) -> None:
    write(root, "docs/todo/note.md", "# 証明用\n")
    subprocess.run(["git", "-C", str(root), "add", "-A"], check=True, capture_output=True)
    cmd = ["git", "-C", str(root), "-c", "user.name=proof", "-c", "user.email=proof@example.invalid", "commit", "-q", "-m", message]
    if no_verify:
        cmd.insert(cmd.index("commit") + 1, "--no-verify")
    subprocess.run(cmd, check=True, capture_output=True)


SWITCH = """\
/// 色。証明用。
enum Side {
    case white
    case black
    case none
}

/// 色の値。
func value(of side: Side) -> Int {
    switch side {
    case .white:
        return 1
    case .black:
        return -1
    BODY
    }
}
"""

LINT_RULES = ["cyclomatic_complexity", "function_body_length", "function_parameter_count", "nesting", "file_length",
              "type_body_length", "force_unwrapping", "implicitly_unwrapped_optional", "discouraged_optional_boolean",
              "discouraged_optional_collection", "force_cast", "force_try", "large_tuple", "fallthrough", "superfluous_disable_command", "blanket_disable_command"]


def every_lint_rule() -> str:
    """有効にした SwiftLint の 16 規則それぞれの最小の違反を 1 ファイルに並べる（コンパイルは通る形）。"""
    lint = "swift" + "lint"
    body = ["/// 証明用。", "enum Probe {"]
    body += [f"    static let value{k} = {k}" for k in range(410)]
    body += ["", "    /// 証明用。", "    static func grade(_ v: Int) -> Int {"]
    body += [f"        if v == {k} {{\n            return {k}\n        }}" for k in range(11)]
    body += ["        return -1", "    }", "", "    /// 証明用。", "    static func long() -> Int {", "        var total = 0"]
    body += [f"        total += {k}" for k in range(61)]
    body += ["        return total", "    }", "",
             "    /// 証明用。", "    static func sum(_ a: Int, _ b: Int, _ c: Int, _ d: Int, _ e: Int) -> Int {", "        a + b + c + d + e", "    }", "",
             "    /// 証明用。", "    static func unwrap(_ v: Int?) -> Int {", "        v!", "    }", "",
             "    static let flag: Bool? = nil", "    static let list: [Int]? = nil", "",
             "    /// 証明用。", "    static func cast(_ v: Int) -> Int {", "        (v as Any) as! Int", "    }", "",
             "    /// 証明用。", "    static func risky() throws -> Int {", "        1", "    }", "",
             "    /// 証明用。", "    static func force() -> Int {", "        try! risky()", "    }", "",
             "    /// 証明用。", "    static func triple() -> (Int, Int, Int) {", "        (1, 2, 3)", "    }", "",
             "    /// 証明用。", "    static func fall(_ v: Int) -> Int {", "        var result = 0", "        switch v {", "        case 0:",
             "            result = 1", "            fallthrough", "        case 1:", "            result += 1", "        default:",
             "            result = 0", "        }", "        return result", "    }", "",
             "    /// 証明用。", "    struct Middle {", "        /// 証明用。", "        struct Inner {}", "    }", "", "    /// 証明用。",
             "    struct Holder {", "        var cache: Int!", "    }", "}", "", "let hidden = 1", "",
             f"// {lint}:disable:next force_cast", "let plain = hidden + 1", "", f"// {lint}:disable force_unwrapping", ""]
    return "\n".join(body)


PROOFS: list[Proof] = [
    Proof("P00", [], "対照: 足場だけ（違反なし）。合成ルートが時計・乱数・CommandLine・print を使い、Terminal が withUnsafe を使う",
          nothing, r"make check: 緑", expect_exit_zero=True),
    Proof("P00b", [], "対照: 足場を置かない作業木そのまま", nothing, r"make check: 緑", scaffold=False, expect_exit_zero=True),
    Proof("P01", ["ARC-002"], "Core が宣言していない Engine を import する",
          core_file("Probe.swift", "import NeNeGambitEngine\n\n/// 証明用。\nenum Probe {}\n"), r"no such module 'NeNeGambitEngine'"),
    Proof("P02", ["ARC-002", "CNF-010", "QLT-006"], "Terminal が正本に無い Core への依存を宣言する（循環は作らない）",
          lambda r: write(r, "Package.swift", package_swift({"NeNeGambitTerminal":
              f'.target(name: "NeNeGambitTerminal", dependencies: ["NeNeGambitRender", "NeNeGambitCore"], {SETTINGS})'})),
          r"^CNF-010 Package\.swift"),
    Proof("P03", ["ARC-003", "CNF-011", "SWF-014", "QLT-006"], "Core が Foundation を import する",
          core_file("Probe.swift", "import Foundation\n\n/// 証明用。\nenum Probe {}\n"), r"^CNF-011 Sources/NeNeGambitCore/Probe\.swift"),
    Proof("P04", ["ARC-007", "CNF-012"], "Engine が using: の無い Int.random を呼ぶ",
          lambda r: edit(r, "Sources/NeNeGambitEngine/Pick.swift", "Int.random(in: 0..<count, using: &generator)",
                         "Int.random(in: 0..<count)"),
          r"^CNF-012 Sources/NeNeGambitEngine/Pick\.swift"),
    Proof("P05", ["ARC-007", "CNF-012"], "Core のテストが CommandLine.arguments を読む（テストにも禁止がかかる）",
          lambda r: write(r, "Tests/NeNeGambitCoreTests/ProbeTests.swift",
                          "/// 証明用。\nenum ProbeTests {\n    static let count = CommandLine.arguments.count\n}\n"),
          r"^CNF-012 Tests/NeNeGambitCoreTests/ProbeTests\.swift"),
    Proof("P06", ["SWF-002"], "enum に case を足し、switch を直さない",
          core_file("Side.swift", SWITCH.replace("    BODY\n", "")), r"error: switch must be exhaustive"),
    Proof("P07", ["SWF-002", "CNF-013"], "switch に default: を書く",
          core_file("Side.swift", SWITCH.replace("BODY", "default:\n        return 0")), r"^CNF-013 Sources/NeNeGambitCore/Side\.swift"),
    Proof("P08", ["CNF-013"], "switch に case let other: を書く（default とも case _ とも書かない全捕捉）",
          core_file("Side.swift", SWITCH.replace("BODY", "case let other:\n        return other == .none ? 0 : 2")),
          r"^CNF-013 Sources/NeNeGambitCore/Side\.swift"),
    Proof("P09", ["SWF-003", "CNF-016"], "公開の格納 var を置く",
          lambda r: edit(r, "Sources/NeNeGambitRender/Cell.swift", "public let glyph", "public var glyph"),
          r"^CNF-016 Sources/NeNeGambitRender/Cell\.swift"),
    Proof("P10", ["SWF-004"], "強制アンラップを書く",
          lambda r: edit(r, "Sources/nene-gambit/main.swift", "square?.index ?? -1", "square!.index"),
          r"\(force_unwrapping\)"),
    Proof("P11", ["SWF-005", "CNF-019"], "製品コードに throws を書く",
          core_file("Probe.swift", "/// 証明用。\nenum Probe {\n    /// 証明用。\n    static func load() throws -> Int { 1 }\n}\n"),
          r"^CNF-019 Sources/NeNeGambitCore/Probe\.swift"),
    Proof("P12", ["SWF-006", "CNF-020"], "Any を使う",
          core_file("Probe.swift", "/// 証明用。\nenum Probe {\n    /// 証明用。\n    static func box() -> Any { 1 }\n}\n"),
          r"^CNF-020 Sources/NeNeGambitCore/Probe\.swift"),
    Proof("P13", ["SWF-006"], "要素 3 つのタプルを返す",
          core_file("Probe.swift", "/// 証明用。\nenum Probe {\n    /// 証明用。\n    static func triple() -> (Int, Int, Int) { (1, 2, 3) }\n}\n"),
          r"\(large_tuple\)"),
    Proof("P14", ["SWF-009", "CNF-014"], "Core で unsafeBitCast を使う",
          core_file("Probe.swift", "/// 証明用。\nenum Probe {\n    static let square = unsafeBitCast(99, to: Square.self)\n}\n"),
          r"^CNF-014 Sources/NeNeGambitCore/Probe\.swift"),
    Proof("P15", ["SWF-010", "CNF-001"], "型を BoardHelper と名付ける",
          core_file("BoardHelper.swift", "/// 証明用。\nenum BoardHelper {}\n"), r"^CNF-001 Sources/NeNeGambitCore/BoardHelper\.swift"),
    Proof("P16", ["SWF-011", "CNF-002"], "1 ファイルに最上位の型を 2 つ置く",
          core_file("Probe.swift", "/// 証明用。\nenum Probe {}\n\n/// 証明用。\nenum Other {}\n"), r"^CNF-002 Sources/NeNeGambitCore/Probe\.swift"),
    Proof("P17", ["SWF-012"], "引数 5 つの関数を書く",
          core_file("Probe.swift", "/// 証明用。\nenum Probe {\n    /// 証明用。\n    static func sum(_ a: Int, _ b: Int, _ c: Int, _ d: Int, _ e: Int) -> Int {\n        a + b + c + d + e\n    }\n}\n"),
          r"\(function_parameter_count\)"),
    Proof("P18", ["SWF-012"], "循環的複雑度 11 の関数を書く（SwiftLint は if 11 個を 11 と数える）",
          core_file("Probe.swift", "/// 証明用。\nenum Probe {\n    /// 証明用。\n    static func grade(_ v: Int) -> Int {\n"
                    + "".join(f"        if v == {k} {{\n            return {k}\n        }}\n" for k in range(11))
                    + "        return -1\n    }\n}\n"),
          r"\(cyclomatic_complexity\)"),
    Proof("P19", ["SWF-015", "CNF-003"], "waiver 無しの swiftlint:disable:next で強制アンラップを抑制する",
          lambda r: edit(r, "Sources/nene-gambit/main.swift", "print(square?.index ?? -1,",
                         "// " + "swift" + "lint:disable:next force_unwrapping\nprint(square!.index,"),
          r"^CNF-003 Sources/nene-gambit/main\.swift"),
    Proof("P20", ["SWF-015", "CNF-003"], "@diagnose で非推奨の警告を消す",
          core_file("Probe.swift", "/// 証明用。\nenum Probe {\n    @available(*, deprecated)\n    static func old() -> Int { 1 }\n\n"
                    "    @diagnose(DeprecatedDeclaration, as: ignored)\n    static func use() -> Int { old() }\n}\n"),
          r"^CNF-003 Sources/NeNeGambitCore/Probe\.swift"),
    Proof("P21", ["SWF-015", "CNF-004"], "期限切れの active な waiver を台帳と索引に置く",
          lambda r: (write(r, "docs/waivers/WVR-0001-proof.md",
                           "# WVR-0001: 証明用\n\n- Status: active\n- Rule: `SWF-004`\n- Issue: #1\n- Owner: hide\n"
                           "- Created: 2026-10-01\n- Expires: 2026-10-24\n- Scope: `Sources/nene-gambit/main.swift`\n"),
                     edit(r, "docs/waivers/README.md", "| — | — | — | 有効な waiver は無い | — |",
                          "| WVR-0001 | SWF-004 | `Sources/nene-gambit/main.swift` | 証明用 | 2026-10-24 |")),
          r"^CNF-004 docs/waivers/WVR-0001"),
    Proof("P22", ["SWF-016", "CNF-011"], "テストで XCTest を import する",
          lambda r: write(r, "Tests/NeNeGambitCoreTests/ProbeTests.swift", "import XCTest\n\n/// 証明用。\nenum ProbeTests {}\n"),
          r"^CNF-011 Tests/NeNeGambitCoreTests/ProbeTests\.swift"),
    Proof("P23", ["QLT-002", "CNF-009"], "target の警告設定を treatAllWarnings(as: .warning) にして未使用の定数を置く（ビルドは警告で通る）",
          lambda r: (write(r, "Package.swift", package_swift({"NeNeGambitCore":
              '.target(name: "NeNeGambitCore", swiftSettings: [.treatAllWarnings(as: .warning), .enableUpcomingFeature("ExistentialAny")])'})),
                     write(r, "Sources/NeNeGambitCore/Probe.swift",
                           "/// 証明用。\nenum Probe {\n    /// 証明用。\n    static func run() -> Int {\n        let unused = 1\n        return 2\n    }\n}\n")),
          r"^CNF-009 Package\.swift"),
    Proof("P24", ["QLT-002"], "未使用のローカル定数を置く（警告がエラーになること）",
          core_file("Probe.swift", "/// 証明用。\nenum Probe {\n    /// 証明用。\n    static func run() -> Int {\n        let unused = 1\n        return 2\n    }\n}\n"),
          r"error: initialization of immutable value 'unused' was never used"),
    Proof("P25", ["QLT-003", "CNF-005"], "名前に baseline を含むファイルを置く",
          lambda r: write(r, "swiftlint-" + "base" + "line.json", "[]\n"), r"^CNF-005 swiftlint-"),
    Proof("P26", ["QLT-003", "CNF-005"], ".gitignore で Sources を検査から隠す",
          lambda r: (edit(r, ".gitignore", ".build/\n", ".build/\nSources/NeNeGambitCore/Hidden.swift\n"),
                     write(r, "Sources/NeNeGambitCore/Hidden.swift", "let x = 1\n")),
          r"^CNF-005 \.gitignore"),
    Proof("P27", ["QLT-004"], "インデントを 2 桁にする", lambda r: edit(r, "Sources/NeNeGambitRender/Cell.swift",
          "    public let glyph", "  public let glyph"), r"\[Indentation\]"),
    Proof("P28", ["QLT-004", "CNF-007"], "Core のディレクトリに入れ子の .swiftlint.yml を置く",
          lambda r: write(r, "Sources/NeNeGambitCore/.swiftlint.yml", "only_rules:\n  - force_cast # SWF-004\n"),
          r"^CNF-007 Sources/NeNeGambitCore/\.swiftlint\.yml"),
    Proof("P29", ["CNF-007", "QLT-007"], "SourceKit が要る規則（statement_position）を有効にする（静的バイナリが黙って飛ばす）",
          lambda r: edit(r, ".swiftlint.yml", "  - blanket_disable_command # SWF-015\n",
                         "  - blanket_disable_command # SWF-015\n  - statement_position # SWF-012\n"),
          r"有効にした規則が実行されていない（CNF-007）"),
    Proof("P30", ["CNF-006"], "未定義の規則 ID を文書に書く",
          lambda r: edit(r, "docs/todo/current.md", "## 次の 1 手", "ARC-0" + "99 を参照する。\n\n## 次の 1 手"),
          r"^CNF-006 docs/todo/current\.md"),
    Proof("P31", ["CNF-006"], "証明行の無い規則をマトリクスで active にする（本文も合わせて書き換える）",
          lambda r: (edit(r, "docs/QUALITY_GATES.md", "\n| QLT-008 | planned |", "\n| QLT-008 | active |"),
                     edit(r, "docs/QUALITY_GATES.md", "- 機械強制: **planned**（レビュー事項。テスト target", "- 機械強制: **active**（レビュー事項。テスト target")),
          r"^CNF-006 docs/QUALITY_GATES\.md:1: active の QLT-008"),
    Proof("P32", ["CNF-008"], "Issue 番号の無い作業メモ（" + "TO" + "DO）を書く",
          lambda r: edit(r, "Sources/NeNeGambitCore/Square.swift", "/// 盤の升。", "// " + "TO" + "DO あとで直す\n/// 盤の升。"),
          r"^CNF-008 Sources/NeNeGambitCore/Square\.swift"),
    Proof("P33", ["QLT-011", "CNF-009"], "許可リストに無い外部パッケージを manifest に書く（解決に行かせないため狭い検査で）",
          lambda r: edit(r, "Package.swift", "    targets: [",
                         '    dependencies: [.package(url: "https://github.com/example/chess.git", exact: "1.0.0")],\n    targets: ['),
          r"^CNF-009 Package\.swift:\d+: 許可リストに無い外部パッケージ", command=["make", "conformance"]),
    Proof("P34", ["QLT-011"], "SwiftLint の lock の SHA-256 を 1 文字変え、道具を入れ直させる",
          lambda r: (edit(r, "eng/swiftlint.lock", "sha256=c", "sha256=d"), (r / ".tools").unlink()),
          r"(FAILED|did NOT match)", command=["make", "tools"]),
    Proof("P35", ["QLT-001", "CNF-018", "QLT-005"], "CI に make check 以外の run（swift build）を足す",
          lambda r: edit(r, ".github/workflows/ci.yml", "      - run: eng/install-swift.sh\n",
                         "      - run: eng/install-swift.sh\n      - run: swift build\n"),
          r"^CNF-018 \.github/workflows/ci\.yml"),
    Proof("P36", ["CNF-018"], "CI のアクションをタグで指す",
          lambda r: edit(r, ".github/workflows/ci.yml", "actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1", "actions/checkout@v7"),
          r"^CNF-018 \.github/workflows/ci\.yml"),
    Proof("P45", ["QLT-012", "CNF-018"], "CI のジョブに draft を飛ばす if: を書く（スキップは成功として数えられる）",
          lambda r: edit(r, ".github/workflows/ci.yml", "    runs-on:", "    if: ${{ !github.event.pull_request.draft }}\n    runs-on:"),
          r"^CNF-018 \.github/workflows/ci\.yml:\d+: if: は使えない"),
    Proof("P37", ["QLT-001"], ".swift-version を実際の版と違う 6.4.0 にする",
          lambda r: write(r, ".swift-version", "6.4.0\n"), r"tools: swift は 6\.4\.0 が要る"),
    Proof("P38", ["QLT-007"], "規約検査の CNF-013 の検出を壊す（検査器の単体テストが落ちること）",
          lambda r: edit(r, "eng/conformance.py", 'r"^\\s*(?:default\\s*:', 'r"^\\s*(?:NEVERMATCH\\s*:'),
          r"FAILED \(failures="),
    Proof("P39", ["CNF-015"], "Decodable を使う",
          core_file("Probe.swift", "/// 証明用。\nstruct Probe: Decodable {\n    let index: Int\n}\n"), r"^CNF-015 Sources/NeNeGambitCore/Probe\.swift"),
    Proof("P40", ["CNF-017", "ARC-006"], "Core で print を呼ぶ",
          core_file("Probe.swift", "/// 証明用。\nenum Probe {\n    /// 証明用。\n    static func show() {\n        print(1)\n    }\n}\n"),
          r"^CNF-017 Sources/NeNeGambitCore/Probe\.swift"),
    Proof("P41", ["GIT-003"], "形の合わないコミット（--no-verify でフックを迂回）",
          lambda r: git_commit(r, "update stuff", no_verify=True), r"GIT-003 [0-9a-f]{7}: 件名は"),
    Proof("P44", ["SWF-002", "SWF-004", "SWF-005", "SWF-006", "SWF-012", "SWF-015"],
          "有効にした SwiftLint の 16 規則それぞれの違反を 1 ファイルに置く（設定の全規則が実際に発火すること）",
          core_file("Probe.swift", every_lint_rule()), r"\((?:" + "|".join(LINT_RULES) + r")\)$",
          expect_all=[rf"\({rule}\)" for rule in LINT_RULES]),
    Proof("P42", ["GIT-003"], "形の合わないコミットをフック付きで作ろうとする（フックが拒む）",
          lambda r: subprocess.run(["git", "-C", str(r), "config", "core.hooksPath", ".githooks"], check=True),
          r"GIT-003 件名は",
          command=["git", "-c", "user.name=proof", "-c", "user.email=proof@example.invalid", "commit", "--allow-empty", "-m", "update stuff"],
          scaffold=False),
]


def copy_tree(dest: Path) -> None:
    def ignore(directory: str, names: list[str]) -> set[str]:
        return {n for n in names if Path(directory) == ROOT and n in (".build", ".tools", ".handoff", ".swiftpm")} | {
            n for n in names if n == "__pycache__"}

    shutil.copytree(ROOT, dest, ignore=ignore, symlinks=True)
    os.symlink(ROOT / ".tools", dest / ".tools")


def scaffold(root: Path) -> None:
    write(root, "Package.swift", package_swift())
    for rel, text in SOURCES.items():
        write(root, rel, text)


def run_proof(proof: Proof) -> dict:
    with tempfile.TemporaryDirectory(prefix=f"gambit-proof-{proof.id}-") as tmp:
        root = Path(tmp) / "repo"
        copy_tree(root)
        if proof.scaffold:
            scaffold(root)
        proof.mutate(root)
        if proof.scaffold:
            # 生成した manifest の行の長さは証明の対象ではないので、Package.swift だけ整形してから回す
            subprocess.run(["swift-format", "format", "-i", "--configuration", ".swift-format", "Package.swift"],
                           cwd=root, capture_output=True)
        p = subprocess.run(proof.command, cwd=root, capture_output=True, text=True, timeout=1800,
                           env=dict(os.environ, NO_COLOR="1"))
        output = (p.stdout + p.stderr).replace(str(root) + "/", "")
        matched = [ln.strip() for ln in output.splitlines() if re.search(proof.expect, ln.strip())]
        missing = [pat for pat in proof.expect_all if not re.search(pat, output)]
        ok = (p.returncode == 0) if proof.expect_exit_zero else (p.returncode != 0 and bool(matched) and not missing)
        return {
            "id": proof.id,
            "rules": proof.rules,
            "violation": proof.violation,
            "command": " ".join(proof.command),
            "exit": p.returncode,
            "expected": proof.expect,
            "verdict": "pass" if ok else "FAIL",
            "evidence": matched[:3] if not proof.expect_all else matched[:len(proof.expect_all)],
            "missing": missing,
            "tail": [ln for ln in output.strip().splitlines()[-8:]],
        }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--only", nargs="*")
    args = parser.parse_args()
    results = []
    for proof in PROOFS:
        if args.only and proof.id not in args.only:
            continue
        r = run_proof(proof)
        print(f"{r['id']:5} {r['verdict']:4} exit={r['exit']:<3} {r['violation']}", flush=True)
        for line in (r["evidence"] or r["tail"])[:2]:
            print(f"        {line}", flush=True)
        if r["missing"]:
            print(f"        出力に現れなかった: {', '.join(r['missing'])}", flush=True)
            for line in r["tail"]:
                print(f"        | {line}", flush=True)
        results.append(r)
    if not args.only:
        doc = {
            "measured_on": subprocess.run(["date", "+%Y-%m-%d"], capture_output=True, text=True).stdout.strip(),
            "head": subprocess.run(["git", "-C", str(ROOT), "rev-parse", "--short", "HEAD"], capture_output=True, text=True).stdout.strip(),
            "note": "verdict=pass は「意図した規則で落ちた」（対照は exit 0）。作業木の未コミットの変更も複製に含む。",
            "results": results,
        }
        OUT.write_text(json.dumps(doc, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print(f"wrote {OUT.relative_to(ROOT)}")
    return 0 if all(r["verdict"] == "pass" for r in results) else 1


if __name__ == "__main__":
    sys.exit(main())
