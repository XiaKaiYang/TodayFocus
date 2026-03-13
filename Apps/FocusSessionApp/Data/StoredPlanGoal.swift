import Foundation
import SwiftData

@Model
final class StoredPlanGoal {
    @Attribute(.unique) var id: UUID
    var title: String
    var notes: String?
    var statusRawValue: String
    var startAt: Date
    var endAt: Date
    var createdAt: Date
    var subtasksData: Data?
    var displayOrder: Int?

    init(goal: PlanGoal) {
        id = goal.id
        title = goal.title
        notes = goal.notes
        statusRawValue = goal.status.rawValue
        startAt = goal.startAt
        endAt = goal.endAt
        createdAt = goal.createdAt
        subtasksData = Self.encodeSubtasks(goal.subtasks)
        displayOrder = goal.displayOrder >= 0 ? goal.displayOrder : nil
    }

    func update(from goal: PlanGoal) {
        title = goal.title
        notes = goal.notes
        statusRawValue = goal.status.rawValue
        startAt = goal.startAt
        endAt = goal.endAt
        createdAt = goal.createdAt
        subtasksData = Self.encodeSubtasks(goal.subtasks)
        displayOrder = goal.displayOrder >= 0 ? goal.displayOrder : nil
    }

    var domainModel: PlanGoal {
        PlanGoal(
            id: id,
            title: title,
            notes: notes,
            status: PlanGoalStatus(rawValue: statusRawValue) ?? .notStarted,
            startAt: startAt,
            endAt: endAt,
            createdAt: createdAt,
            subtasks: Self.decodeSubtasks(from: subtasksData),
            displayOrder: displayOrder ?? -1
        )
    }

    private static func encodeSubtasks(_ subtasks: [PlanGoalSubtask]) -> Data? {
        try? JSONEncoder().encode(subtasks)
    }

    private static func decodeSubtasks(from data: Data?) -> [PlanGoalSubtask] {
        guard
            let data,
            let subtasks = try? JSONDecoder().decode([PlanGoalSubtask].self, from: data)
        else {
            return []
        }

        return PlanGoalSubtask.normalizedGoalSharePercents(in: subtasks).map { subtask in
            PlanGoalSubtask(
                id: subtask.id,
                title: subtask.title,
                baselineValue: subtask.baselineValue,
                targetValue: subtask.targetValue,
                unitLabel: subtask.unitLabel,
                trackingMode: subtask.trackingMode,
                goalSharePercent: subtask.goalSharePercent
            )
        }
    }
}
