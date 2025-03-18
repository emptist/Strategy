// swift-tools-version: 5.10

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
