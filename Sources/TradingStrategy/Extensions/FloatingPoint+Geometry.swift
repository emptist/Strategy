import Foundation

public extension FloatingPoint {
    var toDegrees: Self {
        return self * 180 / .pi
    }

    var toRadians: Self {
        return self * .pi / 180
    }
}
