public protocol PositionManagerProtocol {
    associatedtype YourStrategy: Strategy
    
    /// Adjusts the stop-loss level based on market conditions.
    /// - Parameters:
    ///   - entryBar: The candlestick data at the time of trade entry.
    ///   - marketData: The latest market data.
    /// - Returns: The updated stop-loss price, or nil if no-stop loss
    static func adjustStopLoss(entryBar: Klines, strategy: YourStrategy) -> Double?
    
    /// Determines whether the trade should be exited.
    /// - Parameters:
    ///   - entryBar: The candlestick data at the time of trade entry.
    ///   - marketData: The latest market data.
    /// - Returns: A boolean indicating whether to exit the trade.
    static func shouldExit(entryBar: Klines, strategy: YourStrategy) -> Bool
}
