import SwiftData
import XCTest
@testable import FocusSession
import FocusSessionCore

@MainActor
final class GoalProgressWidgetSyncerTests: XCTestCase {
    func testSyncWritesTopFiveActiveGoalsAndReloadsTimeline() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = PlanGoalsRepository(modelContext: ModelContext(container))
        let store = GoalProgressWidgetStore(containerURL: makeTemporaryDirectory())
        let updatedAt = Date(timeIntervalSince1970: 12_345)
        var reloadedKinds: [String] = []

        try repository.save(goal(title: "Reading Influence", status: .inProgress, progressPercent: nil, displayOrder: 0))
        try repository.save(goal(title: "Weight Management", status: .notStarted, progressPercent: 100, displayOrder: 1))
        try repository.save(goal(title: "Weekly Exercise", status: .onHold, progressPercent: 25, displayOrder: 2))
        try repository.save(goal(title: "Vocabulary Learning", status: .inProgress, progressPercent: 44, displayOrder: 3))
        try repository.save(goal(title: "Cycling", status: .notStarted, progressPercent: 67, displayOrder: 4))
        try repository.save(goal(title: "Saving Money", status: .inProgress, progressPercent: 65, displayOrder: 5))
        try repository.save(goal(title: "Done Goal", status: .completed, progressPercent: 100, displayOrder: 6))
        try repository.save(goal(title: "Unfinished Goal", status: .unfinished, progressPercent: 10, displayOrder: 7))

        let syncer = GoalProgressWidgetSyncer(
            repository: repository,
            store: store,
            now: { updatedAt },
            reloadTimelines: { reloadedKinds.append($0) }
        )

        syncer.sync()

        let snapshot = try store.read()
        XCTAssertEqual(snapshot.updatedAt, updatedAt)
        XCTAssertEqual(
            snapshot.items.map(\.title),
            [
                "Reading Influence",
                "Weight Management",
                "Weekly Exercise",
                "Vocabulary Learning",
                "Cycling"
            ]
        )
        XCTAssertEqual(snapshot.items.map(\.progressPercent), [0, 100, 25, 44, 67])
        XCTAssertEqual(snapshot.items.map(\.progressLabel), ["0%", "100%", "25%", "44%", "67%"])
        XCTAssertEqual(
            snapshot.items.map(\.tintToken),
            [.lilac, .sky, .peach, .sage, .mint]
        )
        XCTAssertEqual(reloadedKinds, [GoalProgressWidgetSyncer.widgetKind])
    }

    func testSyncWritesEmptySnapshotWhenRepositoryHasNoActiveGoals() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = PlanGoalsRepository(modelContext: ModelContext(container))
        let store = GoalProgressWidgetStore(containerURL: makeTemporaryDirectory())

        try repository.save(goal(title: "Done Goal", status: .completed, progressPercent: 100, displayOrder: 0))

        let syncer = GoalProgressWidgetSyncer(
            repository: repository,
            store: store,
            now: { Date(timeIntervalSince1970: 77) },
            reloadTimelines: { _ in }
        )

        syncer.sync()

        XCTAssertEqual(try store.read().items, [])
    }

    private func goal(
        title: String,
        status: PlanGoalStatus,
        progressPercent: Int?,
        displayOrder: Int
    ) -> PlanGoal {
        let subtasks: [PlanGoalSubtask]
        if let progressPercent {
            subtasks = [
                PlanGoalSubtask(
                    title: "\(title) progress",
                    baselineValue: Double(progressPercent),
                    targetValue: 100,
                    unitLabel: "%",
                    trackingMode: .estimated,
                    goalSharePercent: 100
                )
            ]
        } else {
            subtasks = []
        }

        return PlanGoal(
            title: title,
            status: status,
            startAt: Date(timeIntervalSince1970: 1_000 + TimeInterval(displayOrder)),
            endAt: Date(timeIntervalSince1970: 2_000 + TimeInterval(displayOrder)),
            subtasks: subtasks,
            displayOrder: displayOrder
        )
    }

    private func makeTemporaryDirectory() -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.removeItem(at: url)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
