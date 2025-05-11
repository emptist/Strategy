/// Patter recognition signal, with value between 0-1 indicating confidence
public enum Signal: Sendable {
    case buy(confidence: Float)
    case sell(confidence: Float)
}
