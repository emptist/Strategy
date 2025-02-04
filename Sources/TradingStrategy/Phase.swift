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
    case sideways = "sideways"
    case uptrend = "uptrend"
    case downtrend = "downtrend"
}

public extension [Klines] {
    /// Detects sideways, uptrend, and downtrend phases based on local extremes and volatility.
    func detectPhaseFromSideways(
        minimumLength: Int = 12,
        bollingerPeriod: Int = 20,
        adxPeriod: Int = 14,
        rsiPeriod: Int = 14,
        minMaxWindowSize: Int = 6
    ) -> [Phase] {
        let sidelines = self.sidelines(bollingerPeriod: bollingerPeriod, adxPeriod: adxPeriod, rsiPeriod: rsiPeriod)
        let (minima, maxima) = findLocalExtremes(windowSize: minMaxWindowSize)

        var sequences: [Phase] = []
        var start: Int? = nil

        for (index, isSideways) in sidelines.enumerated() {
            if isSideways {
                if start == nil {
                    start = index
                }
            } else {
                if let startIndex = start, index - startIndex >= minimumLength {
                    sequences.append(Phase(type: .sideways, range: startIndex...(index - 1)))
                }
                start = nil
            }
        }

        if let startIndex = start, sidelines.count - startIndex >= minimumLength {
            sequences.append(Phase(type: .sideways, range: startIndex...(sidelines.count - 1)))
        }

        // Fill gaps with uptrend and downtrend phases
        var filledSequences: [Phase] = []
        var previousEnd = -1

        for phase in sequences {
            if phase.range.lowerBound > previousEnd + 1 {
                let trendPhases = detectTrendsInRange(start: previousEnd + 1, end: phase.range.lowerBound - 1, minima: minima, maxima: maxima)
                filledSequences.append(contentsOf: trendPhases)
            }

            filledSequences.append(phase)
            previousEnd = phase.range.upperBound
        }

        if previousEnd < sidelines.count - 1 {
            let trendPhases = detectTrendsInRange(start: previousEnd + 1, end: sidelines.count - 1, minima: minima, maxima: maxima)
            filledSequences.append(contentsOf: trendPhases)
        }

        return filledSequences
    }

    /// Splits a range into uptrend and downtrend phases based on local min/max points.
    private func detectTrendsInRange(start: Int, end: Int, minima: [Int], maxima: [Int]) -> [Phase] {
        var trendPhases: [Phase] = []
        var trendStart = start
        var currentTrend: PhaseType? = nil

        for i in start...end {
            let isMin = minima.contains(i)
            let isMax = maxima.contains(i)

            if isMin || isMax {
                let nextTrend: PhaseType = isMin ? .uptrend : .downtrend

                if currentTrend == nil {
                    currentTrend = nextTrend
                } else if let trend = currentTrend, nextTrend != currentTrend {
                    trendPhases.append(Phase(type: trend, range: trendStart...i))
                    trendStart = i
                    currentTrend = nextTrend
                }
            }
        }

        if let trend = currentTrend, trendStart <= end {
            trendPhases.append(Phase(type: trend, range: trendStart...end))
        }

        return trendPhases
    }
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
