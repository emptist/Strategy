import Foundation

public extension [Klines] {
    
    /// **Aggregates Klines into higher timeframes using FIXED TIME INTERVALS**
    /// - Parameter targetInterval: Desired bar duration (e.g., `900` for 15min, `3600` for 1h).
    /// - Returns: Aggregated Klines matching exact time intervals.
    func aggregateBars(to targetInterval: TimeInterval) -> [Klines] {
        guard let firstBar = self.first else { return [] } // Safe check for empty array
        
        var aggregatedBars: [Klines] = []
        var tempBar: Klines?
        
        // Find the first candle's start time and align to the fixed interval
        let startAlignedTime = (floor(firstBar.timeOpen / targetInterval) * targetInterval)

        for bar in self {
            let barStartTime = (floor(bar.timeOpen / targetInterval) * targetInterval)
            
            if tempBar == nil || barStartTime > (tempBar?.timeOpen ?? 0) {
                // Start new aggregated candle
                if let completedBar = tempBar {
                    aggregatedBars.append(completedBar)
                }
                
                var newBar = bar
                newBar.timeOpen = barStartTime
                newBar.priceOpen = bar.priceOpen
                newBar.priceHigh = bar.priceHigh
                newBar.priceLow = bar.priceLow
                newBar.priceClose = bar.priceClose
                newBar.interval = targetInterval
                tempBar = newBar
            } else if var updatedBar = tempBar {
                // Modify a local copy and then reassign
                updatedBar.priceHigh = Swift.max(updatedBar.priceHigh, bar.priceHigh)
                updatedBar.priceLow = Swift.min(updatedBar.priceLow, bar.priceLow)
                updatedBar.priceClose = bar.priceClose
                tempBar = updatedBar
            }
        }
        
        // Append the last aggregated bar if it exists
        if let lastBar = tempBar {
            aggregatedBars.append(lastBar)
        }

        return aggregatedBars
    }
}
