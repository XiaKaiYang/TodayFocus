import Foundation
import SwiftData

enum TaskComposerMode: Equatable {
    case create
    case edit(UUID)
}

enum TaskTimeRangeMode: Hashable, CaseIterable {
    case none
    case scheduled

    var composerTitle: String {
        switch self {
        case .none:
            "None"
        case .scheduled:
            "Set"
        }
    }
}

struct TaskPrioritySection: Equatable, Identifiable {
    let priority: TaskPriority
    let tasks: [FocusTask]

    var id: TaskPriority { priority }
    var title: String { priority.sectionTitle }
}

enum TasksDashboardScope: String, CaseIterable, Equatable, Hashable {
    case today
    case tomorrow

    var title: String {
        switch self {
        case .today:
            "Today"
        case .tomorrow:
            "Tomorrow"
        }
    }

    var symbolName: String {
        switch self {
        case .today:
            "sun.max"
        case .tomorrow:
            "calendar"
        }
    }
}

@MainActor
final class TasksViewModel: ObservableObject {
    @Published private(set) var tasks: [FocusTask] = []
    @Published var isPresentingCreateSheet = false
    @Published var newTaskTitle = ""
    @Published var newTaskDetails = ""
    @Published var newEstimatedMinutes = 25
    @Published var newTaskPriority: TaskPriority = .none
    @Published var newTaskRepeatRule: TaskRepeatRule = .none
    @Published var newTaskRepeatWeekday: TaskRepeatWeekday = .monday
    @Published var newTaskRepeatCountText = ""
    @Published var usesTimeRange = false
    @Published var newTaskStartAt = Date()
    @Published var newTaskEndAt = Date().addingTimeInterval(25 * 60)
    @Published private(set) var linkedSubtaskID: UUID?
    @Published private(set) var linkedSubtaskTitle: String?
    @Published var contributionValueText = ""
    @Published private(set) var errorMessage: String?

    private let repository: TasksRepository
    private let linkedTaskSettlementCoordinator: LinkedTaskSettlementCoordinator
    private let onStartTask: ((FocusTask) -> Void)?
    private let onTasksChanged: (() -> Void)?
    private let soundEffectPlayer: SoundEffectPlaying?
    private let now: () -> Date
    private let calendar: Calendar
    private var composerMode: TaskComposerMode = .create

    init(
        repository: TasksRepository? = nil,
        linkedTaskSettlementCoordinator: LinkedTaskSettlementCoordinator? = nil,
        onStartTask: ((FocusTask) -> Void)? = nil,
        onTasksChanged: (() -> Void)? = nil,
        soundEffectPlayer: SoundEffectPlaying? = nil,
        now: @escaping () -> Date = Date.init,
        calendar: Calendar = .autoupdatingCurrent
    ) {
        let resolvedRepository: TasksRepository
        if let repository {
            resolvedRepository = repository
        } else {
            resolvedRepository = TasksRepository(
                modelContext: ModelContext(FocusSessionModelContainer.shared)
            )
        }
        self.repository = resolvedRepository
        self.linkedTaskSettlementCoordinator = linkedTaskSettlementCoordinator ?? LinkedTaskSettlementCoordinator(
            tasksRepository: resolvedRepository
        )
        self.onStartTask = onStartTask
        self.onTasksChanged = onTasksChanged
        self.soundEffectPlayer = soundEffectPlayer
        self.now = now
        self.calendar = calendar

        load()
    }

    var prioritySections: [TaskPrioritySection] {
        prioritySections(in: .today)
    }

    func prioritySections(in scope: TasksDashboardScope) -> [TaskPrioritySection] {
        let referenceDate = now()
        return TaskPriority.allCases.compactMap { priority in
            let sectionTasks = tasks.filter {
                $0.priority == priority && isTask($0, visibleIn: scope, at: referenceDate)
            }
            guard !sectionTasks.isEmpty else {
                return nil
            }
            return TaskPrioritySection(priority: priority, tasks: sectionTasks)
        }
    }

    var completedTasks: [FocusTask] {
        tasks
            .filter(\.isCompleted)
            .sorted { lhs, rhs in
                let lhsDate = lhs.completedAt ?? lhs.createdAt
                let rhsDate = rhs.completedAt ?? rhs.createdAt
                if lhsDate != rhsDate {
                    return lhsDate > rhsDate
                }
                return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
            }
    }

    var trashedTasks: [FocusTask] {
        completedTasks
    }

    var isEditingTask: Bool {
        if case .edit = composerMode {
            return true
        }
        return false
    }

    func load() {
        do {
            tasks = sortTasks(try repository.fetchAll())
            errorMessage = nil
        } catch {
            tasks = []
            errorMessage = "Unable to load tasks."
        }
    }

    func presentCreateSheet(
        linkedSubtaskID: UUID? = nil,
        linkedSubtaskTitle: String? = nil,
        contributionValue: Double? = nil
    ) {
        resetComposer()
        composerMode = .create
        self.linkedSubtaskID = linkedSubtaskID
        self.linkedSubtaskTitle = linkedSubtaskTitle
        contributionValueText = Self.formatContributionValue(contributionValue)
        errorMessage = nil
        isPresentingCreateSheet = true
    }

    func presentEditSheet(for task: FocusTask) {
        composerMode = .edit(task.id)
        newTaskTitle = task.title
        newTaskDetails = task.details ?? ""
        newEstimatedMinutes = task.estimatedMinutes
        newTaskPriority = task.priority
        newTaskRepeatRule = task.repeatRule
        newTaskRepeatWeekday = task.repeatWeekday ?? .monday
        newTaskRepeatCountText = task.repeatTotalCount.map(String.init) ?? ""
        newTaskStartAt = task.startAt ?? now()
        newTaskEndAt = task.endAt ?? newTaskStartAt.addingTimeInterval(TimeInterval(task.estimatedMinutes * 60))
        usesTimeRange = task.startAt != nil && task.endAt != nil
        linkedSubtaskID = task.linkedSubtaskID
        linkedSubtaskTitle = nil
        contributionValueText = Self.formatContributionValue(task.contributionValue)
        errorMessage = nil
        isPresentingCreateSheet = true
    }

    func dismissCreateSheet() {
        resetComposer()
        composerMode = .create
        errorMessage = nil
        isPresentingCreateSheet = false
    }

    @discardableResult
    func createTask() -> Bool {
        composerMode = .create
        return saveTask()
    }

    @discardableResult
    func saveTask() -> Bool {
        let trimmedTitle = newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            errorMessage = "Task title is required."
            return false
        }

        if usesTimeRange {
            guard newTaskEndAt > newTaskStartAt else {
                errorMessage = "End time must be later than start time."
                return false
            }
        }

        if newTaskRepeatRule == .weekly && newTaskRepeatWeekday.title.isEmpty {
            errorMessage = "Choose a weekday for weekly repeats."
            return false
        }

        let trimmedDetails = newTaskDetails.trimmingCharacters(in: .whitespacesAndNewlines)
        let startAt = usesTimeRange ? newTaskStartAt : nil
        let endAt = usesTimeRange ? newTaskEndAt : nil
        let repeatRule = newTaskRepeatRule
        let repeatWeekday = repeatRule == .weekly ? newTaskRepeatWeekday : nil
        let recurrenceSeriesID = repeatRule == .none ? nil : existingOrNewRecurrenceSeriesID()
        let trimmedRepeatCount = newTaskRepeatCountText.trimmingCharacters(in: .whitespacesAndNewlines)
        let repeatTotalCount: Int?
        let repeatRemainingCount: Int?
        if repeatRule == .none || trimmedRepeatCount.isEmpty {
            repeatTotalCount = nil
            repeatRemainingCount = nil
        } else if let parsedRepeatCount = Int(trimmedRepeatCount), parsedRepeatCount >= 1 {
            repeatTotalCount = parsedRepeatCount
            switch composerMode {
            case .create:
                repeatRemainingCount = parsedRepeatCount
            case let .edit(id):
                let existingRemainingCount = tasks.first(where: { $0.id == id })?.repeatRemainingCount
                let existingTotalCount = tasks.first(where: { $0.id == id })?.repeatTotalCount
                if existingTotalCount == parsedRepeatCount, let existingRemainingCount {
                    repeatRemainingCount = min(existingRemainingCount, parsedRepeatCount)
                } else {
                    repeatRemainingCount = parsedRepeatCount
                }
            }
        } else {
            errorMessage = "Repeat count must be a positive integer."
            return false
        }
        let contributionValue: Double?
        let trimmedContributionValue = contributionValueText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedContributionValue.isEmpty {
            contributionValue = nil
        } else if let parsedContributionValue = Double(trimmedContributionValue) {
            contributionValue = parsedContributionValue
        } else {
            errorMessage = "Contribution value must be a number."
            return false
        }

        let task: FocusTask
        switch composerMode {
        case .create:
            task = FocusTask(
                title: trimmedTitle,
                details: trimmedDetails.isEmpty ? nil : trimmedDetails,
                estimatedMinutes: newEstimatedMinutes,
                priority: newTaskPriority,
                startAt: startAt,
                endAt: endAt,
                linkedSubtaskID: linkedSubtaskID,
                contributionValue: contributionValue,
                repeatRule: repeatRule,
                repeatWeekday: repeatWeekday,
                repeatTotalCount: repeatTotalCount,
                repeatRemainingCount: repeatRemainingCount,
                recurrenceSeriesID: recurrenceSeriesID
            )
        case let .edit(id):
            guard let existingTask = tasks.first(where: { $0.id == id }) else {
                errorMessage = "Unable to find task."
                return false
            }
            task = FocusTask(
                id: existingTask.id,
                title: trimmedTitle,
                details: trimmedDetails.isEmpty ? nil : trimmedDetails,
                estimatedMinutes: newEstimatedMinutes,
                priority: newTaskPriority,
                startAt: startAt,
                endAt: endAt,
                isCompleted: existingTask.isCompleted,
                createdAt: existingTask.createdAt,
                completedAt: existingTask.completedAt,
                linkedSubtaskID: existingTask.linkedSubtaskID,
                contributionValue: contributionValue ?? existingTask.contributionValue,
                repeatRule: repeatRule,
                repeatWeekday: repeatWeekday,
                repeatTotalCount: repeatTotalCount,
                repeatRemainingCount: repeatRemainingCount,
                visibleFrom: existingTask.visibleFrom,
                recurrenceSeriesID: recurrenceSeriesID
            )
        }

        do {
            switch composerMode {
            case .create:
                try repository.save(task)
            case .edit:
                try repository.update(task)
            }
            resetComposer()
            composerMode = .create
            isPresentingCreateSheet = false
            load()
            onTasksChanged?()
            return true
        } catch {
            errorMessage = "Unable to create task."
            return false
        }
    }

    func markTaskCompleted(_ task: FocusTask) {
        guard let currentTask = tasks.first(where: { $0.id == task.id }), currentTask.isCompleted == false else {
            return
        }

        do {
            try linkedTaskSettlementCoordinator.completeTask(
                id: currentTask.id,
                completedAt: now(),
                calendar: calendar
            )
            soundEffectPlayer?.play(
                SoundPlaybackRequest(assetName: "ending-soon.wav", volume: 1)
            )
            load()
            onTasksChanged?()
        } catch {
            errorMessage = "Unable to update task."
        }
    }

    func restoreTask(_ task: FocusTask) {
        guard task.isCompleted else {
            return
        }

        var updatedTask = task
        updatedTask.isCompleted = false
        updatedTask.completedAt = nil

        do {
            try linkedTaskSettlementCoordinator.restoreTask(id: updatedTask.id)
            load()
            onTasksChanged?()
        } catch {
            errorMessage = (error as? LinkedTaskSettlementCoordinatorError)?.errorDescription ?? "Unable to update task."
        }
    }

    func deleteTask(_ task: FocusTask) {
        do {
            try repository.delete(id: task.id)
            load()
            onTasksChanged?()
        } catch {
            errorMessage = "Unable to delete task."
        }
    }

    @discardableResult
    func startFocus(for task: FocusTask) -> Bool {
        guard let onStartTask else {
            return false
        }
        onStartTask(task)
        return true
    }

    private func resetComposer() {
        newTaskTitle = ""
        newTaskDetails = ""
        newEstimatedMinutes = 25
        newTaskPriority = .none
        newTaskRepeatRule = .none
        newTaskRepeatWeekday = .monday
        newTaskRepeatCountText = ""
        usesTimeRange = false
        newTaskStartAt = now()
        newTaskEndAt = now().addingTimeInterval(25 * 60)
        linkedSubtaskID = nil
        linkedSubtaskTitle = nil
        contributionValueText = ""
    }

    private func existingOrNewRecurrenceSeriesID() -> UUID? {
        switch composerMode {
        case .create:
            return UUID()
        case let .edit(id):
            return tasks.first(where: { $0.id == id })?.recurrenceSeriesID ?? UUID()
        }
    }

    private func isTask(
        _ task: FocusTask,
        visibleIn scope: TasksDashboardScope,
        at referenceDate: Date
    ) -> Bool {
        switch scope {
        case .today:
            task.isVisibleInToday(at: referenceDate)
        case .tomorrow:
            task.isVisibleInTomorrow(relativeTo: referenceDate, calendar: calendar)
        }
    }

    private func sortTasks(_ tasks: [FocusTask]) -> [FocusTask] {
        tasks.sorted { lhs, rhs in
            if lhs.priority.sortOrder != rhs.priority.sortOrder {
                return lhs.priority.sortOrder < rhs.priority.sortOrder
            }
            if lhs.isCompleted != rhs.isCompleted {
                return lhs.isCompleted == false
            }

            let lhsDate = lhs.isCompleted ? (lhs.completedAt ?? lhs.createdAt) : lhs.createdAt
            let rhsDate = rhs.isCompleted ? (rhs.completedAt ?? rhs.createdAt) : rhs.createdAt
            if lhsDate != rhsDate {
                return lhsDate > rhsDate
            }
            return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
        }
    }

    private static func formatContributionValue(_ value: Double?) -> String {
        guard let value else {
            return ""
        }

        if value.rounded() == value {
            return String(Int(value))
        }

        return value.formatted(.number.precision(.fractionLength(0 ... 2)))
    }
}
