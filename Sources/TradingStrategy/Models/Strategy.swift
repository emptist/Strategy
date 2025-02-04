import Foundation

public protocol Strategy {
    var candles: [Klines] { get }
    var phases: [Phase] { get }
    var longTermMA: [Double] { get }
    var shortTermMA: [Double] { get }
    var phaseTermMa: [Double] { get }
    
    var patternIdentified: Bool { get }
    var patterInformatioin: [String: Bool] { get }
    
    init(candles: [Klines])
    init(candles: [Klines], multiplier: Int)
}
