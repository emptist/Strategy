import Foundation

public extension [Klines] {
    /// Detects local minima and maxima across the entire dataset
    func findLocalExtremes(windowSize: Int = 6) -> ([Int], [Int]) {
        guard count > windowSize * 2 else { return ([], []) }
        
        var minima: [Int] = []
        var maxima: [Int] = []
        var lookingForMin = true // Start by searching for a minimum
        
        var i = windowSize
        while i < count - windowSize {
            let window = self[(i - windowSize)...(i + windowSize)]
            let closePrices = window.map { $0.priceClose }
            let midIndex = i
            let currentClose = self[midIndex].priceClose
            
            if lookingForMin, currentClose == closePrices.min() {
                minima.append(midIndex)
                lookingForMin = false // Next, look for a max
                i += windowSize // Skip forward to avoid detecting noise
            } else if !lookingForMin, currentClose == closePrices.max() {
                maxima.append(midIndex)
                lookingForMin = true // Next, look for a min
                i += windowSize
            } else {
                i += 1
            }
        }
        
        return (minima, maxima)
    }
    
    /// Maps local minima and maxima to drawable points
    func mapLocalExtremesToPoints(scale: Scale, canvasSize size: CGSize) -> ([CGPoint], [CGPoint]) {
        let (minimaIndices, maximaIndices) = findLocalExtremes()
        
        // Map minima to points
        let minimaPoints = minimaIndices.map { index in
            let candle = self[index]
            return candle.priceClose.toPoint(atTime: candle.timeCenter, scale: scale, canvasSize: size)
        }
        
        // Map maxima to points
        let maximaPoints = maximaIndices.map { index in
            let candle = self[index]
            return candle.priceClose.toPoint(atTime: candle.timeCenter, scale: scale, canvasSize: size)
        }
        
        return (minimaPoints, maximaPoints)
    }
}

public extension [Klines] {
    /// Determines trend phases using mapped min/max values
    func detectPhasesFromExtremes(windowSize: Int = 6, minPhaseLength: Int = 6) -> [Phase] {
        let (minima, maxima) = findLocalExtremes(windowSize: windowSize)
        guard minima.count > 1, maxima.count > 1 else { return [] }

        var phases: [Phase] = []
        var startIdx = 0
        var currentPhaseType: PhaseType = .sideways

        for i in 1..<count {
            let lastTwoMinima = minima.filter { $0 < i }.suffix(2).map { self[$0].priceClose }
            let lastTwoMaxima = maxima.filter { $0 < i }.suffix(2).map { self[$0].priceClose }

            guard lastTwoMinima.count == 2, lastTwoMaxima.count == 2 else { continue }

            let isUptrend = lastTwoMinima[1] > lastTwoMinima[0] && lastTwoMaxima[1] > lastTwoMaxima[0]
            let isDowntrend = lastTwoMinima[1] < lastTwoMinima[0] && lastTwoMaxima[1] < lastTwoMaxima[0]

            // Define sideways range threshold
            let rangeDiff = lastTwoMaxima[1] - lastTwoMinima[1]
            let threshold = 0.02 * rangeDiff
            let isSideways = abs(lastTwoMinima[1] - lastTwoMinima[0]) < threshold &&
                             abs(lastTwoMaxima[1] - lastTwoMaxima[0]) < threshold

            let newPhaseType: PhaseType = isUptrend ? .uptrend : isDowntrend ? .downtrend : .sideways

            if newPhaseType != currentPhaseType {
                let upperBound = i - 1
                let lastPhaseLength = upperBound - startIdx + 1

                // Merge short phases into the previous phase
                if lastPhaseLength >= minPhaseLength {
                    phases.append(Phase(type: currentPhaseType, range: startIdx...upperBound))
                    startIdx = i
                    currentPhaseType = newPhaseType
                } else {
                    // If phase is too short, merge with the new one
                    currentPhaseType = newPhaseType
                }
            }
        }

        // Append the final phase
        let upperBound = Swift.min(count - 1, count - 1)
        if upperBound - startIdx + 1 >= minPhaseLength {
            phases.append(Phase(type: currentPhaseType, range: startIdx...upperBound))
        }

        return phases
    }
}
