import SwiftData
import XCTest
@testable import FocusSession

@MainActor
final class PlanGoalsRepositoryTests: XCTestCase {
    func testRepositoryRoundTripsGoals() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = PlanGoalsRepository(modelContext: ModelContext(container))
        let goal = PlanGoal(
            title: "Ship RL notes",
            notes: "整理 value iteration 和 policy iteration",
            status: .inProgress,
            startAt: Date(timeIntervalSince1970: 10_000),
            endAt: Date(timeIntervalSince1970: 20_000)
        )

        try repository.save(goal)

        let goals = try repository.fetchAll()
        XCTAssertEqual(goals.map(\.title), ["Ship RL notes"])
        XCTAssertEqual(goals.first?.notes, "整理 value iteration 和 policy iteration")
        XCTAssertEqual(goals.first?.status, .inProgress)
        XCTAssertEqual(goals.first?.startAt, Date(timeIntervalSince1970: 10_000))
        XCTAssertEqual(goals.first?.endAt, Date(timeIntervalSince1970: 20_000))
    }

    func testRepositoryRoundTripsGoalSubtasks() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = PlanGoalsRepository(modelContext: ModelContext(container))
        let goal = PlanGoal(
            title: "Ship RL notes",
            notes: "Split into smaller milestones",
            status: .inProgress,
            startAt: Date(timeIntervalSince1970: 10_000),
            endAt: Date(timeIntervalSince1970: 20_000),
            subtasks: [
                PlanGoalSubtask(
                    title: "Outline",
                    baselineValue: 1,
                    targetValue: 10,
                    unitLabel: "篇",
                    trackingMode: .quantified,
                    goalSharePercent: 20
                ),
                PlanGoalSubtask(
                    title: "Draft",
                    baselineValue: 3.5,
                    targetValue: 5,
                    unitLabel: "章",
                    trackingMode: .estimated,
                    goalSharePercent: 30
                ),
                PlanGoalSubtask(
                    title: "Polish",
                    baselineValue: 8,
                    targetValue: 8,
                    unitLabel: "",
                    trackingMode: .quantified,
                    goalSharePercent: 50
                )
            ]
        )

        try repository.save(goal)

        let storedGoal = try repository.fetchAll().first
        XCTAssertEqual(storedGoal?.subtasks.map(\.title), ["Outline", "Draft", "Polish"])
        XCTAssertEqual(storedGoal?.subtasks.map(\.baselineValue), [1, 3.5, 8])
        XCTAssertEqual(storedGoal?.subtasks.map(\.targetValue), [10, 5, 8])
        XCTAssertEqual(storedGoal?.subtasks.map(\.unitLabel), ["篇", "章", ""])
        XCTAssertEqual(storedGoal?.subtasks.map(\.trackingMode), [.quantified, .estimated, .quantified])
        XCTAssertEqual(storedGoal?.subtasks.map(\.goalSharePercent), [20, 30, 50])
    }

    func testPlanGoalSubtaskDecodesLegacyProgressPercentIntoBaselineValue() throws {
        let legacySubtasksData = try XCTUnwrap(
            """
            [
              {
                "id": "2A0B05AA-93CE-4E04-9478-8481E9EEA52C",
                "title": "Legacy progress",
                "progressPercent": 45
              }
            ]
            """.data(using: .utf8)
        )

        let subtasks = try JSONDecoder().decode([PlanGoalSubtask].self, from: legacySubtasksData)

        XCTAssertEqual(subtasks.map(\.title), ["Legacy progress"])
        XCTAssertEqual(subtasks.map(\.baselineValue), [45])
        XCTAssertEqual(subtasks.map(\.targetValue), [100])
        XCTAssertEqual(subtasks.map(\.unitLabel), [""])
        XCTAssertEqual(subtasks.map(\.trackingMode), [.quantified])
    }

    func testStoredGoalAssignsEqualGoalSharesWhenLegacySubtasksOmitGoalSharePercent() throws {
        let legacySubtasksData = try XCTUnwrap(
            """
            [
              {
                "id": "2A0B05AA-93CE-4E04-9478-8481E9EEA52C",
                "title": "Outline",
                "baselineValue": 0,
                "targetValue": 10,
                "unitLabel": "页"
              },
              {
                "id": "19BB744E-E7E0-4AB7-A4C5-7549912A61E9",
                "title": "Draft",
                "baselineValue": 5,
                "targetValue": 10,
                "unitLabel": "页"
              }
            ]
            """.data(using: .utf8)
        )

        let storedGoal = StoredPlanGoal(
            goal: PlanGoal(
                title: "Legacy goal",
                status: .inProgress,
                startAt: Date(timeIntervalSince1970: 1_000),
                endAt: Date(timeIntervalSince1970: 2_000)
            )
        )
        storedGoal.subtasksData = legacySubtasksData

        let decodedGoal = storedGoal.domainModel

        XCTAssertEqual(decodedGoal.subtasks.map(\.goalSharePercent), [50, 50])
    }

    func testPersistentContainerRoundTripsGoalsAcrossFreshContexts() throws {
        let rootURL = temporaryDirectoryURL()
        let storeURL = rootURL.appending(path: "TodayFocus.store")

        let firstContainer = try FocusSessionModelContainer.makePersistent(at: storeURL)
        let firstRepository = PlanGoalsRepository(modelContext: ModelContext(firstContainer))
        let goal = PlanGoal(
            title: "Persist after relaunch",
            notes: "Make sure goals survive restarts",
            status: .inProgress,
            startAt: Date(timeIntervalSince1970: 1_000),
            endAt: Date(timeIntervalSince1970: 2_000)
        )

        try firstRepository.save(goal)

        let secondContainer = try FocusSessionModelContainer.makePersistent(at: storeURL)
        let secondRepository = PlanGoalsRepository(modelContext: ModelContext(secondContainer))

        XCTAssertEqual(try secondRepository.fetchAll().map(\.title), ["Persist after relaunch"])
    }

    func testPersistentStoreURLMigratesLegacyDefaultStoreData() throws {
        let rootURL = temporaryDirectoryURL()
        let legacyStoreURL = rootURL.appending(path: "default.store")

        let legacyContainer = try FocusSessionModelContainer.makePersistent(at: legacyStoreURL)
        let legacyRepository = PlanGoalsRepository(modelContext: ModelContext(legacyContainer))
        let goal = PlanGoal(
            title: "Legacy goal",
            notes: "Migrated from default.store",
            status: .notStarted,
            startAt: Date(timeIntervalSince1970: 3_000),
            endAt: Date(timeIntervalSince1970: 4_000)
        )

        try legacyRepository.save(goal)

        let migratedStoreURL = try FocusSessionModelContainer.persistentStoreURL(baseDirectory: rootURL)
        let migratedContainer = try FocusSessionModelContainer.makePersistent(at: migratedStoreURL)
        let migratedRepository = PlanGoalsRepository(modelContext: ModelContext(migratedContainer))

        XCTAssertEqual(
            migratedStoreURL.path(),
            rootURL.appending(path: "TodayFocus/TodayFocus.store").path()
        )
        XCTAssertEqual(try migratedRepository.fetchAll().map(\.title), ["Legacy goal"])
    }

    func testRepositoryRoundTripsGoalDisplayOrder() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = PlanGoalsRepository(modelContext: ModelContext(container))
        let goal = PlanGoal(
            title: "Ship RL notes",
            status: .inProgress,
            startAt: Date(timeIntervalSince1970: 10_000),
            endAt: Date(timeIntervalSince1970: 20_000),
            displayOrder: 4
        )

        try repository.save(goal)

        let storedGoal = try repository.fetchAll().first
        XCTAssertEqual(storedGoal?.displayOrder, 4)
    }

    func testRepositoryRoundTripsUnfinishedGoalStatus() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = PlanGoalsRepository(modelContext: ModelContext(container))
        let goal = PlanGoal(
            title: "Missed milestone",
            status: .unfinished,
            startAt: Date(timeIntervalSince1970: 10_000),
            endAt: Date(timeIntervalSince1970: 20_000)
        )

        try repository.save(goal)

        let storedGoal = try repository.fetchAll().first
        XCTAssertEqual(storedGoal?.status, .unfinished)
    }

    func testFetchAllBackfillsLegacyDisplayOrderUsingCurrentVisibleOrder() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let context = ModelContext(container)
        let repository = PlanGoalsRepository(modelContext: context)
        let laterGoal = StoredPlanGoal(
            goal: PlanGoal(
                title: "Later",
                status: .inProgress,
                startAt: Date(timeIntervalSince1970: 20_000),
                endAt: Date(timeIntervalSince1970: 30_000)
            )
        )
        laterGoal.displayOrder = nil
        let earlierGoal = StoredPlanGoal(
            goal: PlanGoal(
                title: "Earlier",
                status: .inProgress,
                startAt: Date(timeIntervalSince1970: 10_000),
                endAt: Date(timeIntervalSince1970: 15_000)
            )
        )
        earlierGoal.displayOrder = nil
        context.insert(laterGoal)
        context.insert(earlierGoal)
        try context.save()

        let goals = try repository.fetchAll()

        XCTAssertEqual(goals.map(\.title), ["Earlier", "Later"])
        XCTAssertEqual(goals.map(\.displayOrder), [0, 1])
        let storedGoals = try context.fetch(FetchDescriptor<StoredPlanGoal>()).sorted { $0.title < $1.title }
        XCTAssertEqual(storedGoals.map(\.displayOrder), [0, 1])
    }

    private func temporaryDirectoryURL() -> URL {
        let rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.removeItem(at: rootURL)
        try? FileManager.default.createDirectory(at: rootURL, withIntermediateDirectories: true)
        return rootURL
    }
}
