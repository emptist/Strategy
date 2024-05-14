import Foundation

public extension Array where Element: FloatingPoint {
    func average() -> Element {
        guard !isEmpty else { return 0 }
        let sum = reduce(0, +)
        return sum / Element(count)
    }
}

public extension Array {
    func chunks(_ chunkSize: Int) -> [[Element]] {
        guard chunkSize < count else { return self.map({ [$0] }) }
        return stride(from: 0, to: self.count, by: chunkSize).map {
            Array(self[$0..<Swift.min($0 + chunkSize, self.count)])
        }
    }
}
