import Foundation
import SwiftData

@MainActor
final class PlanGoalsRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func save(_ goal: PlanGoal) throws {
        modelContext.insert(StoredPlanGoal(goal: goal))
        try modelContext.save()
    }

    func update(_ goal: PlanGoal) throws {
        let goalID = goal.id
        let descriptor = FetchDescriptor<StoredPlanGoal>(
            predicate: #Predicate<StoredPlanGoal> { $0.id == goalID }
        )
        if let storedGoal = try modelContext.fetch(descriptor).first {
            storedGoal.update(from: goal)
            try modelContext.save()
            return
        }

        modelContext.insert(StoredPlanGoal(goal: goal))
        try modelContext.save()
    }

    func delete(id: UUID) throws {
        let goalID = id
        let descriptor = FetchDescriptor<StoredPlanGoal>(
            predicate: #Predicate<StoredPlanGoal> { $0.id == goalID }
        )
        if let storedGoal = try modelContext.fetch(descriptor).first {
            modelContext.delete(storedGoal)
            try modelContext.save()
        }
    }

    func fetchAll() throws -> [PlanGoal] {
        let descriptor = FetchDescriptor<StoredPlanGoal>()
        let storedGoals = try modelContext.fetch(descriptor)
        let goals = storedGoals.map(\.domainModel)
        guard goals.contains(where: { $0.displayOrder < 0 }) else {
            return sortGoals(goals)
        }

        let backfilledGoals = legacySortGoals(goals).enumerated().map { index, goal in
            var updatedGoal = goal
            updatedGoal.displayOrder = index
            return updatedGoal
        }

        for goal in backfilledGoals {
            if let storedGoal = storedGoals.first(where: { $0.id == goal.id }) {
                storedGoal.displayOrder = goal.displayOrder
            }
        }
        try modelContext.save()
        return sortGoals(backfilledGoals)
    }

    func deleteAll() throws {
        let descriptor = FetchDescriptor<StoredPlanGoal>()
        try modelContext.fetch(descriptor).forEach(modelContext.delete)
        try modelContext.save()
    }

    private func legacySortGoals(_ goals: [PlanGoal]) -> [PlanGoal] {
        goals.sorted { lhs, rhs in
            if lhs.startAt != rhs.startAt {
                return lhs.startAt < rhs.startAt
            }
            if lhs.endAt != rhs.endAt {
                return lhs.endAt < rhs.endAt
            }
            if lhs.createdAt != rhs.createdAt {
                return lhs.createdAt > rhs.createdAt
            }
            return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
        }
    }

    private func sortGoals(_ goals: [PlanGoal]) -> [PlanGoal] {
        goals.sorted { lhs, rhs in
            let lhsHasDisplayOrder = lhs.displayOrder >= 0
            let rhsHasDisplayOrder = rhs.displayOrder >= 0
            if lhsHasDisplayOrder || rhsHasDisplayOrder {
                if lhsHasDisplayOrder != rhsHasDisplayOrder {
                    return lhsHasDisplayOrder
                }
                if lhs.displayOrder != rhs.displayOrder {
                    return lhs.displayOrder < rhs.displayOrder
                }
            }
            if lhs.startAt != rhs.startAt {
                return lhs.startAt < rhs.startAt
            }
            if lhs.endAt != rhs.endAt {
                return lhs.endAt < rhs.endAt
            }
            if lhs.createdAt != rhs.createdAt {
                return lhs.createdAt > rhs.createdAt
            }
            return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
        }
    }
}
