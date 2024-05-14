import XCTest
@testable import TradingStrategy

final class MovingAverageTests: XCTestCase {
    
    func testSMA() {
        // Test data
        let testValues: [Double] = [22, 23, 24, 25, 26, 27, 28, 29, 30, 31]
        // Expected results for SMA with period 5
        let expectedSMA5: [Double] = [0, 0, 0, 0, 24, 25, 26, 27, 28, 29]
        
        // Calculate SMA
        let smaResults = testValues.simpleMovingAverage(period: 5)
        
        // Assert equal with a tolerance, since we're dealing with floating point numbers
        for (index, sma) in smaResults.enumerated() {
            XCTAssertEqual(sma, expectedSMA5[index], accuracy: 0.001, "SMA value at index \(index) is incorrect")
        }
    }
    
    func testEMA() {
        let test: [(period: Int, testValues: [Double], expectedEMA5: [Double])] = [
            (
                5,
                [22, 23, 24, 25, 26, 27, 28, 29, 30, 31],
                [0.0, 0.0, 0.0, 0.0, 24.0, 25.0, 26.0, 27.0, 28.0, 29.0]
            ),
            (
                3,
                [22.15, 22.34, 22.52, 22.75, 22.95, 23.18, 23.36, 23.55, 23.75, 23.92],
                [0, 0, 22.34, 22.54, 22.75, 22.96, 23.16, 23.36, 23.55, 23.74]
            )
        ]
        
        for data in test {
            // Calculate EMA
            let emaResults = data.testValues.exponentialMovingAverage(period: data.period)
            print(data.expectedEMA5)
            print(emaResults)
            // Assert equal with a tolerance, since we're dealing with floating point numbers
            for (index, ema) in emaResults.enumerated() {
                XCTAssertEqual(ema, data.expectedEMA5[index], accuracy: 0.01, "EMA value at index \(index) is incorrect")
            }
        }
    }
}

