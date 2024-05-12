import Foundation

public struct Phase: Equatable {
    public var type: PhaseType
    public var range: ClosedRange<Int>
}

public enum PhaseType: String, Equatable {
    case time = "Time"
    case price = "Price"
}

public extension [PhaseType] {
    func group(ignoringNoiseUpTo noiseThreshold: Int = 3) -> [Phase] {
        var phases = [Phase]()
        var currentType: PhaseType? = nil
        var endIndex = self.count - 1
        var noiseCount = 0 // Counter for consecutive elements of a different type
        
        for (index, type) in self.enumerated().reversed() {
            if type == currentType {
                // Reset noise count when we find a matching type
                noiseCount = 0
            } else if currentType == nil || noiseCount < noiseThreshold {
                // Increment noise count if we encounter a different type
                // but haven't exceeded the noise threshold
                if currentType != nil {
                    noiseCount += 1
                }
            } else {
                // If noise threshold is exceeded, start a new phase
                phases.insert(Phase(type: currentType!, range: (index + noiseCount + 1)...endIndex), at: 0)
                currentType = type
                endIndex = index + noiseCount // End before the noise
                noiseCount = 0
            }
            
            // Update currentType if starting a new phase or if it's the first element
            if currentType == nil || noiseCount == 0 {
                currentType = type
            }
        }
        
        // Add the last phase, taking into account any trailing noise
        if let currentType = currentType, endIndex >= noiseCount {
            phases.insert(Phase(type: currentType, range: 0...endIndex), at: 0)
        }
        
        return phases
    }
}

public extension [Klines] {
    func detectPhaseTypes(
        forSimpleMovingAverage sma: [Double],
        inScale scale: Scale,
        canvasSize size: CGSize,
        period: Int
    ) -> [PhaseType] {
        guard sma.count > period else { return [] }
        var phases = [PhaseType](repeating: .price, count: sma.count)
        for i in period ..< count {
            let currentPoint = sma[i].toPoint(atTime: self[i].timeCenter, scale: scale, canvasSize: size)
            let previousPoint = sma[i - period].toPoint(atTime: self[i - period].timeCenter, scale: scale, canvasSize: size)
            let angle  = currentPoint.angleLineToXAxis(previousPoint)
            
            switch abs(angle) {
            case let x where x > 30:
                phases[i] = .price
            default:
                phases[i] = .time
            }
        }
        
        return phases
    }
    
    func detectPhases(
        forSimpleMovingAverage sma: [Double],
        inScale scale: Scale,
        canvasSize size: CGSize,
        period: Int
    ) -> [Phase] {
        detectPhaseTypes(
            forSimpleMovingAverage: sma,
            inScale: scale,
            canvasSize: size,
            period: period
        ).group()
    }
}

public extension ClosedRange where Bound == Int {
    /// Amplitiude between upperBound and lowerBound
    var length: Bound {
        upperBound - lowerBound
    }
}

public extension [Phase] {
    /// Last price phase before suprise
    var lastPricePhase: Phase? {
        var previousPhase: Phase?
        if let lastPhase = last, lastPhase.type == .time, count > 1 {
            previousPhase = self[count - 2]
        } else if (last?.range.length ?? 0) < 4, count > 2 {
            previousPhase = self[count - 3]
        }
        return previousPhase
    }
    
    /// Last time phase before suprise
    var lastTimePhase: Phase? {
        if let lastPhase = last, lastPhase.type == .time {
            return lastPhase
        } else if (last?.range.length ?? 0) < 4, count > 1 {
            let lastPhase = self[count - 2]
            if lastPhase.type == .time {
                return lastPhase
            }
        }
        return nil
    }
}
