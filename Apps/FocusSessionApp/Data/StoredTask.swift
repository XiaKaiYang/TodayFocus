import Foundation
import SwiftData

@Model
final class StoredTask {
    @Attribute(.unique) var id: UUID
    var title: String
    var details: String?
    var estimatedMinutes: Int
    var priorityRawValue: String?
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

    init(task: FocusTask) {
        self.id = task.id
        self.title = task.title
        self.details = task.details
        self.estimatedMinutes = task.estimatedMinutes
        self.priorityRawValue = task.priority.rawValue
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
    }

    func update(from task: FocusTask) {
        title = task.title
        details = task.details
        estimatedMinutes = task.estimatedMinutes
        priorityRawValue = task.priority.rawValue
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
    }

    var domainModel: FocusTask {
        FocusTask(
            id: id,
            title: title,
            details: details,
            estimatedMinutes: estimatedMinutes,
            priority: TaskPriority(rawValue: priorityRawValue ?? "") ?? .none,
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
            recurrenceSeriesID: recurrenceSeriesID
        )
    }
}
