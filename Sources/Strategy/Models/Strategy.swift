import Foundation

public protocol Strategy {
    var recentCandlesSize: Int { get }
    var recentCandlesPatternPrediction: Bool { get }
    var patternIdentified: Bool { get }
    
    init(candles: [Klines], multiplier: Int)
}
