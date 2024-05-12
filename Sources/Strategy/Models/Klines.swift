import Foundation

public protocol Klines {
    var timeOpen: TimeInterval { get set }
    var interval: TimeInterval  { get set }

    var priceOpen: Double  { get set }
    var priceHigh: Double  { get set }
    var priceLow: Double  { get set }
    var priceClose: Double  { get set }
}

public extension Klines {
    var isLong: Bool {
        priceOpen <= priceClose
    }
    
    /// Time of the center
    var timeCenter: Double {
        return timeOpen + (interval / 2)
    }
    
    var timeClose: Double {
        return timeOpen + interval
    }
    
    var duration: Double {
        return interval
    }
    
    var body: Double {
        isLong ? priceClose - priceOpen : priceOpen - priceClose
    }
    
    var centerPrice: Double {
        priceOpen + (priceClose - priceOpen) / 2.0
    }
    
    var upperWick: Double {
        isLong ? priceHigh - priceClose : priceHigh - priceOpen
    }
    
    var lowerWick: Double {
        isLong ? priceOpen - priceLow : priceClose - priceLow
    }
}
