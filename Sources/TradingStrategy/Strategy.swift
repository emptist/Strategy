/// A protocol defining the core structure for a trading strategy.
///
/// Each strategy can have multiple charts, various indicators, and phases.
/// It supports both single-chart and multi-chart strategies.
public protocol Strategy: Sendable, Versioned {
    /// A string containing the name of the strategy.
    var name: String { get }
    
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
    var patternIdentified: Bool { get }
    
    /// A dictionary containing additional information about detected patterns.
    var patternInformation: [String: Bool] { get }
    
    /// Initializes a strategy with given sets of candlestick data.
    init(candles: [Klines])
    
    /// Evaluates the number of units/contracts to trade based on available capital.
    func shouldEnterWitUnitCount(
        entryBar: Klines,
        equity: Double,
        feePerUnit cost: Double,
        nextAnnoucment annoucment: Annoucment?
    ) -> Int
    
    /// Adjusts the stop-loss level dynamically based on market conditions.
    func adjustStopLoss(entryBar: Klines) -> Double?
    
    /// Determines whether the trade should be exited based on strategy conditions.
    func shouldExit(entryBar: Klines, nextAnnoucment annoucment: Annoucment?) -> Bool
}

public extension Strategy {
    var candles: [Klines] {
        charts.first ?? []
    }
}
