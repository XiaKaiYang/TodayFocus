import Combine
import Foundation
import SwiftData

struct SettingsDataSummary: Equatable {
    var focusSessionsCount = 0
    var tasksCount = 0
    var goalsCount = 0
    var blockerRulesCount = 0
    var blockedEventsCount = 0
}

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published private(set) var preferences: AppPreferences
    @Published private(set) var dataSummary = SettingsDataSummary()
    @Published private(set) var errorMessage: String?

    private let preferencesStore: AppPreferencesStore
    private let focusSessionRepository: FocusSessionRepository
    private let tasksRepository: TasksRepository
    private let planGoalsRepository: PlanGoalsRepository
    private let rulesRepository: BlockingRuleRepository
    private let eventRepository: DistractionEventRepository
    private let onDataChanged: (() -> Void)?
    private var cancellables = Set<AnyCancellable>()

    init(
        preferencesStore: AppPreferencesStore = AppPreferencesStore(),
        focusSessionRepository: FocusSessionRepository? = nil,
        tasksRepository: TasksRepository? = nil,
        rulesRepository: BlockingRuleRepository? = nil,
        eventRepository: DistractionEventRepository? = nil,
        onDataChanged: (() -> Void)? = nil
    ) {
        let modelContext = ModelContext(FocusSessionModelContainer.shared)
        self.preferencesStore = preferencesStore
        self.focusSessionRepository = focusSessionRepository ?? FocusSessionRepository(modelContext: modelContext)
        self.tasksRepository = tasksRepository ?? TasksRepository(modelContext: modelContext)
        self.planGoalsRepository = PlanGoalsRepository(modelContext: modelContext)
        self.rulesRepository = rulesRepository ?? BlockingRuleRepository(modelContext: modelContext)
        self.eventRepository = eventRepository ?? DistractionEventRepository(modelContext: modelContext)
        self.onDataChanged = onDataChanged
        preferences = preferencesStore.preferences

        preferencesStore.$preferences
            .sink { [weak self] in
                self?.preferences = $0
            }
            .store(in: &cancellables)

        reload()
    }

    func updateDefaultFocusDurationMinutes(_ minutes: Int) {
        preferencesStore.updateDefaultFocusDurationMinutes(minutes)
    }

    func updateLaunchSection(_ section: AppSection) {
        preferencesStore.updateLaunchSection(
            AppSection.resolvedLaunchSection(
                preferredSection: section,
                on: AppPlatform.current
            )
        )
    }

    func updatePlanGoalLaunchExpansion(_ expansion: PlanGoalLaunchExpansion) {
        preferencesStore.updatePlanGoalLaunchExpansion(expansion)
    }

    func setAutoEnableBlockerDuringFocus(_ isEnabled: Bool) {
        preferencesStore.setAutoEnableBlockerDuringFocus(isEnabled)
    }

    func updateRecentSessionsLimit(_ limit: Int) {
        preferencesStore.updateRecentSessionsLimit(limit)
    }

    func clearFocusHistory() {
        performDataChange {
            try focusSessionRepository.deleteAll()
        }
    }

    func clearCompletedTasks() {
        performDataChange {
            try tasksRepository.deleteCompleted()
        }
    }

    func clearBlockerActivity() {
        performDataChange {
            try eventRepository.deleteAll()
        }
    }

    func resetAllLocalData() {
        performDataChange {
            try focusSessionRepository.deleteAll()
            try tasksRepository.deleteAll()
            try planGoalsRepository.deleteAll()
            try rulesRepository.deleteAll()
            try eventRepository.deleteAll()
            preferencesStore.reset()
        }
    }

    func reload() {
        do {
            dataSummary = SettingsDataSummary(
                focusSessionsCount: try focusSessionRepository.fetchAll().count,
                tasksCount: try tasksRepository.fetchAll().count,
                goalsCount: try planGoalsRepository.fetchAll().count,
                blockerRulesCount: try rulesRepository.fetchAll().count,
                blockedEventsCount: try eventRepository.fetchAll(limit: 500).count
            )
            errorMessage = nil
        } catch {
            dataSummary = SettingsDataSummary()
            errorMessage = "Unable to load settings data."
        }
    }

    private func performDataChange(_ change: () throws -> Void) {
        do {
            try change()
            reload()
            onDataChanged?()
            errorMessage = nil
        } catch {
            errorMessage = "Unable to apply settings change."
        }
    }
}
