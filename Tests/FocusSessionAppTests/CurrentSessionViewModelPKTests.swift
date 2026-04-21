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
