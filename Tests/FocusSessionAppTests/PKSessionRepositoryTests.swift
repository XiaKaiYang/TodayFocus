import XCTest
@testable import FocusSession

@MainActor
final class PKSessionRepositoryTests: XCTestCase {
    func testCreateSessionAndFetch() async throws {
        let repo = StubPKSessionRepository()
        let session = PKSessionRecord(sessionID: "s1", roomID: "r1", plannedMinutes: 25)
        try await repo.createSession(session)
        let fetched = try await repo.fetchCurrentSession(roomID: "r1")
        XCTAssertEqual(fetched?.sessionID, "s1")
    }

    func testUpdateSessionPersistsStatus() async throws {
        let repo = StubPKSessionRepository()
        var session = PKSessionRecord(sessionID: "s1", roomID: "r1", plannedMinutes: 25)
        try await repo.createSession(session)
        session.status = .ended
        try await repo.updateSession(session)
        let fetched = try await repo.fetchCurrentSession(roomID: "r1")
        XCTAssertEqual(fetched?.status, .ended)
    }
}
