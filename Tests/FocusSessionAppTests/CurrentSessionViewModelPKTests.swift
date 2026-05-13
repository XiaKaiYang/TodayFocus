import XCTest
@testable import FocusSession
import SwiftData

@MainActor
final class CurrentSessionViewModelPKTests: XCTestCase {
    func testBindPKSessionAttachesCoordinator() throws {
        let harness = try makeHarness()
        let stub = StubPKSessionCoordinator()
        harness.viewModel.bindPKSession(roomID: "r1", sessionID: "s1", coordinator: stub)
        XCTAssertNotNil(harness.viewModel.pkCoordinator)
    }

    func testUnbindRemovesCoordinator() throws {
        let harness = try makeHarness()
        let stub = StubPKSessionCoordinator()
        harness.viewModel.bindPKSession(roomID: "r1", sessionID: "s1", coordinator: stub)
        harness.viewModel.unbindPKSession()
        XCTAssertNil(harness.viewModel.pkCoordinator)
    }

    func testStartPKLinkedSessionStartsFocusWithoutTaskSelection() async throws {
        let harness = try makeHarness()
        let stub = StubPKSessionCoordinator()

        harness.viewModel.bindPKSession(roomID: "r1", sessionID: "s1", coordinator: stub)
        harness.viewModel.startPKLinkedSession(title: "PK Room Session", plannedMinutes: 25)
        await Task.yield()

        XCTAssertEqual(harness.viewModel.sessionState.phase, .focusing)
        XCTAssertEqual(harness.viewModel.currentIntention, "PK Room Session")
        XCTAssertTrue(stub.didStartCalled)
    }

    private struct Harness {
        let viewModel: CurrentSessionViewModel
        let tasksRepository: TasksRepository
    }

    private func makeHarness() throws -> Harness {
        let container = try FocusSessionModelContainer.makeInMemory()
        let context = ModelContext(container)
        let tasksRepo = TasksRepository(modelContext: context)
        let focusRepo = FocusSessionRepository(modelContext: context)
        let vm = CurrentSessionViewModel(
            snapshotStore: nil,
            focusSessionRepository: focusRepo,
            tasksRepository: tasksRepo
        )
        return Harness(viewModel: vm, tasksRepository: tasksRepo)
    }
}
