import Foundation

/// **Touch event for a Support/Resistance Level**
public struct Touch {
    public let time: TimeInterval
    public let closePrice: Double
}

/// **Support/Resistance Level with Touch Data**
public struct Level {
    public let time: TimeInterval
    public let level: Double
    public var touches: [Touch]
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
    
    /// **Detects support levels using a dynamic tolerance based on volatility * factor**
    func candidateSupportPivots(windowSize: Int = 10, factor: Double) -> [(index: Int, level: Level)] {
        guard count > windowSize * 2 else { return [] }
        var supports: [(index: Int, level: Level)] = []
        
        for i in windowSize..<count - windowSize {
            let windowCandles = self[(i - windowSize)...(i + windowSize)]
            let minLow = windowCandles.map { $0.priceLow }.min()!
            
            let avgVolatility = windowCandles.reduce(0.0) {
                $0 + ( ($1.priceHigh - $1.priceLow) / $1.priceLow )
            } / Double(windowCandles.count)
            let dynamicTolerance = avgVolatility * factor
            
            let current = self[i]
            if current.priceLow <= minLow {
                let touches = self.compactMap { candle -> Touch? in
                    guard abs(candle.priceLow - minLow) / minLow <= dynamicTolerance else { return nil }
                    return Touch(time: candle.timeOpen, closePrice: candle.priceClose)
                }
                supports.append((i, Level(time: current.timeOpen, level: current.priceLow, touches: touches)))
            }
        }
        return supports
    }
    
    /// **Detects resistance levels using a dynamic tolerance based on volatility * factor**
    func candidateResistancePivots(windowSize: Int = 10, factor: Double) -> [(index: Int, level: Level)] {
        guard count > windowSize * 2 else { return [] }
        var resistances: [(index: Int, level: Level)] = []
        
        for i in windowSize..<count - windowSize {
            let windowCandles = self[(i - windowSize)...(i + windowSize)]
            let maxHigh = windowCandles.map { $0.priceHigh }.max()!
            
            let avgVolatility = windowCandles.reduce(0.0) {
                $0 + ( ($1.priceHigh - $1.priceLow) / $1.priceHigh )
            } / Double(windowCandles.count)
            let dynamicTolerance = avgVolatility * factor
            
            let current = self[i]
            if current.priceHigh >= maxHigh {
                let touches = self.compactMap { candle -> Touch? in
                    guard abs(candle.priceHigh - maxHigh) / maxHigh <= dynamicTolerance else { return nil }
                    return Touch(time: candle.timeOpen, closePrice: candle.priceClose)
                }
                resistances.append((i, Level(time: current.timeOpen, level: current.priceHigh, touches: touches)))
            }
        }
        return resistances
    }
    
    /// **Pairs supports with the first resistance that comes later**
    /// Iterates supports in reverse (most recent first) to capture current market behavior.
    func srPairs(windowSize: Int = 10, factor: Double) -> [((index: Int, level: Level), (index: Int, level: Level))] {
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
    
    /// **Auto-trains the factor using a grid search over historical data**
    func optimizeFactor(windowSize: Int = 10) -> Double {
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
    func evaluateFactor(_ factor: Double, windowSize: Int) -> Double {
        // Example metric: minimize imbalance between detected support and resistance counts.
        let supports = candidateSupportPivots(windowSize: windowSize, factor: factor)
        let resistances = candidateResistancePivots(windowSize: windowSize, factor: factor)
        return abs(Double(supports.count - resistances.count))
    }
}
