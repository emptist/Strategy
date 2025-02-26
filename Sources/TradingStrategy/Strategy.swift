import Foundation

/// A protocol defining the core structure for a trading strategy.
///
/// Implementing strategies must provide market data analysis, trade entry evaluation,
/// stop-loss adjustments, and exit conditions to facilitate systematic trading.
public protocol Strategy {
    
    /// The list of historical candlestick data used by the strategy.
    var candles: [Klines] { get }
    
    /// The detected market phases based on price action and trend analysis.
    var phases: [Phase] { get }
    
    /// The long-term moving averages used for trend identification.
    var longTermMA: [Double] { get }
    
    /// The short-term moving averages used for dynamic price tracking.
    var shortTermMA: [Double] { get }
    
    /// Candlestick data used for identifying support levels.
    var supportBars: [Klines] { get }
    
    /// Market phases that are considered significant for support detection.
    var supportPhases: [Phase] { get }
    
    /// The scale used for measuring support and resistance levels.
    var supportScale: Scale { get }
    
    /// The computed support and resistance levels in the market.
    var levels: SupportResistance { get }
    
    /// Indicates whether a recognizable trading pattern has been identified.
    var patternIdentified: Bool { get }
    
    /// A dictionary containing additional information about detected patterns.
    /// - Keys: Descriptive names of the patterns.
    /// - Values: Boolean values indicating whether the pattern is present.
    var patternInformation: [String: Bool] { get }
    
    /// Initializes a strategy with a given set of candlestick data.
    /// - Parameter candles: The list of market candlesticks to be analyzed by the strategy.
    init(candles: [Klines])
    
    /// Evaluates the number of units/contracts to trade based on available capital and market conditions.
    /// - Parameter portfolio: The total trading capital available (in USD).
    /// - Returns: The number of units/contracts to trade. Returns 0 if no trade should be taken.
    func unitCount(equity: Double) -> Int
    
    /// Adjusts the stop-loss level dynamically based on market conditions.
    /// - Parameter entryBar: The candlestick representing the trade entry point.
    /// - Returns: The new stop-loss price if applicable, otherwise nil.
    func adjustStopLoss(entryBar: Klines) -> Double?
    
    /// Determines whether the trade should be exited based on strategy conditions.
    /// - Parameter entryBar: The candlestick representing the trade entry point.
    /// - Returns: `true` if the trade should be exited, otherwise `false`.
    func shouldExit(entryBar: Klines) -> Bool
}
