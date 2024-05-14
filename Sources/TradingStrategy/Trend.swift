import Foundation

public enum Trend: CustomStringConvertible, Equatable {
    public var description: String {
        if isUpTrend {
            return "⬆ \(String(describing: momentum))"
        }
        return "⬇ \(String(describing: momentum))"
    }
    
    case up(Momentum)
    case down(Momentum)
    
    public var isUpTrend: Bool {
        switch self {
        case .up:
            return true
        case .down:
            return false
        }
    }

    public var momentum: Momentum {
        switch self {
        case .up(let momentum):
            return momentum
        case .down(let momentum):
            return momentum
        }
    }
    
    static public func !=(lhs: Trend, rhs: Trend) -> Bool {
        return lhs.isUpTrend != rhs.isUpTrend
        || lhs.momentum != rhs.momentum
    }
}

public enum Momentum {
    case strong, increasing, flat
    
    public func isSuprise(to: Momentum) -> Bool {
        switch self {
        case .strong:
            return to != .strong
        case .increasing, .flat:
            return to == .strong
        }
    }
}

public extension [CGPoint] {
    func movingAverageTrend() -> Trend {
        var trend: Trend = .up(.flat)
        
        if count > 3 {
            let p1 = self[count - 1]
            let p3 = self[count - 4]
            let angle  = p1.angleLineToXAxis(p3)
            
            if angle > 0 {
                trend = .down(angle.momentum)
            } else {
                trend = .up(angle.momentum)
            }
        }
        return trend
    }

}
