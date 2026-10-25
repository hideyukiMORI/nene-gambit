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

/// 24 ビットの色を使うか。`COLORTERM` が truecolor / 24bit を名乗るときだけ使い、それ以外は 256 色へ落とす。
let colors: ColorMode = {
    guard let raw = getenv("COLORTERM") else {
        return .palette256
    }
    return ["truecolor", "24bit"].contains(String(cString: raw)) ? .trueColor : .palette256
}()

var systemRandom = SystemRandomNumberGenerator()
var screensaver = Screensaver(options: options, colors: colors, seed: options.seed ?? systemRandom.next())
screensaver.run()
Console.close()
exit(0)
