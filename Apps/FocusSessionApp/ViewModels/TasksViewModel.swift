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
    @Published var taskSubtasksDraft: [TaskSubtask] = []
    @Published private(set) var linkedSubtaskID: UUID?
    @Published private(set) var linkedSubtaskTitle: String?
    @Published var contributionValueText = ""
    @Published private(set) var errorMessage: String?

    private let repository: TasksRepository
    private let linkedTaskSettlementCoordinator: LinkedTaskSettlementCoordinator
    private let onStartTask: ((FocusTask, TaskSubtask?) -> Void)?
    private let onTasksChanged: (() -> Void)?
    private let soundEffectPlayer: SoundEffectPlaying?
    private let now: () -> Date
    private let calendar: Calendar
    private var composerMode: TaskComposerMode = .create

    init(
        repository: TasksRepository? = nil,
        linkedTaskSettlementCoordinator: LinkedTaskSettlementCoordinator? = nil,
        onStartTask: ((FocusTask, TaskSubtask?) -> Void)? = nil,
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
        taskSubtasksDraft = task.subtasks
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
        let sanitizedSubtasks = taskSubtasksDraft.compactMap(Self.sanitizedSubtask(from:))
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
                subtasks: sanitizedSubtasks,
                startAt: startAt,
                endAt: endAt,
                linkedSubtaskID: linkedSubtaskID,
                contributionValue: contributionValue,
                repeatRule: repeatRule,
                repeatWeekday: repeatWeekday,
                repeatTotalCount: repeatTotalCount,
                repeatRemainingCount: repeatRemainingCount,
                recurrenceSeriesID: recurrenceSeriesID,
                displayOrder: 0
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
                subtasks: sanitizedSubtasks,
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
                recurrenceSeriesID: recurrenceSeriesID,
                displayOrder: existingTask.priority == newTaskPriority ? existingTask.displayOrder : 0
            )
        }

        do {
            switch composerMode {
            case .create:
                try repository.save(task)
                try pinTaskToTop(taskID: task.id, in: task.priority, excluding: [])
            case .edit:
                let previousTask = tasks.first(where: { $0.id == task.id })
                let editsRecurringSeries = previousTask?.isRepeating == true || task.isRepeating
                if editsRecurringSeries {
                    try repository.updateRecurringInstance(
                        task,
                        previousSeriesID: previousTask?.recurrenceSeriesID
                    )
                    load()
                } else {
                    try repository.update(task)
                }
                if let previousTask, previousTask.priority != task.priority {
                    try reindexPriority(previousTask.priority, excluding: [task.id])
                    try pinTaskToTop(taskID: task.id, in: task.priority, excluding: [])
                }
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
        guard currentTask.hasSubtasks == false else {
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
            if var restoredTask = try repository.task(id: updatedTask.id), restoredTask.hasSubtasks {
                restoredTask.subtasks = restoredTask.resettingSubtasks()
                try repository.update(restoredTask)
            }
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
    func startFocus(for task: FocusTask, subtask: TaskSubtask? = nil) -> Bool {
        guard let onStartTask else {
            return false
        }
        onStartTask(task, subtask)
        return true
    }

    func addTaskSubtaskDraft() {
        taskSubtasksDraft.append(TaskSubtask(title: ""))
    }

    func updateTaskSubtaskDraftTitle(_ title: String, id: UUID) {
        guard let index = taskSubtasksDraft.firstIndex(where: { $0.id == id }) else {
            return
        }
        taskSubtasksDraft[index].title = title
    }

    func removeTaskSubtaskDraft(id: UUID) {
        taskSubtasksDraft.removeAll { $0.id == id }
    }

    func toggleTaskSubtaskCompletion(_ subtask: TaskSubtask, in task: FocusTask) {
        guard var currentTask = tasks.first(where: { $0.id == task.id }), currentTask.isCompleted == false else {
            return
        }
        guard let subtaskIndex = currentTask.subtasks.firstIndex(where: { $0.id == subtask.id }) else {
            return
        }

        do {
            if currentTask.subtasks[subtaskIndex].isCompleted {
                currentTask.subtasks[subtaskIndex].isCompleted = false
                try repository.update(currentTask)
            } else if try linkedTaskSettlementCoordinator.completeSubtask(
                taskID: currentTask.id,
                subtaskID: subtask.id,
                completedAt: now(),
                calendar: calendar
            ) {
                soundEffectPlayer?.play(
                    SoundPlaybackRequest(assetName: "ending-soon.wav", volume: 1)
                )
            }
            load()
            onTasksChanged?()
        } catch {
            errorMessage = "Unable to update task."
        }
    }

    func completeFocusedSubtask(_ subtask: TaskSubtask, in task: FocusTask) -> Bool {
        do {
            let completedParent = try linkedTaskSettlementCoordinator.completeSubtask(
                taskID: task.id,
                subtaskID: subtask.id,
                completedAt: now(),
                calendar: calendar
            )
            load()
            onTasksChanged?()
            return completedParent
        } catch {
            errorMessage = "Unable to update task."
            return false
        }
    }

    func moveTask(_ sourceID: UUID, to targetID: UUID) {
        guard sourceID != targetID else {
            return
        }
        guard
            let sourceTask = tasks.first(where: { $0.id == sourceID }),
            let targetTask = tasks.first(where: { $0.id == targetID }),
            sourceTask.priority == targetTask.priority,
            sourceTask.isCompleted == false,
            targetTask.isCompleted == false
        else {
            return
        }

        var orderedTasks = sortTasks(
            tasks.filter { $0.priority == sourceTask.priority && $0.isCompleted == false }
        )
        guard
            let sourceIndex = orderedTasks.firstIndex(where: { $0.id == sourceID }),
            let targetIndex = orderedTasks.firstIndex(where: { $0.id == targetID })
        else {
            return
        }

        let movedTask = orderedTasks.remove(at: sourceIndex)
        orderedTasks.insert(movedTask, at: targetIndex)

        do {
            try persistDisplayOrder(for: orderedTasks)
            load()
            onTasksChanged?()
        } catch {
            errorMessage = "Unable to reorder tasks."
        }
    }

    private func resetComposer() {
        newTaskTitle = ""
        newTaskDetails = ""
        newEstimatedMinutes = 25
        newTaskPriority = .none
        taskSubtasksDraft = []
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
            if lhs.isCompleted == false {
                let lhsHasDisplayOrder = lhs.displayOrder >= 0
                let rhsHasDisplayOrder = rhs.displayOrder >= 0
                if lhsHasDisplayOrder != rhsHasDisplayOrder {
                    return lhsHasDisplayOrder
                }
                if lhsHasDisplayOrder, rhsHasDisplayOrder, lhs.displayOrder != rhs.displayOrder {
                    return lhs.displayOrder < rhs.displayOrder
                }
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

    private static func sanitizedSubtask(from subtask: TaskSubtask) -> TaskSubtask? {
        let trimmedTitle = subtask.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedTitle.isEmpty == false else {
            return nil
        }

        return TaskSubtask(id: subtask.id, title: trimmedTitle, isCompleted: subtask.isCompleted)
    }

    private func pinTaskToTop(taskID: UUID, in priority: TaskPriority, excluding excludedIDs: Set<UUID>) throws {
        guard var pinnedTask = try repository.task(id: taskID) else {
            return
        }

        let orderedTasks = sortTasks(
            tasks.filter {
                $0.priority == priority && $0.isCompleted == false && $0.id != taskID && !excludedIDs.contains($0.id)
            }
        )

        pinnedTask.displayOrder = 0
        try repository.update(pinnedTask)

        for (index, task) in orderedTasks.enumerated() {
            var updatedTask = task
            updatedTask.displayOrder = index + 1
            try repository.update(updatedTask)
        }
    }

    private func reindexPriority(_ priority: TaskPriority, excluding excludedIDs: Set<UUID> = []) throws {
        let orderedTasks = sortTasks(
            tasks.filter {
                $0.priority == priority && $0.isCompleted == false && !excludedIDs.contains($0.id)
            }
        )
        try persistDisplayOrder(for: orderedTasks)
    }

    private func persistDisplayOrder(for orderedTasks: [FocusTask]) throws {
        for (index, task) in orderedTasks.enumerated() {
            var updatedTask = task
            updatedTask.displayOrder = index
            try repository.update(updatedTask)
        }
    }
}
