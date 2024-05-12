import XCTest
@testable import TradeWithIt

final class PhaseTests: XCTestCase {
    func testPhaseGroupingWithNoise() {
        let phaseTypes: [PhaseType] = [.time, .time, .time, .time, .price, .price, .time, .time, .time, .price, .time]
        let expectedGroups = [
            Phase(type: .time, range: 0...10) // Last 'time' series including one 'price' as noise
        ]
        
        let actualGroups = phaseTypes.group(ignoringNoiseUpTo: 3)
        
        XCTAssertEqual(actualGroups, expectedGroups, "The actual groups should match the expected groups, with noise being ignored up to a threshold of 3.")
    }
    
    func testPhaseGroupingWithoutNoise() {
        let phaseTypes: [PhaseType] = [.time, .time, .price, .price, .time, .time]
        let expectedGroups = [
            Phase(type: .time, range: 0...1),
            Phase(type: .price, range: 2...3),
            Phase(type: .time, range: 4...5)
        ]
        
        let actualGroups = phaseTypes.group(ignoringNoiseUpTo: 0) // Setting noise threshold to 0
        
        XCTAssertEqual(actualGroups, expectedGroups, "The actual groups should match the expected groups, with no noise being ignored.")
    }
    
    func testPhaseGroupingWithNoiseAtEnd() {
        let phaseTypes: [PhaseType] = [.time, .time, .time, .price, .time]
        let expectedGroups = [
            Phase(type: .time, range: 0...4)  // All as 'time' with 'price' being considered as noise
        ]
        
        let actualGroups = phaseTypes.group(ignoringNoiseUpTo: 1)
        
        XCTAssertEqual(actualGroups, expectedGroups, "The actual groups should match the expected groups, including noise at the end.")
    }
    
    func testPhaseGroupingWithoutNoiseAndPositiveTreshold() {
        let phaseTypes: [PhaseType] = [.time, .time, .time, .time, .price, .price, .price, .price, .time, .time, .time, .time]
        let expectedGroups = [
            Phase(type: .time, range: 0...3),
            Phase(type: .price, range: 4...7),
            Phase(type: .time, range: 8...11)
        ]
        
        let actualGroups = phaseTypes.group(ignoringNoiseUpTo: 3) // Setting noise threshold to 3
        
        XCTAssertEqual(actualGroups, expectedGroups, "The actual groups should match the expected groups, with no noise being ignored.")
    }
}
