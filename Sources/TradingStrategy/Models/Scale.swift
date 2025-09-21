import Foundation

extension Double {
    public func yToPoint(
        atIndex index: Int,
        scale: Scale,
        canvasSize size: CGSize
    ) -> CGPoint {
        .init(
            x: scale.x(index, size: size),
            y: scale.y(self, size: size)
        )
    }
}

public struct Scale: Sendable, Equatable {
    public var x: Range<Int>
    public var y: Range<Double>
    public let candlesPerScreen: Int
    
    public init(
        x: Range<Int> = 0..<80,
        y: Range<Double> = 40000..<50000,
        candlesPerScreen: Int = 80
    ) {
        self.x = x
        self.y = y
        self.candlesPerScreen = candlesPerScreen
    }
    
    public init(data: [any Klines], candlesPerScreen: Int = 80) {
        guard !data.isEmpty else {
            self.init()
            return
        }
        
        let xScale = (max(0, data.count - candlesPerScreen)) ..< (max(data.count, 80))
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
        
        self.init(x: xScale, y: yScaleStart ..< yScaleEnd, candlesPerScreen: candlesPerScreen)
    }
    
    public var xGuideStep: Int {
        (x.upperBound - x.lowerBound) / 5
    }
    
    public var yGuideStep: Double {
        (y.upperBound - y.lowerBound) / 10.0
    }
    
    public var xAmplitude: Double {
        Swift.max(0.001, Double(x.upperBound - x.lowerBound))
    }
    
    public var yAmplitude: Double {
        Swift.max(0.001, Double(y.upperBound - y.lowerBound))
    }
    
    public var amplitiude: CGSize {
        .init(width: xAmplitude, height: yAmplitude)
    }
    
    public func x(_ index: Int, size: CGSize) -> Double {
        Double(index - self.x.lowerBound) / xAmplitude * size.width
    }
    
    public func y(_ y: Double, size: CGSize) -> Double {
        (Double(self.y.upperBound) - y) / yAmplitude * size.height
    }
    
    public func width(_ candleCount: Int, size: CGSize) -> Double {
        guard !size.width.isNaN else { return 0 }
        return (Double(candleCount) / xAmplitude) * size.width
    }
    
    public func index(forX xValue: Double, size: CGSize) -> Int {
        guard !xValue.isNaN, !size.width.isNaN, size.width != 0 else { return x.lowerBound }
        let index = x.lowerBound + Int((xValue / size.width) * xAmplitude)
        return min(max(x.lowerBound, index), x.upperBound - 1)
    }
    
    public func barCount(forLength length: Double, size: CGSize) -> Int {
        guard !length.isNaN, !size.width.isNaN, size.width != 0 else { return 1 }
        return max(1, Int((length / size.width) * xAmplitude))
    }
    
    public func height(_ height: Double, size: CGSize) -> Double {
        guard !height.isNaN, !size.height.isNaN else { return 0 }
        return height / yAmplitude * size.height
    }
    
    public func price(fromHeight height: Double, size: CGSize) -> Double {
        guard !height.isNaN, !size.height.isNaN, size.height != 0 else { return y.upperBound }
        return y.upperBound - (height / size.height) * yAmplitude
    }
}
