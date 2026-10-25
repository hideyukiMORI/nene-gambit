// 合成ルート（ARC-006）。時計・乱数・環境・起動オプションを読み（ARC-007）、Core・Engine・Render・Terminal を組み立てて
// 対局の列を回す。標準出力への直書きと終了コードを持つのはここだけで、出すのは起動できなかった理由 1 行だけ。

import Glibc
import NeNeGambitEngine
import NeNeGambitRender
import NeNeGambitTerminal

let options: LaunchOptions
switch LaunchOptions.parse(Array(CommandLine.arguments.dropFirst())) {
case .parsed(let parsed):
    options = parsed
case .rejected(let reason):
    Console.reportFailure("nene-gambit: \(reason)")
    exit(2)
}

switch Console.open() {
case .opened:
    break
case .notATerminal:
    Console.reportFailure("nene-gambit: 端末の中で起動してください（標準入力と標準出力が端末でない）")
    exit(1)
case .failed:
    Console.reportFailure("nene-gambit: 端末の設定を読み書きできない")
    exit(1)
}

/// 24 ビットの色を使うか。`COLORTERM` が truecolor / 24bit を名乗るか、Windows Terminal（`WT_SESSION` がある）なら使い、
/// それ以外は 256 色へ落とす。WSL の中では `COLORTERM` が無いことが多い（Issue #9）。
let colors: ColorMode = {
    if getenv("WT_SESSION") != nil {
        return .trueColor
    }
    guard let raw = getenv("COLORTERM") else {
        return .palette256
    }
    return ["truecolor", "24bit"].contains(String(cString: raw)) ? .trueColor : .palette256
}()

/// 罫線の文字が 1 桁で描かれる端末だけ罫線の枠を使い、それ以外（2 桁・答えが無い）は ASCII の枠へ落とす（ADR 0007）。
/// 駒記号が 2 桁で描かれる端末では、駒記号を 2 桁として配置する（ADR 0008）。
let traits = TerminalTraits(
    frame: Console.columnsAdvanced(by: "─") == 1 ? .boxDrawing : .ascii,
    wideSymbols: Console.columnsAdvanced(by: "\u{265A}") == 2,
    colors: colors)

var systemRandom = SystemRandomNumberGenerator()
let display = DisplayOptions(glyphs: options.glyphs, theme: options.theme, traits: traits)
var screensaver = Screensaver(options: options, display: display, seed: options.seed ?? systemRandom.next())
screensaver.run()
Console.close()
exit(0)
