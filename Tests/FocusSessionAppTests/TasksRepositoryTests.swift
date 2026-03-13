import SwiftData
import XCTest
@testable import FocusSession

@MainActor
final class TasksRepositoryTests: XCTestCase {
    func testRepositoryRoundTripsTasks() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = TasksRepository(modelContext: ModelContext(container))
        let task = FocusTask(
            title: "Write RL notes",
            details: "整理 value iteration",
            estimatedMinutes: 30,
            priority: .high,
            startAt: Date(timeIntervalSince1970: 1_000),
            endAt: Date(timeIntervalSince1970: 2_800)
        )

        try repository.save(task)

        let tasks = try repository.fetchAll()
        XCTAssertEqual(tasks.map(\.title), ["Write RL notes"])
        XCTAssertEqual(tasks.first?.details, "整理 value iteration")
        XCTAssertEqual(tasks.first?.estimatedMinutes, 30)
        XCTAssertEqual(tasks.first?.priority, .high)
        XCTAssertEqual(tasks.first?.startAt, Date(timeIntervalSince1970: 1_000))
        XCTAssertEqual(tasks.first?.endAt, Date(timeIntervalSince1970: 2_800))
        XCTAssertFalse(tasks.first?.isCompleted ?? true)
    }

    func testRepositoryRoundTripsTaskSubtaskLinkMetadata() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = TasksRepository(modelContext: ModelContext(container))
        let linkedSubtaskID = UUID()
        let task = FocusTask(
            title: "Write experiment report",
            details: "Link this to the report subtask",
            estimatedMinutes: 45,
            priority: .medium,
            linkedSubtaskID: linkedSubtaskID,
            contributionValue: 2.5
        )

        try repository.save(task)

        let storedTask = try repository.fetchAll().first
        XCTAssertEqual(storedTask?.linkedSubtaskID, linkedSubtaskID)
        XCTAssertEqual(storedTask?.contributionValue, 2.5)
    }

    func testRepositoryRoundTripsSettledLinkMetadata() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = TasksRepository(modelContext: ModelContext(container))
        let settledLinkedSubtaskID = UUID()
        let task = FocusTask(
            title: "Settled linked task",
            estimatedMinutes: 25,
            priority: .medium,
            isCompleted: true,
            completedAt: Date(timeIntervalSince1970: 3_600),
            settledLinkedSubtaskID: settledLinkedSubtaskID,
            settledContributionValue: 1.5
        )

        try repository.save(task)

        let storedTask = try repository.fetchAll().first
        XCTAssertEqual(storedTask?.settledLinkedSubtaskID, settledLinkedSubtaskID)
        XCTAssertEqual(storedTask?.settledContributionValue, 1.5)
    }

    func testRepositoryRoundTripsRecurringTaskMetadata() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = TasksRepository(modelContext: ModelContext(container))
        let seriesID = UUID()
        let visibleFrom = Date(timeIntervalSince1970: 7_200)
        let task = FocusTask(
            title: "Weekly review",
            estimatedMinutes: 30,
            priority: .medium,
            repeatRule: .weekly,
            repeatWeekday: .friday,
            visibleFrom: visibleFrom,
            recurrenceSeriesID: seriesID
        )

        try repository.save(task)

        let storedTask = try repository.fetchAll().first
        XCTAssertEqual(storedTask?.repeatRule, .weekly)
        XCTAssertEqual(storedTask?.repeatWeekday, .friday)
        XCTAssertEqual(storedTask?.visibleFrom, visibleFrom)
        XCTAssertEqual(storedTask?.recurrenceSeriesID, seriesID)
    }

    func testRepositoryRoundTripsFiniteRecurringTaskCounts() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = TasksRepository(modelContext: ModelContext(container))
        let task = FocusTask(
            title: "Daily drill",
            estimatedMinutes: 25,
            priority: .medium,
            repeatRule: .daily,
            repeatTotalCount: 13,
            repeatRemainingCount: 13,
            recurrenceSeriesID: UUID()
        )

        try repository.save(task)

        let storedTask = try repository.fetchAll().first
        XCTAssertEqual(storedTask?.repeatTotalCount, 13)
        XCTAssertEqual(storedTask?.repeatRemainingCount, 13)
    }
}
