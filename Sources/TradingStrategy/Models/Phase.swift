import Foundation

public typealias PhaseLinePoint = (point: CGPoint, index: Int)

public struct Phase: Sendable, Equatable {
    public var type: PhaseType
    // Rage of candle indices.
    public var range: ClosedRange<Int>
    
    public init(type: PhaseType, range: ClosedRange<Int>) {
        self.type = type
        self.range = range
    }
}

public enum PhaseType: String, Equatable, Sendable {
    case uptrend = "uptrend"
    case downtrend = "downtrend"
    case sideways = "sideways"
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
        return self.last(where: { $0.type != .sideways })
    }
    
    /// Return time phase if it is last phase in the list
    var timePhaseIfLast: Phase? {
        return self.last?.type == .sideways ? self.last : nil
    }
}

public extension [any Klines] {
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
        let currentPhaseRange = startIdx...(count - 1)
        if let lastPhase = phases.last, currentPhaseRange.length < minPhaseLength {
            // Extend the existing last phase to include new candles
            phases[phases.count - 1] = Phase(type: lastPhase.type, range: lastPhase.range.lowerBound...(count - 1))
        } else {
            phases.append(Phase(type: currentPhase, range: currentPhaseRange))
        }
        
        return phases
    }
    
    /// Identifies market phases based on price action relative to a short-term moving average (SMA).
    /// - Parameters:
    ///   - period: Minimum phase length before merging (default: 8).
    ///   - sma: Short-term moving average values corresponding to each candle.
    /// - Returns: A list of detected market **phases** (uptrend, downtrend, sideways).
    func detectPhasesUsingMovingAverage(period: Int = 8, shortTermMA sma: [Double], scale: Scale) -> [Phase] {
        guard count > period else { return [] }
        
        var phases: [Phase] = []
        var startIdx = 0
        var currentPhase: PhaseType = self[0].priceClose > sma[0] ? .uptrend : .downtrend
        
        for i in 1..<count {
            let price = self[i].priceClose
            let maValue = sma[i]
            let newPhase: PhaseType
            let yRange = scale.y.upperBound - scale.y.lowerBound
            let sidewaysThreshold = yRange * 0.05

            if abs(price - maValue) < sidewaysThreshold {
                newPhase = .sideways
            } else {
                newPhase = price > maValue ? .uptrend : .downtrend
            }
            
            if newPhase != currentPhase {
                let phaseLength = i - startIdx
                
                if phaseLength < period, !phases.isEmpty {
                    phases[phases.count - 1].range = phases[phases.count - 1].range.lowerBound...(i - 1)
                } else {
                    phases.append(Phase(type: currentPhase, range: startIdx...(i - 1)))
                }
                
                startIdx = i
                currentPhase = newPhase
            }
        }
        
        if startIdx < count {
            let phaseLength = count - startIdx
            if phaseLength < period, !phases.isEmpty {
                phases[phases.count - 1].range = phases[phases.count - 1].range.lowerBound...(count - 1)
            } else {
                phases.append(Phase(type: currentPhase, range: startIdx...(count - 1)))
            }
        }
        
        var mergedPhases: [Phase] = []
        for phase in phases {
            if let last = mergedPhases.last, last.type == phase.type {
                mergedPhases[mergedPhases.count - 1].range = last.range.lowerBound...phase.range.upperBound
            } else {
                mergedPhases.append(phase)
            }
        }
        
        return mergedPhases
    }
}
