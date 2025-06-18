import Foundation

public typealias BollingerBands = (upperBand: [Double], middleBand: [Double], lowerBand: [Double])

public struct MACDResult {
    public let macd: [Double]
    public let signal: [Double]
    public let histogram: [Double]
}


public enum PricePattern: String, Sendable {
    case high = "H"       // High: Higher high than the previous candle
    case low = "L"        // Low: Lower low than the previous candle
    case higherHigh = "HH" // Higher High: Higher high than the previous high
    case higherLow = "HL"  // Higher Low: Higher low than the previous low
    case lowerHigh = "LH"  // Lower High: Lower high than the previous high
    case lowerLow = "LL"   // Lower Low: Lower low than the previous low
}

public extension [Klines] {
    func lastPricePattern(window: Int = 9) -> [(index: Int, pattern: PricePattern)] {
        guard count > window * 2 else { return [] }
        
        @inline(__always)
        func isPivotHigh(at i: Int) -> Bool {
            let center = self[i].priceHigh
            for j in (i - window)...(i + window) where j != i {
                if self[j].priceHigh >= center { return false }
            }
            return true
        }
        
        @inline(__always)
        func isPivotLow(at i: Int) -> Bool {
            let center = self[i].priceLow
            for j in (i - window)...(i + window) where j != i {
                if self[j].priceLow <= center { return false }
            }
            return true
        }
        
        var pivots: [(index: Int, pattern: PricePattern)] = []
        var direction: PricePattern? = nil
        
        for i in stride(from: count - window - 1, through: window, by: -1) {
            if isPivotHigh(at: i) {
                if direction == .low { break }
                pivots.append((i, .high))
                direction = .high
            } else if isPivotLow(at: i) {
                if direction == .high { break }
                pivots.append((i, .low))
                direction = .low
            }
        }
        
        guard !pivots.isEmpty else { return [] }
        
        var patterns: [(index: Int, pattern: PricePattern)] = []
        var lastValue: Double? = nil
        
        for (i, base) in pivots.reversed() {
            switch base {
            case .high:
                if lastValue == nil {
                    patterns.append((i, .high))
                } else {
                    patterns.append((i, self[i].priceHigh > lastValue! ? .higherHigh : .lowerHigh))
                }
                lastValue = self[i].priceHigh
                
            case .low:
                if lastValue == nil {
                    patterns.append((i, .low))
                } else {
                    patterns.append((i, self[i].priceLow > lastValue! ? .higherLow : .lowerLow))
                }
                lastValue = self[i].priceLow
                
            default:
                break
            }
        }
        
        return patterns
    }
    
    func macd(fast: Int = 12, slow: Int = 26, signal: Int = 9) -> MACDResult {
        guard count >= slow + signal else {
            return MACDResult(macd: [], signal: [], histogram: [])
        }

        let closes = self.map(\.priceClose)
        let fastEMA = closes.exponentialMovingAverage(period: fast)
        let slowEMA = closes.exponentialMovingAverage(period: slow)

        let macdLine = zip(fastEMA, slowEMA).map { $0 - $1 }
        let signalLine = macdLine.exponentialMovingAverage(period: signal)

        // Pad signal line to align with macd line length
        let paddedSignal = Array<Double>(repeating: Double.nan, count: macdLine.count - signalLine.count) + signalLine
        let histogram = zip(macdLine, paddedSignal).map { $0 - ($1.isNaN ? 0 : $1) }

        return MACDResult(macd: macdLine, signal: paddedSignal, histogram: histogram)
    }

    // Calculate Simple Moving Average (SMA)
    func simpleMovingAverage(_ period: Int) -> Double? {
        // Ensure we have enough candles to calculate the SMA
        guard count >= period else { return nil }
        
        // Sum up the closing prices of the last 'period' candles
        let sum = self.suffix(period).reduce(0.0) { $0 + $1.priceClose }
        
        // Divide by the period to get the average
        return sum / Double(period)
    }
    
    func simpleMovingAverage(period: Int) -> [Double] {
        var smaValues: [Double] = []
        
        for i in 0..<self.count {
            if i < period - 1 {
                smaValues.append(0) // Not enough data to calculate SMA
            } else {
                let sum = self[(i - period + 1)...i].reduce(0.0) { $0 + $1.priceClose }
                let average = sum / Double(period)
                smaValues.append(average)
            }
        }
        
        return smaValues
    }
    
    func triangularMovingAverage(period: Int) -> [Double] {
        simpleMovingAverage(period: period)
            .simpleMovingAverage(period: period)
    }
    
    func exponentialMovingAverage(period: Int) -> [Double] {
        guard count >= period else { return Array<Double>(repeating: 0, count: count) }
        
        // Initialize the first EMA value with the SMA of the first 'period' candles
        var emaValues: [Double] = Array(prefix(period)).simpleMovingAverage(period: period)
        let smoothingFactor = 2.0 / (Double(period) + 1.0)
        
        // Calculate EMA for the rest of the candles
        for i in period..<count {
            let currentPrice = self[i].priceClose
            let previousEMA = emaValues.last ?? currentPrice
            let ema = (currentPrice * smoothingFactor) + (previousEMA * (1 - smoothingFactor))
            emaValues.append(ema)
        }
        
        return emaValues
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
            let closingPrices = self[startIndex..<endIndex].map { $0.priceClose }
            
            let sum = closingPrices.reduce(0, +)
            let mean = sum / Double(period)
            
            let slice2 = closingPrices.map { pow($0 - mean, 2) }
            let variance = slice2.reduce(0, +) / Double(period)
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
                let slice = trValues[0...i]
                let sumOfInitialTRs = slice.reduce(0, +)
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
        guard count > 1 else { return ([],[]) }
        
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
    
    /// Calculates the Average True Range (ATR) for a given period.
    /// Returns only the **latest ATR value**, optimized for real-time use.
    func computeATR(period: Int = 14) -> Double {
        let atrValues = averageTrueRange(period: period)
        return atrValues.last ?? 0.0
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
            let diff = (plusDI[i] + minusDI[i])
            if diff != 0 {
                let dx = 100 * abs(plusDI[i] - minusDI[i]) / diff
                dxValues.append(dx)
            } else {
                dxValues.append(0)
            }
        }
        
        return dxValues.exponentialMovingAverage(period: period)
    }
    
    /// Calculates the Relative Strength Index (RSI) for the candles over a specified period.
    /// RSI is a momentum oscillator that measures the speed and change of price movements.
    /// - Parameter period: The number of periods over which to calculate the RSI.
    /// - Returns: An array of RSI values corresponding to each candle in the input array. The first few values (up to `period - 1`) will be 0, as there's not enough data to calculate the RSI.
    func relativeStrengthIndex(period: Int) -> [Double] {
        guard count > period else { return [] }
        
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
    
    func sidelines(
        bollingerPeriod: Int,
        adxPeriod: Int,
        rsiPeriod: Int
    ) -> [Bool] {
        let bollingerBands = bollingerBands(period: bollingerPeriod, multiplier: 2.0)
        let adx = averageDirectionalIndex(period: adxPeriod)
        let rsi = relativeStrengthIndex(period: rsiPeriod)
        return indices.map { index in
            // Ensure sufficient data for Bollinger Bands, ADX, and RSI
            guard index >= bollingerPeriod,
                  index >= adxPeriod,
                  index >= rsiPeriod else { return false }
            
            // Bollinger Bands Condition
            let price = self[index].priceClose
            let inBollingerRange = price > bollingerBands.lowerBand[index] + 0.2 * (bollingerBands.upperBand[index] - bollingerBands.lowerBand[index]) &&
            price < bollingerBands.upperBand[index] - 0.2 * (bollingerBands.upperBand[index] - bollingerBands.lowerBand[index])
            
            // ADX Condition
            let adxBelowThreshold = adx[index] < 30
            
            // RSI Condition
            let rsiNeutral = rsi[index] > 40 && rsi[index] < 60
            
            // Return true only if at least two conditions are satisfied
            let trueConditions = [inBollingerRange, adxBelowThreshold, rsiNeutral].filter { $0 }.count
            return trueConditions > 1
        }
    }
    
    // MARK: Compute VWAP
    
    func computeVWAP() -> [Double] {
        var cumulativeVWAP: [Double] = []
        var cumulativeVolume: Double = 0
        var cumulativePriceVolume: Double = 0
        
        for candle in self {
            guard let volume = candle.volume else { continue }
            cumulativeVolume += volume
            cumulativePriceVolume += ((candle.priceHigh + candle.priceLow + candle.priceClose) / 3.0) * volume
            cumulativeVWAP.append(cumulativePriceVolume / cumulativeVolume)
        }
        return cumulativeVWAP
    }
}
