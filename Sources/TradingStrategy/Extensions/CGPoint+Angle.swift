import Foundation

public extension CGPoint {
    func angleLineToXAxis(_ p2: CGPoint) -> Double {
        return atan2(p2.y - y, p2.x - x).toDegrees
    }
}
