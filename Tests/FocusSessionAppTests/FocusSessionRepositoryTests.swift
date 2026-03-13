import SwiftData
import XCTest
@testable import FocusSession
import FocusSessionCore

@MainActor
final class FocusSessionRepositoryTests: XCTestCase {
    func testRepositoryRoundTripsFocusSessionRecord() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = FocusSessionRepository(modelContext: ModelContext(container))
        let record = FocusSessionRecord(
            intention: "Deep work",
            startedAt: Date(timeIntervalSince1970: 0),
            endedAt: Date(timeIntervalSince1970: 1500),
            notes: "Initial persistence test"
        )

        try repository.save(record)
        let records = try repository.fetchAll()

        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?.intention, "Deep work")
        XCTAssertEqual(records.first?.durationSeconds, 1500)
    }

    func testRepositoryRoundTripsFocusSessionMood() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = FocusSessionRepository(modelContext: ModelContext(container))
        let record = FocusSessionRecord(
            intention: "Reflection persistence",
            startedAt: Date(timeIntervalSince1970: 0),
            endedAt: Date(timeIntervalSince1970: 900),
            notes: "Mood should survive persistence",
            mood: .neutral
        )

        try repository.save(record)
        let records = try repository.fetchAll()

        XCTAssertEqual(records.first?.mood, .neutral)
    }
}
