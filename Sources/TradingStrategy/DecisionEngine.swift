import Foundation

/// A protocol defining a decision engine for evaluating trade entry conditions.
public protocol DecisionEngineProtocol {
    associatedtype YourStrategy: Strategy

    /// Evaluates the number of contracts or units that can be traded based on available capital and market conditions.
    /// - Parameters:
    ///   - portfolio: The total available capital in AUD for trading.
    ///   - marketData: The market data containing price action, technical indicators, and relevant trade conditions.
    /// - Returns: The number of contracts or units that can be traded while considering costs, fees, and tax implications.
    static func evaluateEntry(portfolio: Double, strategy: YourStrategy) -> Int
}
