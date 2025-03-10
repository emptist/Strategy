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

/// **Container for Support & Resistance Levels**
public struct SupportResistance {
    public var support: [Level]
    public var resistance: [Level]
    
    public init(support: [Level] = [], resistance: [Level] = []) {
        self.support = support
        self.resistance = resistance
    }
}

public extension [Klines] {
    /// **Generates SR levels with touch history**
    /// Iterates in reverse to pick the most recent numPairs.
    func generateSRLevels(numPairs: Int = 3, windowSize: Int = 12) -> SupportResistance {
        let factor = optimizeFactor(windowSize: windowSize)
        let pairs = srPairs(windowSize: windowSize, factor: factor)
        guard !pairs.isEmpty else { return SupportResistance() }
        
        // Take the first numPairs from the reverse-ordered pairs (most recent first).
        let selectedPairs = pairs.prefix(numPairs).reversed()
        let supports = selectedPairs.map { $0.0.level }
        let resistances = selectedPairs.map { $0.1.level }
        
        return SupportResistance(support: supports, resistance: resistances)
    }
    
    /// **Detects support levels using a dynamic tolerance based on volatility * factor**
    private func candidateSupportPivots(windowSize: Int, factor: Double) -> [(index: Int, level: Level)] {
        guard count > windowSize * 2 else { return [] }
        var supports: [(index: Int, level: Level)] = []
        
        for i in windowSize ..< (count - windowSize) {
            let windowCandles = Array(self[(i - windowSize)...(i + windowSize)])
            guard let minLow = windowCandles.map { $0.priceLow }.min() else { continue }
            
            let avgVolatility = windowCandles.reduce(0.0) {
                $0 + ( ($1.priceHigh - $1.priceLow) / $1.priceLow )
            } / Double(windowCandles.count)
            let dynamicTolerance = avgVolatility * factor
            
            let current = self[i]
            if current.priceLow <= minLow {
                let touches = self.compactMap { candle -> Touch? in
                    guard abs(candle.priceLow - minLow) / minLow <= dynamicTolerance else { return nil }
                    return Touch(index: i, time: candle.timeOpen, closePrice: candle.priceClose)
                }
                supports.append((i, Level(index: i, time: current.timeOpen, touches: touches)))
            }
        }
        return supports
    }
    
    /// **Detects resistance levels using a dynamic tolerance based on volatility * factor**
    private func candidateResistancePivots(windowSize: Int, factor: Double) -> [(index: Int, level: Level)] {
        guard count > windowSize * 2 else { return [] }
        var resistances: [(index: Int, level: Level)] = []
        
        for i in windowSize ..< (count - windowSize) {
            let windowCandles = Array(self[(i - windowSize)...(i + windowSize)])
            guard let maxHigh = windowCandles.map { $0.priceHigh }.max()  else { continue }
            
            let avgVolatility = windowCandles.reduce(0.0) {
                $0 + ( ($1.priceHigh - $1.priceLow) / $1.priceHigh )
            } / Double(windowCandles.count)
            let dynamicTolerance = avgVolatility * factor
            
            let current = self[i]
            if current.priceHigh >= maxHigh {
                let touches = self.compactMap { candle -> Touch? in
                    guard abs(candle.priceHigh - maxHigh) / maxHigh <= dynamicTolerance else { return nil }
                    return Touch(index: i, time: candle.timeOpen, closePrice: candle.priceClose)
                }
                resistances.append((i, Level(index: i, time: current.timeOpen, touches: touches)))
            }
        }
        return resistances
    }
    
    /// **Pairs supports with the first resistance that comes later**
    /// Iterates supports in reverse (most recent first) to capture current market behavior.
    private func srPairs(windowSize: Int, factor: Double) -> [((index: Int, level: Level), (index: Int, level: Level))] {
        let supports = candidateSupportPivots(windowSize: windowSize, factor: factor)
        let resistances = candidateResistancePivots(windowSize: windowSize, factor: factor)
        
        // Sort supports descending to prioritize the most recent ones.
        let sortedSupports = supports.sorted { $0.index > $1.index }
        // Keep resistances sorted in ascending order.
        let sortedResistances = resistances.sorted { $0.index < $1.index }
        
        var pairs: [((index: Int, level: Level), (index: Int, level: Level))] = []
        for support in sortedSupports {
            if let resistance = sortedResistances.first(where: { $0.index > support.index }) {
                pairs.append((support, resistance))
            }
        }
        return pairs
    }
    
    /// **Auto-trains the factor using a grid search over historical data**
    private func optimizeFactor(windowSize: Int) -> Double {
        let candidateFactors = stride(from: 0.1, through: 1.0, by: 0.1)
        var bestFactor: Double = 0.5
        var bestScore = Double.greatestFiniteMagnitude
        
        for factor in candidateFactors {
            let score = evaluateFactor(factor, windowSize: windowSize)
            if score < bestScore {
                bestScore = score
                bestFactor = factor
            }
        }
        return bestFactor
    }

    /// **Evaluates a factor using a custom performance metric**
    private func evaluateFactor(_ factor: Double, windowSize: Int) -> Double {
        // Example metric: minimize imbalance between detected support and resistance counts.
        let supports = candidateSupportPivots(windowSize: windowSize, factor: factor)
        let resistances = candidateResistancePivots(windowSize: windowSize, factor: factor)
        return abs(Double(supports.count - resistances.count))
    }
}
