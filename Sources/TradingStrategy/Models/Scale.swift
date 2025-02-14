import Foundation

public struct Scale: Equatable {
    public var x: Range<TimeInterval>
    public var y: Range<Double>
    
    public init(
        x: Range<TimeInterval> = Date().addingTimeInterval(-3600).timeIntervalSince1970..<Date().timeIntervalSince1970,
        y: Range<Double> = 40000..<50000
    ) {
        self.x = x
        self.y = y
    }
    
    public init(
        data: [Klines],
        interval: TimeInterval,
        candlesPerScreen: Int = 80
    ) {
        guard !data.isEmpty else {
            self.init()
            return
        }
        
        let now = (data.last?.timeOpen ?? Date().timeIntervalSince1970) + (interval * 4)
        let from = interval * Double(candlesPerScreen)
        var xScaleStart: TimeInterval
        var yScaleStart: Double
        var yScaleEnd: Double
        if data.count > candlesPerScreen {
            xScaleStart = data[data.count - candlesPerScreen].timeOpen
            yScaleStart = data[data.count - candlesPerScreen ..< data.count].min(by: { $0.priceLow < $1.priceLow })?.priceLow ?? -100
            yScaleEnd = data[data.count - candlesPerScreen ..< data.count].max(by: { $0.priceHigh < $1.priceHigh })?.priceHigh ?? 100
        } else {
            xScaleStart = TimeInterval(now - from)
            yScaleStart = data.min(by: { $0.priceLow < $1.priceLow })?.priceLow ?? -100
            yScaleEnd = data.max(by: { $0.priceHigh < $1.priceHigh })?.priceHigh ?? 100
        }
        
        if yScaleStart > yScaleEnd {
            // Swap values if the start is greater than the end
            swap(&yScaleStart, &yScaleEnd)
        }
        
        let verticalPadding = (yScaleEnd - yScaleStart) * 0.2
        yScaleStart -= verticalPadding
        yScaleEnd += verticalPadding
        
        self.init(
            x: xScaleStart ..< TimeInterval(now),
            y: yScaleStart ..< yScaleEnd
        )
    }
    
    public var xGuideStep: TimeInterval {
        (x.upperBound - x.lowerBound) / 5
    }
    
    public var yGuideStep: Double {
        (y.upperBound - y.lowerBound) / 10
    }
    
    public var xAmplitiude: Double {
        Swift.max(0.001, (x.upperBound - x.lowerBound))
    }
    
    public var yAmplitiude: Double {
        Swift.max(0.001, Double(y.upperBound - y.lowerBound))
    }
    
    public var amplitiude: CGSize {
        .init(width: xAmplitiude, height: yAmplitiude)
    }
    
    public func x(_ x: Double, size: CGSize) -> Double {
        (x - self.x.lowerBound) / xAmplitiude * size.width
    }
    
    public func y(_ y: Double, size: CGSize) -> Double {
        (Double(self.y.upperBound) - y) / yAmplitiude * size.height
    }
    
    public func width(_ width: Double, size: CGSize) -> Double {
        guard !width.isNaN, !size.width.isNaN else { return 0 }
        return width / xAmplitiude * size.width
    }
    
    public func timeInterval(x value: Double, size: CGSize) -> TimeInterval {
        guard !value.isNaN, !size.width.isNaN, size.width != 0 else { return x.lowerBound }
        return x.lowerBound + (value / size.width) * xAmplitiude
    }
    
    public func timeInterval(fromLength length: Double, size: CGSize) -> TimeInterval {
        guard !length.isNaN, !size.width.isNaN, size.width != 0 else { return 0 }
        return (length / size.width) * xAmplitiude
    }
    
    public func height(_ height: Double, size: CGSize) -> Double {
        guard !height.isNaN, !size.height.isNaN else { return 0 }
        return height / yAmplitiude * size.height
    }
    
    public func price(fromHeight height: Double, size: CGSize) -> Double {
        guard !height.isNaN, !size.height.isNaN, size.height != 0 else { return y.upperBound }
        return y.upperBound - (height / size.height) * yAmplitiude
    }

}
