import Foundation

public typealias BollingerBands = (upperBand: [Double], middleBand: [Double], lowerBand: [Double])

public extension [Klines] {
    // Calculate Simple Moving Average (SMA)
    func simpleMovingAverage(period: Int) -> Double? {
        // Ensure we have enough candles to calculate the SMA
        guard count >= period else { return nil }
        
        // Sum up the closing prices of the last 'period' candles
        let sum = self.suffix(period).reduce(0) { $0 + $1.priceClose }
        
        // Divide by the period to get the average
        return sum / Double(period)
    }
    
    func simpleMovingAverage(period: Int) -> [Double] {
        var smaValues: [Double] = []
        
        for i in 0..<self.count {
            if i < period - 1 {
                smaValues.append(0) // Not enough data to calculate SMA
            } else {
                let sum = self[(i - period + 1)...i].reduce(0, { $0 + $1.priceClose })
                let average = sum / Double(period)
                smaValues.append(average)
            }
        }
        
        return smaValues
    }
    
    func rateOfChange(period: Int) -> [Double] {
        var roc = [Double](repeating: 0.0, count: count)
        for i in period..<count {
            let prevPrice = self[i - period].priceClose
            let currentPrice = self[i].priceClose
            roc[i] = (currentPrice - prevPrice) / prevPrice
        }
        return roc
    }
    
    func bollingerBands(period: Int, multiplier: Double) -> BollingerBands {
        var upperBand = [Double](repeating: 0.0, count: count)
        var middleBand = [Double](repeating: 0.0, count: count)
        var lowerBand = [Double](repeating: 0.0, count: count)
        
        for i in stride(from: period, to: count, by: 1) {
            let startIndex = i - period
            let endIndex = i
            let slice = self[startIndex..<endIndex]
            let closingPrices = slice.map { $0.priceClose }
            
            let sum = closingPrices.reduce(0, +)
            let mean = sum / Double(period)
            
            let variance = closingPrices.map { pow($0 - mean, 2) }.reduce(0, +) / Double(period)
            let standardDeviation = sqrt(variance)
            
            middleBand[i] = mean
            upperBand[i] = mean + (standardDeviation * multiplier)
            lowerBand[i] = mean - (standardDeviation * multiplier)
        }
        
        return (upperBand, middleBand, lowerBand)
    }
    
    /// Calculates the Average True Range (ATR) for the candles over a specified period.
    /// ATR is a technical analysis indicator that measures market volatility by decomposing the entire range of an asset price for that period.
    /// - Parameter period: The number of periods over which to calculate the ATR.
    /// - Returns: An array of ATR values corresponding to each candle in the input array. The first few values (up to `period - 1`) will be 0, as there's not enough data to calculate the ATR.
    func averageTrueRange(period: Int) -> [Double] {
        var trValues: [Double] = []
        var atrValues: [Double] = []
        
        for i in 0..<self.count {
            let high = self[i].priceHigh
            let low = self[i].priceLow
            let close = i == 0 ? self[i].priceClose : self[i - 1].priceClose // Use the current close for the first TR calculation
            let tr = Swift.max(high - low, abs(high - close), abs(low - close))
            trValues.append(tr)
        }
        
        for i in 0..<trValues.count {
            if i < period - 1 {
                atrValues.append(0) // Not enough data to calculate ATR
            } else if i == period - 1 {
                // The first ATR value is the average of the first 'period' TR values
                let sumOfInitialTRs = trValues[0...i].reduce(0, +)
                atrValues.append(sumOfInitialTRs / Double(period))
            } else {
                // Subsequent ATR values are calculated using the formula
                let atr = (atrValues.last! * Double(period - 1) + trValues[i]) / Double(period)
                atrValues.append(atr)
            }
        }
        
        return atrValues
    }
    
    /// Calculates the Plus and Minus Directional Indicators (+DI and -DI) for the candles over a specified period.
    /// These indicators are part of the Average Directional Index (ADX) system and help determine the direction of the market trend.
    /// - Parameter period: The number of periods over which to calculate the indicators.
    /// - Returns: A tuple containing two arrays: the first for +DI values and the second for -DI values, corresponding to each candle in the input array.
    func directionalIndicators(period: Int) -> ([Double], [Double]) {
        var plusDI: [Double] = []
        var minusDI: [Double] = []
        var trValues: [Double] = []
        var plusDMValues: [Double] = []
        var minusDMValues: [Double] = []
        
        for i in 1..<self.count {
            let upMove = self[i].priceHigh - self[i - 1].priceHigh
            let downMove = self[i - 1].priceLow - self[i].priceLow
            let plusDM = Swift.max(upMove, 0) > Swift.max(downMove, 0) ? Swift.max(upMove, 0) : 0
            let minusDM = Swift.max(downMove, 0) > Swift.max(upMove, 0) ? Swift.max(downMove, 0) : 0
            let tr = Swift.max(self[i].priceHigh - self[i].priceLow, abs(self[i].priceHigh - self[i - 1].priceClose), abs(self[i].priceLow - self[i - 1].priceClose))
            trValues.append(tr)
            plusDMValues.append(plusDM)
            minusDMValues.append(minusDM)
        }
        
        // Assuming simpleMovingAverage(period:) is correctly implemented
        let atr = trValues.simpleMovingAverage(period: period)
        let accumulatedPlusDM = plusDMValues.simpleMovingAverage(period: period)
        let accumulatedMinusDM = minusDMValues.simpleMovingAverage(period: period)
        
        for i in 0..<atr.count {
            let plus = atr[i] == 0 ? 0 : 100 * accumulatedPlusDM[i] / atr[i]
            let minus = atr[i] == 0 ? 0 : 100 * accumulatedMinusDM[i] / atr[i]
            plusDI.append(plus)
            minusDI.append(minus)
        }
        
        // Pad the beginning of the arrays with zeros
        plusDI = Array<Double>(repeating: 0.0, count: period - 1) + plusDI
        minusDI = Array<Double>(repeating: 0.0, count: period - 1) + minusDI
        
        return (plusDI, minusDI)
    }
    
    /// Calculates the Average Directional Index (ADX) for a given set of candlesticks.
    ///
    /// The ADX is a technical analysis indicator used to quantify the strength of a trend.
    /// The ADX is calculated based on the moving averages of the expansion range values (DX).
    /// This function first calculates the positive and negative directional indicators (+DI and -DI) and then uses these to calculate the DX values.
    /// The ADX is then derived as an Exponential Moving Average (EMA) of these DX values.
    ///
    /// - Parameters:
    ///   - candlesticks: An array of `Candlestick` structs, each containing the open, high, low, and close prices for a given period.
    ///   - period: The number of periods to use for calculating the +DI, -DI, and ultimately the ADX.
    /// - Returns: An array of Double values representing the ADX values for each period in the input array. The first few entries (up to `period - 1`) will be 0, as there's not enough data to calculate the ADX.
    func averageDirectionalIndex(period: Int) -> [Double] {
        let (plusDI, minusDI) = self.directionalIndicators(period: period)
        var dxValues: [Double] = []
        
        for i in 0..<plusDI.count {
            let dx = 100 * abs(plusDI[i] - minusDI[i]) / (plusDI[i] + minusDI[i])
            dxValues.append(dx)
        }
        
        return dxValues.exponentialMovingAverage(period: period)
    }
    
    /// Calculates the Relative Strength Index (RSI) for the candles over a specified period.
    /// RSI is a momentum oscillator that measures the speed and change of price movements.
    /// - Parameter period: The number of periods over which to calculate the RSI.
    /// - Returns: An array of RSI values corresponding to each candle in the input array. The first few values (up to `period - 1`) will be 0, as there's not enough data to calculate the RSI.
    func relativeStrengthIndex(period: Int) -> [Double] {
        var rsi = [Double](repeating: 0.0, count: count)
        var gains = 0.0
        var losses = 0.0
        
        for i in 1..<period {
            let change = self[i].priceClose - self[i - 1].priceClose
            if change > 0 {
                gains += change
            } else {
                losses -= change
            }
        }
        
        var averageGain = gains / Double(period)
        var averageLoss = losses / Double(period)
        
        if averageLoss == 0 {
            rsi[period - 1] = 100
        } else {
            let rs = averageGain / averageLoss
            rsi[period - 1] = 100 - (100 / (1 + rs))
        }
        
        for i in period..<count {
            let change = self[i].priceClose - self[i - 1].priceClose
            let gain = Swift.max(change, 0)
            let loss = Swift.max(-change, 0)
            
            averageGain = ((averageGain * Double(period - 1)) + gain) / Double(period)
            averageLoss = ((averageLoss * Double(period - 1)) + loss) / Double(period)
            
            if averageLoss == 0 {
                rsi[i] = 100
            } else {
                let rs = averageGain / averageLoss
                rsi[i] = 100 - (100 / (1 + rs))
            }
        }
        
        return rsi
    }
}
