/// A protocol defining the core structure for a trading strategy.
///
/// Each strategy can have multiple charts, various indicators, and phases.
/// It supports both single-chart and multi-chart strategies.
public protocol Strategy: Sendable, Versioned {    
    /// The list of historical candlestick data per chart (Symbol -> Klines).
    var charts: [[Klines]] { get }
    
    /// The chart scales per chart (Symbol -> Scale).
    var resolution: [Scale] { get }
    
    /// The detected market phases for each chart.
    var distribution: [[Phase]] { get }
    
    /// The computed indicators for each chart (Symbol -> Indicator Name -> Values).
    /// `indicators.count` has to match `charts.count`
    var indicators: [[String: [Double]]] { get }
    
    /// The computed support and resistance levels for each chart.
    var levels: [Level] { get }
    
    /// Indicates whether a recognizable trading pattern has been identified.
    var patternIdentified: Signal? { get }
    
    /// A dictionary containing additional information about detected patterns.
    var patternInformation: [String: Double] { get }
    
    /// Initializes a strategy with given sets of candlestick data.
    init(candles: [Klines])
    
    /// Evaluates the number of units/contracts to trade based on available capital.
    func shouldEnterWitUnitCount(
        signal: Signal,
        entryBar: Klines,
        equity: Double,
        tickValue: Double,
        tickSize: Double,
        feePerUnit cost: Double,
        nextAnnouncment announcment: Annoucment?
    ) -> Int
    
    /// the stop-loss and take profit targets for  market.
    func exitTargets(for signal: Signal, entryBar: Klines) -> (takeProfit: Double?, stopLoss: Double?)
    
    /// Determines whether the trade should be exited based on strategy conditions.
    func shouldExit(signal: Signal, entryBar: Klines, nextAnnouncment announcment: Annoucment?) -> Bool
}

public extension Strategy {
    var candles: [Klines] {
        charts.first ?? []
    }
}
