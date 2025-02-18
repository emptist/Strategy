public protocol DecisionEngineProtocol {
    associatedtype MarketData
    func evaluateEntry(marketData: MarketData) -> Bool
}
