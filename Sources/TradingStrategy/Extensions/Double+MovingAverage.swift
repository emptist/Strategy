import Foundation

extension [Double] {
    // Calculate Simple Moving Average (SMA)
    func simpleMovingAverage(_ period: Int) -> Double? {
        // Ensure we have enough candles to calculate the SMA
        guard count > period else { return nil }
        
        // Sum up the closing prices of the last 'period' candles
        let sum = self.suffix(period).reduce(0.0) { $0 + $1 }
        
        // Divide by the period to get the average
        return sum / Double(period)
    }
    
    /// Calculates the Exponential Moving Average (EMA) for a given set of values over a specified period.
    /// - Parameters:
    ///   - period: The number of periods over which to calculate the EMA.
    /// - Returns: An array of EMA values corresponding to each value in the input array.
    func exponentialMovingAverage(period: Int) -> [Double] {
        var emaValues: [Double] = []
        let multiplier: Double = 2.0 / (Double(period) + 1.0)
        
        for i in 0..<self.count {
            if i < period - 1 {
                emaValues.append(0) // Not enough data to calculate EMA
            } else if i == period - 1 {
                let sum: Double = self[0...i].reduce(0.0, +)
                let average = sum / Double(period)
                emaValues.append(average)
            } else {
                let ema = (self[i] - emaValues[i - 1]) * multiplier + emaValues[i - 1]
                emaValues.append(ema)
            }
        }
        
        return emaValues
    }
    
    /// Calculates the Simple Moving Average (SMA) for a given set of values over a specified period.
    /// - Parameters:
    ///   - values: An array of `Double` values for which to calculate the SMA.
    ///   - period: The number of periods over which to calculate the SMA.
    /// - Returns: An array of SMA values corresponding to each value in the input array.
    func simpleMovingAverage(period: Int) -> [Double] {
        var smaValues: [Double] = []
        
        for i in 0..<self.count {
            if i < period - 1 {
                smaValues.append(0) // Not enough data to calculate SMA
            } else {
                let sum = self[(i - period + 1)...i].reduce(0, +)
                let average = sum / Double(period)
                smaValues.append(average)
            }
        }
        
        return smaValues
    }
}
