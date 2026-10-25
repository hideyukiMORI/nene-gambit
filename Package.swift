// swift-tools-version: 6.2
// tools-version は manifest の API の版であり、ツールチェーンの版（.swift-version）ではない。
// 6.2 は treatAllWarnings(as:) を使える最小の版（ADR 0001）。
// target は承認された依存グラフ（docs/architecture/module-graph.txt）から、最初の責務が生じた PR で足す（Core は Issue #3・残りは Issue #5）。
// 各 target の swiftSettings は [.treatAllWarnings(as: .error), .enableUpcomingFeature("ExistentialAny")]（CNF-009）。

import PackageDescription

let package = Package(
    name: "NeNeGambit",
    targets: [
        .target(
            name: "NeNeGambitCore",
            swiftSettings: [.treatAllWarnings(as: .error), .enableUpcomingFeature("ExistentialAny")]
        ),
        .target(
            name: "NeNeGambitEngine",
            dependencies: ["NeNeGambitCore"],
            swiftSettings: [.treatAllWarnings(as: .error), .enableUpcomingFeature("ExistentialAny")]
        ),
        .target(
            name: "NeNeGambitRender",
            dependencies: ["NeNeGambitCore", "NeNeGambitEngine"],
            swiftSettings: [.treatAllWarnings(as: .error), .enableUpcomingFeature("ExistentialAny")]
        ),
        .target(
            name: "NeNeGambitTerminal",
            dependencies: ["NeNeGambitRender"],
            swiftSettings: [.treatAllWarnings(as: .error), .enableUpcomingFeature("ExistentialAny")]
        ),
        .executableTarget(
            name: "nene-gambit",
            dependencies: ["NeNeGambitCore", "NeNeGambitEngine", "NeNeGambitRender", "NeNeGambitTerminal"],
            swiftSettings: [.treatAllWarnings(as: .error), .enableUpcomingFeature("ExistentialAny")]
        ),
        .testTarget(
            name: "NeNeGambitCoreTests",
            dependencies: ["NeNeGambitCore"],
            swiftSettings: [.treatAllWarnings(as: .error), .enableUpcomingFeature("ExistentialAny")]
        ),
        .testTarget(
            name: "NeNeGambitEngineTests",
            dependencies: ["NeNeGambitCore", "NeNeGambitEngine"],
            swiftSettings: [.treatAllWarnings(as: .error), .enableUpcomingFeature("ExistentialAny")]
        ),
        .testTarget(
            name: "NeNeGambitRenderTests",
            dependencies: ["NeNeGambitCore", "NeNeGambitEngine", "NeNeGambitRender"],
            swiftSettings: [.treatAllWarnings(as: .error), .enableUpcomingFeature("ExistentialAny")]
        ),
        .testTarget(
            name: "NeNeGambitTerminalTests",
            dependencies: ["NeNeGambitEngine", "NeNeGambitRender", "NeNeGambitTerminal"],
            swiftSettings: [.treatAllWarnings(as: .error), .enableUpcomingFeature("ExistentialAny")]
        ),
    ],
    swiftLanguageModes: [.v6]
)
