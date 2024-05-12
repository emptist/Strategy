import Foundation

public extension [Klines] {
    /// Groups Klines of lower interval together in order to present higher interval of bars.
    /// For instance 1min candles can be group to represent 5min candles
    /// - Parameter interval: how many candles of lower interval to group together. In order to achieve 15min candles from 1min bars, you would put 15 here.
    /// - Returns: higher interval klines
    func aggregateBars(by interval: Int) -> [Klines] {
        var aggregatedBars: [Klines] = []
        var tempHigh: Double = -Double.infinity
        var tempLow: Double = Double.infinity
        var startIndex = 0

        for (index, bar) in enumerated() {
            tempHigh = Swift.max(tempHigh, bar.priceHigh)
            tempLow = Swift.min(tempLow, bar.priceLow)

            let isLastBar = index == count - 1
            let isIntervalEnd = (index - startIndex + 1) % interval == 0

            if isIntervalEnd || isLastBar {
                var newBar = bar
                newBar.timeOpen = self[startIndex].timeOpen
                newBar.priceOpen = self[startIndex].priceOpen
                newBar.priceHigh = tempHigh
                newBar.priceLow = tempLow
                newBar.priceClose = bar.priceClose
                newBar.interval = bar.interval * Double(interval)
                aggregatedBars.append(newBar)

                startIndex = index + 1
                tempHigh = -Double.infinity
                tempLow = Double.infinity
            }
        }

        return aggregatedBars
    }
}
