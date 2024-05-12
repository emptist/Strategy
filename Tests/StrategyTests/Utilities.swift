import Foundation
@testable import TradeWithIt

public struct Candle: Klines {
    public var priceClose: Double
    public var priceHigh: Double
    public var priceLow: Double
    public var priceOpen: Double
    public var timeOpen: TimeInterval
    public var interval: TimeInterval
    
    public init(
        open: Double,
        close: Double,
        high: Double,
        low: Double,
        volume: Double,
        time: TimeInterval = Date().timeIntervalSince1970,
        interval: TimeInterval = 60
    ) {
        self.priceClose = close
        self.priceHigh = high
        self.priceLow = low
        self.priceOpen = open
        self.timeOpen = time
        self.interval = interval
    }
}

// Function to generate an array of Candle objects reflecting the first image (Uptrend with a big bullish candle)
func generateLongCandles(count: Int = 30) -> [Klines] {
    let baseTime = Date().timeIntervalSince1970
    let oneMinute: TimeInterval = 60
    var candles: [Candle] = []

    // Generate some previous candles to establish the trend
    for i in 0..<(count - 2) {
        let openCloseMin = Double.random(in: 100.0...105.0)
        let openCloseMax = Double.random(in: openCloseMin...110.0)
        let low = openCloseMin - Double.random(in: 1.0...5.0)
        let high = openCloseMax + Double.random(in: 1.0...5.0)
        let volume = Double.random(in: 500...1500)
        candles.append(
            Candle(
                open: openCloseMin,
                close: openCloseMax,
                high: high,
                low: low,
                volume: volume,
                time: baseTime - (Double(count-i) * oneMinute)
            )
        )
    }
    
    for i in (count - 2)..<count {
        candles.append(
            Candle(
                open: 105,
                close: 107,
                high: 110,
                low: 100,
                volume: 200,
                time: baseTime - (Double(count-i) * oneMinute)
            )
        )
    }
    // Add the big bullish candle
    let bigBullishCandle = Candle(open: 105, close: 130, high: 135, low: 100, volume: 2000, time: baseTime)
    candles.append(bigBullishCandle)

    return candles
}

// Function to generate an array of Candle objects reflecting the second image (Downtrend with a big bearish candle)
func generateShortCandles(count: Int = 30) -> [Klines] {
    let baseTime = Date().timeIntervalSince1970
    let oneMinute: TimeInterval = 60
    var candles: [Klines] = []

    // Generate some previous candles to establish the trend
    for i in 0..<(count - 2) {
        let openCloseMax = Double.random(in: 95.0...100.0)
        let openCloseMin = Double.random(in: 90.0...openCloseMax)
        let high = openCloseMax + Double.random(in: 1.0...5.0)
        let low = openCloseMin - Double.random(in: 1.0...5.0)
        let volume = Double.random(in: 500...1500)
        
        candles.append(
            Candle(
                open: openCloseMax,
                close: openCloseMin,
                high: high,
                low: low,
                volume: volume,
                time: baseTime - (Double(count-i) * oneMinute)
            )
        )
    }
    
    for i in (count - 2)..<count {
        candles.append(
            Candle(
                open: 92,
                close: 90,
                high: 93,
                low: 89,
                volume: 200,
                time: baseTime - (Double(count-i) * oneMinute)
            )
        )
    }
    
    // Add the big bearish candle
    let bigBearishCandle = Candle(open: 95, close: 70, high: 100, low: 65, volume: 2000, time: baseTime)
    candles.append(bigBearishCandle)

    return candles
}

func printCandles(_ candles: [Klines]) {
    let maxHeight = candles.max(by: { $0.priceHigh < $1.priceHigh })?.priceHigh ?? 0
    let minHeight = candles.min(by: { $0.priceLow < $1.priceLow })?.priceLow ?? 0
    let maxGraphHeight = Int(maxHeight - minHeight)
    let scalingFactor = 1.0
    let graphWidth = candles.count * 3 // Assuming 3 characters width per candle

    var graph = Array(repeating: Array(repeating: " ", count: graphWidth), count: maxGraphHeight)

    for (index, candle) in candles.enumerated() {
        let openPos = Int((candle.priceOpen - minHeight) * scalingFactor)
        let closePos = Int((candle.priceClose - minHeight) * scalingFactor)
        let highPos = Int((candle.priceHigh - minHeight) * scalingFactor)
        let lowPos = Int((candle.priceLow - minHeight) * scalingFactor)

        for y in lowPos...highPos {
            let yPos = max(0, min(maxGraphHeight - 1, maxGraphHeight - 1 - y))
            graph[yPos][index * 3 + 1] = "|"
        }

        let bodyRange = min(openPos, closePos)...max(openPos, closePos)
        for y in bodyRange {
            let yPos = max(0, min(maxGraphHeight - 1, maxGraphHeight - 1 - y))
            graph[yPos][index * 3] = "["
            graph[yPos][index * 3 + 2] = "]"
        }
    }

    for row in graph {
        print(row.joined())
    }
}
