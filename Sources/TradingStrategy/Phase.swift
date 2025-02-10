import Foundation

public typealias PhaseLinePoint = (point: CGPoint, index: Int)

public struct Phase: Equatable {
    public var type: PhaseType
    // Rage of candle indices.
    public var range: ClosedRange<Int>
    
    public init(type: PhaseType, range: ClosedRange<Int>) {
        self.type = type
        self.range = range
    }
}

public enum PhaseType: String, Equatable {
    case uptrend = "uptrend"
    case downtrend = "downtrend"
}

public extension ClosedRange where Bound == Int {
    /// Amplitiude between upperBound and lowerBound
    var length: Bound {
        upperBound - lowerBound
    }
}

public extension [Phase] {
    /// Last price phase
    var lastPricePhase: Phase? {
        return self.last
    }
}

public extension [Klines] {
    func convertToPhases(minPhaseLength: Int = 14, longTermMA: [Double]) -> [Phase] {
        guard count > 1, longTermMA.count >= count else { return [] }
        
        var phases: [Phase] = []
        var startIdx = 0
        var currentPhase: PhaseType = self[0].priceClose > longTermMA[0] ? .uptrend : .downtrend
        let stabilityBuffer = Swift.max(minPhaseLength / 2, 3) // Minimum candles required before switching
        
        for i in 1..<count {
            let closePrice = self[i].priceClose
            let maValue = longTermMA[i]
            let newPhase: PhaseType = closePrice > maValue ? .uptrend : .downtrend
            
            // **Trend Change Detection with Stability Buffer**
            if newPhase != currentPhase {
                let phaseLength = i - startIdx
                
                // Ensure trend change only after a stability period
                if phaseLength < stabilityBuffer {
                    continue // Ignore temporary fluctuations
                }
                
                // **Merge short phases into the previous one**
                if phaseLength < minPhaseLength, !phases.isEmpty {
                    let lastPhase = phases.removeLast()
                    startIdx = lastPhase.range.lowerBound // Extend the previous phase
                } else {
                    phases.append(Phase(type: currentPhase, range: startIdx...(i - 1)))
                    startIdx = i
                }
                
                currentPhase = newPhase
            }
        }
        
        // **Ensure last phase is appended without blinking**
        if let lastPhase = phases.last, lastPhase.type == currentPhase {
            // Extend the existing last phase to include new candles
            phases[phases.count - 1] = Phase(type: lastPhase.type, range: lastPhase.range.lowerBound...(count - 1))
        } else {
            phases.append(Phase(type: currentPhase, range: startIdx...(count - 1)))
        }
        
        return phases
    }
}
