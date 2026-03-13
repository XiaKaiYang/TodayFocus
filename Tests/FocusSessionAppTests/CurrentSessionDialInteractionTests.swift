import XCTest
import SwiftData
@testable import FocusSession

@MainActor
final class CurrentSessionDialInteractionTests: XCTestCase {
    func testDialDurationUpdatesClampAndRespectSessionLock() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let modelContext = ModelContext(container)
        let tasksRepository = TasksRepository(modelContext: modelContext)
        let task = FocusTask(
            title: "Locked while focusing",
            estimatedMinutes: 30
        )
        try tasksRepository.save(task)
        let viewModel = CurrentSessionViewModel(
            snapshotStore: nil,
            focusSessionRepository: FocusSessionRepository(modelContext: modelContext),
            tasksRepository: tasksRepository
        )

        viewModel.updateDurationFromDial(normalizedValue: 0)
        XCTAssertEqual(viewModel.durationMinutes, 0)

        viewModel.updateDurationFromDial(normalizedValue: 1.0 / 60.0)
        XCTAssertEqual(viewModel.durationMinutes, 1)

        viewModel.updateDurationFromDial(normalizedValue: 0.5)
        XCTAssertEqual(viewModel.durationMinutes, 30)

        viewModel.updateDurationFromDial(normalizedValue: 2)
        XCTAssertEqual(viewModel.durationMinutes, 60)

        viewModel.selectTask(task)
        viewModel.startSession()
        viewModel.updateDurationFromDial(normalizedValue: 0.1)

        XCTAssertEqual(viewModel.durationMinutes, 30)
    }
}
