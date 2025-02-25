import Foundation

public struct Scale: Equatable {
    public var x: Range<Int>
    public var y: Range<Double>
    
    public init(x: Range<Int> = 0..<80, y: Range<Double> = 40000..<50000) {
        self.x = x
        self.y = y
    }
    
    public init(data: [Klines], candlesPerScreen: Int = 80) {
        guard !data.isEmpty else {
            self.init()
            return
        }
        
        var xScale = max(0, data.count - candlesPerScreen) ..< max(data.count, 80)
        var yScaleStart: Double
        var yScaleEnd: Double
        if data.count > candlesPerScreen {
            yScaleStart = data[data.count - candlesPerScreen ..< data.count].min(by: { $0.priceLow < $1.priceLow })?.priceLow ?? -100
            yScaleEnd = data[data.count - candlesPerScreen ..< data.count].max(by: { $0.priceHigh < $1.priceHigh })?.priceHigh ?? 100
        } else {
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
        
        self.init(x: xScale, y: yScaleStart ..< yScaleEnd)
    }
    
    public var xGuideStep: Int {
        (x.upperBound - x.lowerBound) / 5
    }
    
    public var yGuideStep: Double {
        (y.upperBound - y.lowerBound) / 10.0
    }
    
    public var xAmplitiude: Double {
        Swift.max(0.001, Double(x.upperBound - x.lowerBound))
    }
    
    public var yAmplitiude: Double {
        Swift.max(0.001, Double(y.upperBound - y.lowerBound))
    }
    
    public var amplitiude: CGSize {
        .init(width: xAmplitiude, height: yAmplitiude)
    }
    
    public func x(_ index: Int, size: CGSize) -> Double {
        Double(index - self.x.lowerBound) / xAmplitiude * size.width
    }
    
    public func y(_ y: Double, size: CGSize) -> Double {
        (Double(self.y.upperBound) - y) / yAmplitiude * size.height
    }
    
    public func width(_ candleCount: Int, size: CGSize) -> Double {
        guard !size.width.isNaN else { return 0 }
        return (Double(candleCount) / xAmplitiude) * size.width
    }
    
    public func index(forX xValue: Double, size: CGSize) -> Int {
        guard !xValue.isNaN, !size.width.isNaN, size.width != 0 else { return x.lowerBound }
        let index = x.lowerBound + Int((xValue / size.width) * xAmplitiude)
        return min(max(x.lowerBound, index), x.upperBound - 1)
    }
    
    public func barCount(forLength length: Double, size: CGSize) -> Int {
        guard !length.isNaN, !size.width.isNaN, size.width != 0 else { return 1 }
        return max(1, Int((length / size.width) * xAmplitiude))
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
