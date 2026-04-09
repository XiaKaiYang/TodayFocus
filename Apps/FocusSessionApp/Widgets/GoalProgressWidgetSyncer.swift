import Foundation
import FocusSessionCore
#if canImport(WidgetKit)
import WidgetKit
#endif

@MainActor
struct GoalProgressWidgetSyncer {
    static let widgetKind = "FocusSessionWidget"

    private let repository: PlanGoalsRepository
    private let store: GoalProgressWidgetStore?
    private let now: () -> Date
    private let reloadTimelines: (String) -> Void
    private let palette: [GoalProgressWidgetTintToken]

    init(
        repository: PlanGoalsRepository,
        store: GoalProgressWidgetStore? = nil,
        now: @escaping () -> Date = Date.init,
        reloadTimelines: @escaping (String) -> Void = { kind in
            #if canImport(WidgetKit)
            WidgetCenter.shared.reloadTimelines(ofKind: kind)
            #endif
        }
    ) {
        self.repository = repository
        self.store = store ?? (try? GoalProgressWidgetStore())
        self.now = now
        self.reloadTimelines = reloadTimelines
        palette = [.lilac, .sky, .peach, .sage, .mint]
    }

    func sync() {
        do {
            try sync(goals: repository.fetchAll())
        } catch {
            syncEmptySnapshot()
        }
    }

    func sync(goals: [PlanGoal]) throws {
        guard let store else {
            return
        }

        let snapshot = GoalProgressWidgetSnapshot(
            items: makeItems(from: goals),
            updatedAt: now()
        )
        try store.write(snapshot)
        reloadTimelines(Self.widgetKind)
    }

    func syncEmptySnapshot() {
        try? sync(goals: [])
    }

    private func makeItems(from goals: [PlanGoal]) -> [GoalProgressWidgetItem] {
        goals
            .filter { !$0.status.isTerminal }
            .prefix(5)
            .enumerated()
            .map { index, goal in
                let progressPercent = goal.progressPercent ?? 0
                return GoalProgressWidgetItem(
                    id: goal.id,
                    title: goal.title,
                    progressPercent: progressPercent,
                    progressLabel: "\(progressPercent)%",
                    tintToken: palette[index % palette.count]
                )
            }
    }
}
