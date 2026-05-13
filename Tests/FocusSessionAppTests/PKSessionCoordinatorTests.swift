import XCTest
@testable import FocusSession

@MainActor
final class PKSessionCoordinatorTests: XCTestCase {
    func testRoomStartCreatesBoundPKSession() async throws {
        let pkRepo = StubPKSessionRepository()
        let roomRepo = StubRoomRepository()
        let coordinator = PKSessionCoordinator(pkSessionRepository: pkRepo, roomRepository: roomRepo)
        await coordinator.sessionDidStart(roomID: "r1", sessionID: "s1", plannedMinutes: 25)
        XCTAssertEqual(coordinator.currentPKSessionID, "s1")
    }

    func testFinishMarksPKSessionEnded() async throws {
        let pkRepo = StubPKSessionRepository()
        let roomRepo = StubRoomRepository()
        let coordinator = PKSessionCoordinator(pkSessionRepository: pkRepo, roomRepository: roomRepo)
        await coordinator.sessionDidStart(roomID: "r1", sessionID: "s1", plannedMinutes: 25)
        coordinator.sessionDidFinish(verifiedMinutes: 20)
        // give the async task time to run
        try await Task.sleep(nanoseconds: 50_000_000)
        let session = try await pkRepo.fetchCurrentSession(roomID: "r1")
        XCTAssertEqual(session?.status, .ended)
    }

    func testAbandonMarksPKSessionCancelled() async throws {
        let pkRepo = StubPKSessionRepository()
        let roomRepo = StubRoomRepository()
        let coordinator = PKSessionCoordinator(pkSessionRepository: pkRepo, roomRepository: roomRepo)
        await coordinator.sessionDidStart(roomID: "r1", sessionID: "s1", plannedMinutes: 25)
        coordinator.sessionDidAbandon()
        // give the async task time to run
        try await Task.sleep(nanoseconds: 50_000_000)
        let session = try await pkRepo.fetchCurrentSession(roomID: "r1")
        XCTAssertEqual(session?.status, .cancelled)
    }
}
