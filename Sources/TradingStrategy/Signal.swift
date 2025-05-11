/// Patter recognition signal, with value between 0-1 indicating confidence
public enum Signal: Sendable {
    case buy(Float)
    case sell(Float)
}
