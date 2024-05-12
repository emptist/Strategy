import Foundation

public extension CGPoint {
    func angleLineToXAxis(_ p2: CGPoint) -> Double {
        return atan2((y - p2.y), (x - p2.x)).toDegrees
    }
}
