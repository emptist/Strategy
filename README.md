# Strategy Protocol and Utilities Library

## Introduction
This repository provides a flexible and powerful framework for financial strategy development and testing, designed specifically for use with Swift. It includes a standard `Strategy` protocol and a suite of utility functions to assist in strategy analysis and decision-making based on technical indicators.

## Key Features
- **Strategy Protocol**: A protocol to standardize the development of trading strategies.
- **Utility Functions**: A comprehensive collection of functions to calculate various technical indicators such as SMA (Simple Moving Average), Bollinger Bands, ROC (Rate of Change), and more.

## Strategy Protocol
The `Strategy` protocol is designed for implementing trading strategies with an emphasis on candlestick data analysis. The protocol requires the following properties and initializer:

```swift
public protocol Strategy {
    var recentCandlesSize: Int { get }
    var recentCandlesPatternPrediction: Bool { get }
    var patternIdentified: Bool { get }
    
    init(candles: [Klines], multiplier: Int)
}
```

### Example Implementation
Below is an example of a simple strategy conforming to the `Strategy` protocol:

```swift
import Foundation

public struct ExampleStrat: Strategy {
    public init(candles: [Klines], multiplier: Int = 15) {
        // Implementation based on `multiplier` and `candles`
    }
    
    public let recentCandlesSize: Int = 12
    
    public var recentCandlesPatternPrediction: Bool {
        // Logic to predict candle pattern
        return true
    }
    
    public var patternIdentified: Bool {
        // Logic to identify patterns
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

The [Swift Package Manager](https://swift.org/package-manager/) is a tool for automating the distribution of Swift code and is integrated into the swift compiler.

Once you have your Swift package set up, adding a dependency is as easy as adding it to the dependencies value of your Package.swift.

```
dependencies: [
    .package(url: "https://github.com/TradeWithIt/Strategy", branch: "main")
]

## Contributions
Contributions are welcome! If you have improvements or bug fixes, please submit a pull request or open an issue.

## License
This library is released under the MIT license. Please see the [LICENSE](LICENSE) file for more details.
