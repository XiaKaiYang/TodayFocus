import Foundation
import SwiftData

@Model
final class StoredTask {
    @Attribute(.unique) var id: UUID
    var title: String
    var details: String?
    var estimatedMinutes: Int
    var priorityRawValue: String?
    var subtasksData: Data?
    var startAt: Date?
    var endAt: Date?
    var isCompleted: Bool
    var createdAt: Date
    var completedAt: Date?
    var linkedSubtaskID: UUID?
    var contributionValue: Double?
    var settledLinkedSubtaskID: UUID?
    var settledContributionValue: Double?
    var repeatRuleRawValue: String?
    var repeatWeekdayRawValue: Int?
    var repeatTotalCount: Int?
    var repeatRemainingCount: Int?
    var visibleFrom: Date?
    var recurrenceSeriesID: UUID?
    var displayOrder: Int?

    init(task: FocusTask) {
        self.id = task.id
        self.title = task.title
        self.details = task.details
        self.estimatedMinutes = task.estimatedMinutes
        self.priorityRawValue = task.priority.rawValue
        self.subtasksData = Self.encodeSubtasks(task.subtasks)
        self.startAt = task.startAt
        self.endAt = task.endAt
        self.isCompleted = task.isCompleted
        self.createdAt = task.createdAt
        self.completedAt = task.completedAt
        self.linkedSubtaskID = task.linkedSubtaskID
        self.contributionValue = task.contributionValue
        self.settledLinkedSubtaskID = task.settledLinkedSubtaskID
        self.settledContributionValue = task.settledContributionValue
        self.repeatRuleRawValue = task.repeatRule.rawValue
        self.repeatWeekdayRawValue = task.repeatWeekday?.rawValue
        self.repeatTotalCount = task.repeatTotalCount
        self.repeatRemainingCount = task.repeatRemainingCount
        self.visibleFrom = task.visibleFrom
        self.recurrenceSeriesID = task.recurrenceSeriesID
        self.displayOrder = task.displayOrder >= 0 ? task.displayOrder : nil
    }

    func update(from task: FocusTask) {
        title = task.title
        details = task.details
        estimatedMinutes = task.estimatedMinutes
        priorityRawValue = task.priority.rawValue
        subtasksData = Self.encodeSubtasks(task.subtasks)
        startAt = task.startAt
        endAt = task.endAt
        isCompleted = task.isCompleted
        createdAt = task.createdAt
        completedAt = task.completedAt
        linkedSubtaskID = task.linkedSubtaskID
        contributionValue = task.contributionValue
        settledLinkedSubtaskID = task.settledLinkedSubtaskID
        settledContributionValue = task.settledContributionValue
        repeatRuleRawValue = task.repeatRule.rawValue
        repeatWeekdayRawValue = task.repeatWeekday?.rawValue
        repeatTotalCount = task.repeatTotalCount
        repeatRemainingCount = task.repeatRemainingCount
        visibleFrom = task.visibleFrom
        recurrenceSeriesID = task.recurrenceSeriesID
        displayOrder = task.displayOrder >= 0 ? task.displayOrder : nil
    }

    var domainModel: FocusTask {
        FocusTask(
            id: id,
            title: title,
            details: details,
            estimatedMinutes: estimatedMinutes,
            priority: TaskPriority(rawValue: priorityRawValue ?? "") ?? .none,
            subtasks: Self.decodeSubtasks(from: subtasksData),
            startAt: startAt,
            endAt: endAt,
            isCompleted: isCompleted,
            createdAt: createdAt,
            completedAt: completedAt,
            linkedSubtaskID: linkedSubtaskID,
            contributionValue: contributionValue,
            settledLinkedSubtaskID: settledLinkedSubtaskID,
            settledContributionValue: settledContributionValue,
            repeatRule: TaskRepeatRule(rawValue: repeatRuleRawValue ?? "") ?? .none,
            repeatWeekday: repeatWeekdayRawValue.flatMap(TaskRepeatWeekday.init(rawValue:)),
            repeatTotalCount: repeatTotalCount,
            repeatRemainingCount: repeatRemainingCount,
            visibleFrom: visibleFrom,
            recurrenceSeriesID: recurrenceSeriesID,
            displayOrder: displayOrder ?? -1
        )
    }

    private static func encodeSubtasks(_ subtasks: [TaskSubtask]) -> Data? {
        try? JSONEncoder().encode(subtasks)
    }

    private static func decodeSubtasks(from data: Data?) -> [TaskSubtask] {
        guard
            let data,
            let subtasks = try? JSONDecoder().decode([TaskSubtask].self, from: data)
        else {
            return []
        }

        return subtasks
    }
}
