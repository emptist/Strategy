/// Patter recognition signal, with value between 0-1 indicating confidence
public enum Signal: Sendable, Hashable {
    case buy(confidence: Float)
    case sell(confidence: Float)
}

public extension Signal {
    var isLong: Bool {
        switch self {
        case .buy: true
        case .sell: false
        }
    }
    
    var confidence: Float {
        switch self {
        case .buy(confidence: let c): c
        case .sell(confidence: let c): c
        }
    }
}
