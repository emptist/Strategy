import Foundation

public protocol Annoucment: Sendable {
    var interval: TimeInterval  { get }
    var impact: Impact { get }
}

public enum Impact {
    case high
    case medium
    case low
}
