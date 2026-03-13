import Foundation
import SwiftData

enum LinkedTaskSettlementCoordinatorError: LocalizedError, Equatable {
    case settledSubtaskMissing
    case settledSubtaskNoLongerSupportsLinking

    var errorDescription: String? {
        switch self {
        case .settledSubtaskMissing:
            "This linked subtask no longer exists, so the task can't be restored."
        case .settledSubtaskNoLongerSupportsLinking:
            "This linked subtask no longer supports task linking, so the task can't be restored."
        }
    }
}

@MainActor
final class LinkedTaskSettlementCoordinator {
    private let tasksRepository: TasksRepository
    private let planGoalsRepository: PlanGoalsRepository

    init(
        tasksRepository: TasksRepository? = nil,
        planGoalsRepository: PlanGoalsRepository? = nil
    ) {
        let resolvedTasksRepository = tasksRepository ?? TasksRepository(
            modelContext: ModelContext(FocusSessionModelContainer.shared)
        )
        self.tasksRepository = resolvedTasksRepository
        self.planGoalsRepository = planGoalsRepository ?? PlanGoalsRepository(
            modelContext: resolvedTasksRepository.modelContext
        )
    }

    func completeTask(
        id: UUID,
        completedAt: Date,
        calendar: Calendar = .autoupdatingCurrent
    ) throws {
        guard let task = try tasksRepository.task(id: id), task.isCompleted == false else {
            return
        }

        guard
            shouldSettleLinkedContributionOnCompletion(for: task),
            let linkedSubtaskID = task.linkedSubtaskID,
            let goalAndIndex = try goalAndSubtaskIndex(for: linkedSubtaskID),
            goalAndIndex.goal.subtasks[goalAndIndex.index].trackingMode == .quantified
        else {
            try tasksRepository.completeTask(id: id, completedAt: completedAt, calendar: calendar)
            return
        }

        var updatedGoal = goalAndIndex.goal
        updatedGoal.subtasks[goalAndIndex.index].baselineValue += task.contributionValue ?? 0
        try planGoalsRepository.update(updatedGoal)

        var updatedTask = task
        updatedTask.isCompleted = true
        updatedTask.completedAt = completedAt
        updatedTask.settledLinkedSubtaskID = linkedSubtaskID
        updatedTask.settledContributionValue = task.contributionValue
        updatedTask.linkedSubtaskID = nil
        updatedTask.contributionValue = nil
        try tasksRepository.update(updatedTask)
    }

    func restoreTask(id: UUID) throws {
        guard let task = try tasksRepository.task(id: id), task.isCompleted else {
            return
        }

        guard let settledLinkedSubtaskID = task.settledLinkedSubtaskID else {
            var updatedTask = task
            updatedTask.isCompleted = false
            updatedTask.completedAt = nil
            try tasksRepository.update(updatedTask)
            return
        }

        guard let goalAndIndex = try goalAndSubtaskIndex(for: settledLinkedSubtaskID) else {
            throw LinkedTaskSettlementCoordinatorError.settledSubtaskMissing
        }
        guard goalAndIndex.goal.subtasks[goalAndIndex.index].trackingMode == .quantified else {
            throw LinkedTaskSettlementCoordinatorError.settledSubtaskNoLongerSupportsLinking
        }

        var updatedGoal = goalAndIndex.goal
        updatedGoal.subtasks[goalAndIndex.index].baselineValue -= task.settledContributionValue ?? 0
        try planGoalsRepository.update(updatedGoal)

        var updatedTask = task
        updatedTask.isCompleted = false
        updatedTask.completedAt = nil
        updatedTask.linkedSubtaskID = settledLinkedSubtaskID
        updatedTask.contributionValue = task.settledContributionValue
        updatedTask.settledLinkedSubtaskID = nil
        updatedTask.settledContributionValue = nil
        try tasksRepository.update(updatedTask)
    }

    private func shouldSettleLinkedContributionOnCompletion(for task: FocusTask) -> Bool {
        guard task.linkedSubtaskID != nil else {
            return false
        }

        switch task.repeatRule {
        case .none:
            return true
        case .daily, .weekly:
            guard task.repeatTotalCount != nil else {
                return false
            }
            let remainingCount = task.repeatRemainingCount ?? task.repeatTotalCount ?? 0
            return remainingCount <= 1
        }
    }

    private func goalAndSubtaskIndex(for subtaskID: UUID) throws -> (goal: PlanGoal, index: Int)? {
        for goal in try planGoalsRepository.fetchAll() {
            if let index = goal.subtasks.firstIndex(where: { $0.id == subtaskID }) {
                return (goal, index)
            }
        }

        return nil
    }
}

@MainActor
final class TasksRepository {
    let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func save(_ task: FocusTask) throws {
        modelContext.insert(StoredTask(task: task))
        try modelContext.save()
    }

    func update(_ task: FocusTask) throws {
        let taskID = task.id
        let descriptor = FetchDescriptor<StoredTask>(
            predicate: #Predicate<StoredTask> { $0.id == taskID }
        )
        if let storedTask = try modelContext.fetch(descriptor).first {
            storedTask.update(from: task)
            try modelContext.save()
            return
        }

        modelContext.insert(StoredTask(task: task))
        try modelContext.save()
    }

    func task(id: UUID) throws -> FocusTask? {
        let taskID = id
        let descriptor = FetchDescriptor<StoredTask>(
            predicate: #Predicate<StoredTask> { $0.id == taskID }
        )
        return try modelContext.fetch(descriptor).first?.domainModel
    }

    func completeTask(
        id: UUID,
        completedAt: Date,
        calendar: Calendar = .autoupdatingCurrent
    ) throws {
        let taskID = id
        let descriptor = FetchDescriptor<StoredTask>(
            predicate: #Predicate<StoredTask> { $0.id == taskID }
        )
        guard let storedTask = try modelContext.fetch(descriptor).first else {
            return
        }

        let currentTask = storedTask.domainModel
        guard currentTask.isCompleted == false else {
            return
        }

        var updatedTask = currentTask
        updatedTask.isCompleted = true
        updatedTask.completedAt = completedAt
        storedTask.update(from: updatedTask)

        if let successor = recurringSuccessor(for: updatedTask, calendar: calendar) {
            modelContext.insert(StoredTask(task: successor))
        }

        try modelContext.save()
    }

    func delete(id: UUID) throws {
        let taskID = id
        let descriptor = FetchDescriptor<StoredTask>(
            predicate: #Predicate<StoredTask> { $0.id == taskID }
        )
        if let storedTask = try modelContext.fetch(descriptor).first {
            modelContext.delete(storedTask)
            try modelContext.save()
        }
    }

    func fetchAll() throws -> [FocusTask] {
        let descriptor = FetchDescriptor<StoredTask>()
        return try modelContext.fetch(descriptor).map { $0.domainModel }
    }

    func deleteCompleted() throws {
        let descriptor = FetchDescriptor<StoredTask>()
        try modelContext.fetch(descriptor)
            .filter(\.isCompleted)
            .forEach(modelContext.delete)
        try modelContext.save()
    }

    func deleteAll() throws {
        let descriptor = FetchDescriptor<StoredTask>()
        try modelContext.fetch(descriptor).forEach(modelContext.delete)
        try modelContext.save()
    }

    private func recurringSuccessor(
        for task: FocusTask,
        calendar: Calendar
    ) -> FocusTask? {
        guard task.repeatRule != .none else {
            return nil
        }
        guard let completedAt = task.completedAt else {
            return nil
        }
        let currentRemainingCount = task.repeatRemainingCount ?? task.repeatTotalCount
        if let currentRemainingCount, currentRemainingCount <= 1 {
            return nil
        }
        guard let visibleFrom = nextVisibleDate(for: task, after: completedAt, calendar: calendar) else {
            return nil
        }

        return FocusTask(
            title: task.title,
            details: task.details,
            estimatedMinutes: task.estimatedMinutes,
            priority: task.priority,
            createdAt: visibleFrom,
            linkedSubtaskID: task.linkedSubtaskID,
            contributionValue: task.contributionValue,
            repeatRule: task.repeatRule,
            repeatWeekday: task.repeatWeekday,
            repeatTotalCount: task.repeatTotalCount,
            repeatRemainingCount: currentRemainingCount.map { $0 - 1 },
            visibleFrom: visibleFrom,
            recurrenceSeriesID: task.recurrenceSeriesID ?? UUID()
        )
    }

    private func nextVisibleDate(
        for task: FocusTask,
        after completionDate: Date,
        calendar: Calendar
    ) -> Date? {
        switch task.repeatRule {
        case .none:
            return nil
        case .daily:
            let nextDay = calendar.date(byAdding: .day, value: 1, to: completionDate) ?? completionDate
            return dateAtSixAM(on: nextDay, calendar: calendar)
        case .weekly:
            guard let repeatWeekday = task.repeatWeekday else {
                return nil
            }
            var components = DateComponents()
            components.weekday = repeatWeekday.calendarWeekday
            components.hour = 6
            components.minute = 0
            components.second = 0
            return calendar.nextDate(
                after: completionDate,
                matching: components,
                matchingPolicy: .nextTime,
                direction: .forward
            )
        }
    }

    private func dateAtSixAM(on date: Date, calendar: Calendar) -> Date? {
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = 6
        components.minute = 0
        components.second = 0
        return calendar.date(from: components)
    }
}
