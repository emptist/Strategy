// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "TradingStrategy",
    products: [
        .library(name: "TradingStrategy", targets: ["TradingStrategy"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "TradingStrategy", dependencies: []),
        .testTarget(name: "TradingStrategyTests", dependencies: ["TradingStrategy"]),
    ]
)
