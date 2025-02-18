protocol PositionManagerProtocol {
    associatedtype Position
    associatedtype MarketData
    func adjustStopLoss(position: Position, marketData: MarketData) -> Double
    func adjustTakeProfit(position: Position, marketData: MarketData) -> Double
    func shouldExit(position: Position, marketData: MarketData) -> Bool
}
