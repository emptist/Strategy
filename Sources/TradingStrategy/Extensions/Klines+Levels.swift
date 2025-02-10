import Foundation

public struct Level {
    public let time: TimeInterval
    public let level: Double
}

public struct SupportResistance {
    public var support: [Level]
    public var resistance: [Level]
    
    public init(support: [Level] = [], resistance: [Level] = []) {
        self.support = support
        self.resistance = resistance
    }
}

public extension [Klines] {
    // Extract candidate support pivots as (index, price) pairs.
    func candidateSupportPivots(windowSize: Int = 10) -> [(index: Int, level: Level)] {
        guard count > windowSize * 2 else { return [] }
        var supports: [(index: Int, level: Level)] = []
        for i in windowSize..<count - windowSize {
            let current = self[i]
            var minLow = current.priceLow
            for j in (i - windowSize)...(i + windowSize) {
                let low = self[j].priceLow
                if low < minLow { minLow = low }
            }
            if current.priceLow <= minLow {
                supports.append((i, Level(time: current.timeOpen, level: current.priceLow)))
            }
        }
        return supports
    }
    
    // Extract candidate resistance pivots as (index, price) pairs.
    func candidateResistancePivots(windowSize: Int = 10) -> [(index: Int, level: Level)] {
        guard count > windowSize * 2 else { return [] }
        var resistances: [(index: Int, level: Level)] = []
        for i in windowSize..<count - windowSize {
            let current = self[i]
            var maxHigh = current.priceHigh
            for j in (i - windowSize)...(i + windowSize) {
                let high = self[j].priceHigh
                if high > maxHigh { maxHigh = high }
            }
            if current.priceHigh >= maxHigh {
                resistances.append((i, Level(time: current.timeOpen, level: current.priceLow)))
            }
        }
        return resistances
    }
    
    /// Returns all (support, resistance) pairs.
    /// Each support pivot is paired with the first resistance pivot that comes later.
    func srPairs(windowSize: Int = 10) -> [((index: Int, level: Level), (index: Int, level: Level))] {
        let supports = candidateSupportPivots(windowSize: windowSize).sorted { $0.index < $1.index }
        let resistances = candidateResistancePivots(windowSize: windowSize).sorted { $0.index < $1.index }
        
        var pairs: [((index: Int, level: Level), (index: Int, level: Level))] = []
        for support in supports {
            if let resistance = resistances.first(where: { $0.index > support.index }) {
                pairs.append((support, resistance))
            }
        }
        return pairs
    }
    
    /// Generates SR levels using the specified number of pairs.
    /// The pairs are ordered from older to newest.
    func generateSRLevels(numPairs: Int = 3, windowSize: Int = 10) -> SupportResistance {
        let pairs = srPairs(windowSize: windowSize)
        guard !pairs.isEmpty else { return SupportResistance() }
        
        // Take the last 'numPairs' pairs (most recent), preserving order.
        let selectedPairs = pairs.suffix(numPairs)
        let supports = selectedPairs.map { $0.0.level }
        let resistances = selectedPairs.map { $0.1.level }
        return SupportResistance(support: supports, resistance: resistances)
    }
}
