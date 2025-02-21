# Strategy Protocol and Utilities Library

## Introduction
This repository provides a flexible and powerful framework for financial strategy development and testing, designed specifically for use with Swift. It includes a standard `Strategy` protocol and a suite of utility functions to assist in strategy analysis and decision-making based on technical indicators.

## Key Features
- **Strategy Protocol**: A protocol to standardize the development of trading strategies.
- **Decision Engine & Position Management**: Integrated modules for evaluating trade entry conditions and managing stop-losses dynamically.
- **Utility Functions**: A comprehensive collection of functions to calculate various technical indicators such as SMA (Simple Moving Average), Bollinger Bands, ROC (Rate of Change), and more.
- **Persistent Trade Storage**: Ensures trades can be restored after a crash or app restart.

## Strategy Protocol
The `Strategy` protocol is designed for implementing trading strategies with an emphasis on candlestick data analysis. The protocol requires the following properties and methods:

```swift
public protocol Strategy {
    var candles: [Klines] { get }
    var phases: [Phase] { get }
    var longTermMA: [Double] { get }
    var shortTermMA: [Double] { get }
    var supportBars: [Klines] { get }
    var supportPhases: [Phase] { get }
    var supportScale: Scale { get }
    var levels: SupportResistance { get }
    var patternIdentified: Bool { get }
    var patternInformation: [String: Bool] { get }
    
    init(candles: [Klines])

    func evaluateEntry(portfolio: Double) -> Int
    func adjustStopLoss(entryBar: Klines) -> Double?
    func shouldExit(entryBar: Klines) -> Bool
}
```

### Example Implementation
Below is an example of a simple strategy conforming to the `Strategy` protocol:

```swift
import Foundation

public struct ExampleStrat: Strategy {
    public let candles: [Klines]
    public var patternIdentified: Bool
    public var patternInformation: [String: Bool]

    public init(candles: [Klines]) {
        self.candles = candles
        self.patternIdentified = false
        self.patternInformation = [:]
    }

    public func evaluateEntry(portfolio: Double) -> Int {
        // Example evaluation logic
        return 0
    }

    public func adjustStopLoss(entryBar: Klines) -> Double? {
        // Example stop-loss adjustment logic
        return nil
    }

    public func shouldExit(entryBar: Klines) -> Bool {
        // Example exit condition logic
        return false
    }
}
```

## Utility Functions
The library includes several extensions for arrays of `Klines`, providing calculations of various technical indicators. These functions aid in analyzing financial data to determine market trends and to make informed trading decisions.

### Technical Indicators
- **Simple Moving Average (SMA)**
- **Bollinger Bands**
- **Rate of Change (ROC)**
- **Average True Range (ATR)**
- **Directional Indicators (+DI, -DI)**
- **Average Directional Index (ADX)**
- **Relative Strength Index (RSI)**
- **Geometry Tools**
- **Others**

## Swift Package Manager

The [Swift Package Manager](https://swift.org/package-manager/) is a tool for automating the distribution of Swift code and is integrated into the Swift compiler.

Once you have your Swift package set up, adding a dependency is as easy as adding it to the dependencies value of your Package.swift.

```swift
dependencies: [
    .package(url: "https://github.com/TradeWithIt/Strategy", branch: "main")
]
```

## Contributions
Contributions are welcome! If you have improvements or bug fixes, please submit a pull request or open an issue.

## License
This library is released under the MIT license. Please see the [LICENSE](LICENSE) file for more details.

