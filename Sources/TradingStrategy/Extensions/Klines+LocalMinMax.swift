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
            return candle.priceClose.yToPoint(atIndex: index, scale: scale, canvasSize: size)
        }
        
        // Map maxima to points
        let maximaPoints = maximaIndices.map { index in
            let candle = self[index]
            return candle.priceClose.yToPoint(atIndex: index, scale: scale, canvasSize: size)
        }
        
        return (minimaPoints, maximaPoints)
    }
}
