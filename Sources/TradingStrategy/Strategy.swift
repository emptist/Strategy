import Foundation

public protocol Strategy {
    var candles: [Klines] { get }
    var phases: [Phase] { get }
    var longTermMA: [Double] { get }
    var shortTermMA: [Double] { get }
    
    var supportBars: [Klines] { get }
    var supportPhases: [Phase] { get }
    var supportScale: Scale { get }
    var levels: SupportResistance { get }
    
    var patternIdentified: Bool { get }
    var patterInformatioin: [String: Bool] { get }
    
    init(candles: [Klines])
}
