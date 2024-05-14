import Foundation

public extension FloatingPoint {
    var toDegrees: Self {
        return self * 180 / .pi
    }

    var toRadians: Self {
        return self * .pi / 180
    }
    
    var momentum: Momentum {
        var momentum: Momentum = .flat
        
        switch abs(self) {
        case let x where x > 45:
            momentum = .strong
        case let x where x <= 45 && x > 15:
            momentum = .increasing
        default:
            break
        }

        return momentum
    }
}
