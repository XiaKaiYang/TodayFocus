import XCTest
import SwiftData
import FocusSessionCore
@testable import FocusSession

@MainActor
final class SettingsViewModelTests: XCTestCase {
    func testResetAllLocalDataClearsRepositoriesAndResetsPreferences() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let modelContext = ModelContext(container)
        let focusSessionRepository = FocusSessionRepository(modelContext: modelContext)
        let tasksRepository = TasksRepository(modelContext: modelContext)
        let rulesRepository = BlockingRuleRepository(modelContext: modelContext)
        let eventRepository = DistractionEventRepository(modelContext: modelContext)

        try focusSessionRepository.save(
            FocusSessionRecord(
                intention: "Study RL",
                startedAt: Date(timeIntervalSince1970: 0),
                endedAt: Date(timeIntervalSince1970: 1_500),
                notes: "Bellman update",
                wasCompleted: true
            )
        )
        try tasksRepository.save(
            FocusTask(
                title: "Write derivation",
                estimatedMinutes: 30,
                isCompleted: true,
                createdAt: Date(timeIntervalSince1970: 100),
                completedAt: Date(timeIntervalSince1970: 200)
            )
        )
        try rulesRepository.save(
            BlockingRule(
                mode: .deny,
                target: .app(name: "Discord"),
                activeDuringFocus: true,
                activeDuringBreak: false
            )
        )
        try eventRepository.save(
            DistractionEvent(
                kind: .blockedApp(name: "Discord"),
                occurredAt: Date(timeIntervalSince1970: 300)
            )
        )

        let suiteName = UUID().uuidString
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let preferencesStore = AppPreferencesStore(userDefaults: defaults)
        preferencesStore.updateDefaultFocusDurationMinutes(45)
        preferencesStore.updateLaunchSection(.tasks)
        preferencesStore.updatePlanGoalLaunchExpansion(.expanded)
        preferencesStore.setAutoEnableBlockerDuringFocus(false)
        preferencesStore.updateRecentSessionsLimit(3)

        let viewModel = SettingsViewModel(
            preferencesStore: preferencesStore,
            focusSessionRepository: focusSessionRepository,
            tasksRepository: tasksRepository,
            rulesRepository: rulesRepository,
            eventRepository: eventRepository
        )

        XCTAssertEqual(viewModel.dataSummary.focusSessionsCount, 1)
        XCTAssertEqual(viewModel.dataSummary.tasksCount, 1)
        XCTAssertEqual(viewModel.dataSummary.blockerRulesCount, 1)
        XCTAssertEqual(viewModel.dataSummary.blockedEventsCount, 1)

        viewModel.resetAllLocalData()

        XCTAssertEqual(viewModel.dataSummary.focusSessionsCount, 0)
        XCTAssertEqual(viewModel.dataSummary.tasksCount, 0)
        XCTAssertEqual(viewModel.dataSummary.blockerRulesCount, 0)
        XCTAssertEqual(viewModel.dataSummary.blockedEventsCount, 0)
        XCTAssertEqual(viewModel.preferences.defaultFocusDurationMinutes, 25)
        XCTAssertEqual(viewModel.preferences.launchSection, .tasks)
        XCTAssertEqual(viewModel.preferences.planGoalLaunchExpansion, .collapsed)
        XCTAssertTrue(viewModel.preferences.autoEnableBlockerDuringFocus)
        XCTAssertEqual(viewModel.preferences.recentSessionsLimit, 8)
    }

    func testClearCompletedTasksPreservesPendingTasks() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let modelContext = ModelContext(container)
        let tasksRepository = TasksRepository(modelContext: modelContext)
        try tasksRepository.save(
            FocusTask(title: "Pending", estimatedMinutes: 25)
        )
        try tasksRepository.save(
            FocusTask(
                title: "Done",
                estimatedMinutes: 25,
                isCompleted: true,
                createdAt: Date(timeIntervalSince1970: 100),
                completedAt: Date(timeIntervalSince1970: 200)
            )
        )

        let suiteName = UUID().uuidString
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let preferencesStore = AppPreferencesStore(userDefaults: defaults)
        let viewModel = SettingsViewModel(
            preferencesStore: preferencesStore,
            focusSessionRepository: FocusSessionRepository(modelContext: modelContext),
            tasksRepository: tasksRepository,
            rulesRepository: BlockingRuleRepository(modelContext: modelContext),
            eventRepository: DistractionEventRepository(modelContext: modelContext)
        )

        viewModel.clearCompletedTasks()

        XCTAssertEqual(viewModel.dataSummary.tasksCount, 1)
        XCTAssertEqual(try tasksRepository.fetchAll().map(\.title), ["Pending"])
    }

    func testUpdatePlanGoalLaunchExpansionPersistsPreference() throws {
        let suiteName = UUID().uuidString
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let preferencesStore = AppPreferencesStore(userDefaults: defaults)
        let container = try FocusSessionModelContainer.makeInMemory()
        let modelContext = ModelContext(container)
        let viewModel = SettingsViewModel(
            preferencesStore: preferencesStore,
            focusSessionRepository: FocusSessionRepository(modelContext: modelContext),
            tasksRepository: TasksRepository(modelContext: modelContext),
            rulesRepository: BlockingRuleRepository(modelContext: modelContext),
            eventRepository: DistractionEventRepository(modelContext: modelContext)
        )

        viewModel.updatePlanGoalLaunchExpansion(.expanded)

        XCTAssertEqual(viewModel.preferences.planGoalLaunchExpansion, .expanded)
        XCTAssertEqual(
            AppPreferencesStore(userDefaults: defaults).preferences.planGoalLaunchExpansion,
            .expanded
        )
    }
}
