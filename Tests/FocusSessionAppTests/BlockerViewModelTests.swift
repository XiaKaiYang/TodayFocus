import XCTest
import AppKit
import SwiftData
import FocusSessionCore
@testable import FocusSession

@MainActor
final class BlockerViewModelTests: XCTestCase {
    func testDemoViewModelSeedsRulesAndRecentEvents() {
        let viewModel = BlockerViewModel.demo()

        XCTAssertTrue(viewModel.isBlockingEnabled)
        XCTAssertEqual(viewModel.appRules.count, 2)
        XCTAssertEqual(viewModel.domainRules.count, 2)
        XCTAssertEqual(viewModel.recentEvents.count, 2)
        XCTAssertEqual(viewModel.lastBlockedAppName, "Discord")
    }

    func testSessionDrivenBlockingAutoEnablesDuringFocusAndRestoresAfterCompletion() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let modelContext = ModelContext(container)
        let viewModel = BlockerViewModel(
            rulesRepository: BlockingRuleRepository(modelContext: modelContext),
            eventRepository: DistractionEventRepository(modelContext: modelContext),
            coordinator: BlockerCoordinator(
                rulesRepository: BlockingRuleRepository(modelContext: modelContext),
                distractionEventRepository: DistractionEventRepository(modelContext: modelContext),
                watcher: TestForegroundAppWatcher()
            )
        )

        XCTAssertFalse(viewModel.isBlockingEnabled)

        viewModel.syncSessionPhase(.focusing, autoEnableDuringFocus: true)
        XCTAssertTrue(viewModel.isBlockingEnabled)

        viewModel.syncSessionPhase(.completed, autoEnableDuringFocus: true)
        XCTAssertFalse(viewModel.isBlockingEnabled)
    }

    func testSessionDrivenBlockingDoesNotOverrideManualEnablement() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let modelContext = ModelContext(container)
        let viewModel = BlockerViewModel(
            rulesRepository: BlockingRuleRepository(modelContext: modelContext),
            eventRepository: DistractionEventRepository(modelContext: modelContext),
            coordinator: BlockerCoordinator(
                rulesRepository: BlockingRuleRepository(modelContext: modelContext),
                distractionEventRepository: DistractionEventRepository(modelContext: modelContext),
                watcher: TestForegroundAppWatcher()
            )
        )

        viewModel.isBlockingEnabled = true
        viewModel.syncSessionPhase(.focusing, autoEnableDuringFocus: true)
        viewModel.syncSessionPhase(.completed, autoEnableDuringFocus: true)

        XCTAssertTrue(viewModel.isBlockingEnabled)
    }
}

private struct TestForegroundAppWatcher: ForegroundAppWatching {
    func start(onChange: @escaping @Sendable (NSRunningApplication?) -> Void) {}
}
