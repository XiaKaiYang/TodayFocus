import XCTest
@testable import FocusSessionCore

final class DomainModelTests: XCTestCase {
    func testFocusSessionRecordDurationUsesEndMinusStart() throws {
        let start = Date(timeIntervalSince1970: 0)
        let end = Date(timeIntervalSince1970: 1500)
        let record = FocusSessionRecord(startedAt: start, endedAt: end)

        XCTAssertEqual(record.durationSeconds, 1500)
    }
}
