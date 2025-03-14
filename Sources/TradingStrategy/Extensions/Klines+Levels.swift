import Foundation

/// **Touch event for a Support/Resistance Level**
public struct Touch {
    public let index: Int
    public let time: TimeInterval
    public let closePrice: Double
    
    public init(index: Int, time: TimeInterval, closePrice: Double) {
        self.index = index
        self.time = time
        self.closePrice = closePrice
    }
}

/// **Support/Resistance Level with Touch Data**
public struct Level {
    public let index: Int
    public let time: TimeInterval
    public var touches: [Touch]
    
    public init(index: Int, time: TimeInterval, touches: [Touch]) {
        self.index = index
        self.time = time
        self.touches = touches
    }
    
    public var level: Double {
        guard !touches.isEmpty else { return 0.0 }

        let candidates = touches.map { $0.closePrice }
        return candidates.min(by: { left, right in
            let leftDeviation = candidates.map { abs($0 - left) }.reduce(0, +)
            let rightDeviation = candidates.map { abs($0 - right) }.reduce(0, +)
            return leftDeviation < rightDeviation
        }) ?? 0.0
    }
}

public extension [Klines] {
    /// **Generates SR levels with touch history**
    /// Iterates in reverse to pick the most recent numPairs.
    func generateSRLevels(numPairs: Int = 2, windowSize: Int = 12, scale: Scale, chartSize: CGSize) -> [Level] {
        var supportLevels: [Level] = []
        var resistanceLevels: [Level] = []
        var processedPairs = 0
        
        // Ensure there are enough candles to process
        guard self.count > windowSize, numPairs > 0 else { return [] }
        
        // Commit last candle as "entry" and do not affect SR levels
        let lastCandle = self.last
        let candlesToProcess = self.dropLast()
        
        // Iterate over the candles in reverse and stop once numPairs pairs are found
        for i in stride(from: candlesToProcess.count - windowSize - 1, through: 0, by: -1) {
            guard i >= 0, i + windowSize <= candlesToProcess.count else { continue }
            
            let window = candlesToProcess[i..<(i + windowSize)]
            
            guard let high = window.max(by: { $0.priceHigh < $1.priceHigh })?.priceHigh,
                  let low = window.min(by: { $0.priceLow < $1.priceLow })?.priceLow else {
                continue
            }
            
            // Ensure resistance levels are distinct and not clustered too close
            if let existingResistanceIndex = resistanceLevels.firstIndex(where: { abs($0.level - high) < scale.yGuideStep * 2 }) {
                resistanceLevels[existingResistanceIndex].touches.append(Touch(index: i, time: candlesToProcess[i].timeOpen, closePrice: high))
            } else {
                resistanceLevels.append(Level(index: i, time: candlesToProcess[i].timeOpen, touches: [Touch(index: i, time: candlesToProcess[i].timeOpen, closePrice: high)]))
            }
            
            // Ensure support levels are distinct and not clustered too close
            if let existingSupportIndex = supportLevels.firstIndex(where: { abs($0.level - low) < scale.yGuideStep * 2 }) {
                supportLevels[existingSupportIndex].touches.append(Touch(index: i, time: candlesToProcess[i].timeOpen, closePrice: low))
            } else {
                supportLevels.append(Level(index: i, time: candlesToProcess[i].timeOpen, touches: [Touch(index: i, time: candlesToProcess[i].timeOpen, closePrice: low)]))
            }
            
            // Only count pairs where both support and resistance exist, and each has at least two touch points
            if let lastResistance = resistanceLevels.last, let lastSupport = supportLevels.last,
               lastResistance.touches.count >= 2, lastSupport.touches.count >= 2 {
                processedPairs += 1
            }
            
            if processedPairs >= numPairs {
                break
            }
        }
        
        // Ensure we return an equal number of support and resistance levels
        let count = Swift.min(supportLevels.count, resistanceLevels.count, numPairs)
        let result: [Level] = supportLevels.prefix(count) + resistanceLevels.prefix(count).map { $0 }
        return result.sorted { $0.level < $1.level }
    }
}
