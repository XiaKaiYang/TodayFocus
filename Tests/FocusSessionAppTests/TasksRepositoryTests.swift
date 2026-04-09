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

    func testRepositoryRoundTripsTaskSubtasksAndDisplayOrder() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = TasksRepository(modelContext: ModelContext(container))
        let task = FocusTask(
            title: "English listening",
            estimatedMinutes: 35,
            priority: .high,
            subtasks: [
                TaskSubtask(title: "Section A"),
                TaskSubtask(title: "Section B", isCompleted: true)
            ],
            displayOrder: 2
        )

        try repository.save(task)

        let storedTask = try repository.fetchAll().first
        XCTAssertEqual(storedTask?.subtasks.map(\.title), ["Section A", "Section B"])
        XCTAssertEqual(storedTask?.subtasks.map(\.isCompleted), [false, true])
        XCTAssertEqual(storedTask?.displayOrder, 2)
    }

    func testCompleteRecurringTaskCreatesSuccessorWithResetSubtasksAndInheritedDisplayOrder() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = TasksRepository(modelContext: ModelContext(container))
        let seriesID = UUID()
        let task = FocusTask(
            title: "Listening drill",
            estimatedMinutes: 25,
            priority: .medium,
            subtasks: [
                TaskSubtask(title: "Part 1", isCompleted: true),
                TaskSubtask(title: "Part 2")
            ],
            repeatRule: .daily,
            repeatTotalCount: 3,
            repeatRemainingCount: 3,
            recurrenceSeriesID: seriesID,
            displayOrder: 1
        )
        try repository.save(task)

        try repository.completeTask(
            id: task.id,
            completedAt: Date(timeIntervalSince1970: 10_000)
        )

        let storedTasks = try repository.fetchAll()
        XCTAssertEqual(storedTasks.count, 2)

        let completedTask = try XCTUnwrap(storedTasks.first(where: { $0.id == task.id }))
        XCTAssertTrue(completedTask.isCompleted)

        let successor = try XCTUnwrap(storedTasks.first(where: { $0.id != task.id }))
        XCTAssertEqual(successor.subtasks.map(\.title), ["Part 1", "Part 2"])
        XCTAssertEqual(successor.subtasks.map(\.isCompleted), [false, false])
        XCTAssertEqual(successor.displayOrder, 1)
        XCTAssertEqual(successor.repeatRemainingCount, 2)
        XCTAssertEqual(successor.recurrenceSeriesID, seriesID)
    }

    func testUpdateRecurringInstanceRemovesOtherActiveTasksInSeriesButKeepsCompletedHistory() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = TasksRepository(modelContext: ModelContext(container))
        let seriesID = UUID()
        let currentTask = FocusTask(
            title: "Listening",
            estimatedMinutes: 25,
            priority: .high,
            repeatRule: .daily,
            recurrenceSeriesID: seriesID
        )
        let duplicateTask = FocusTask(
            title: "Listening",
            estimatedMinutes: 25,
            priority: .high,
            repeatRule: .daily,
            visibleFrom: Date(timeIntervalSince1970: 20_000),
            recurrenceSeriesID: seriesID
        )
        let completedHistory = FocusTask(
            title: "Listening history",
            estimatedMinutes: 25,
            priority: .high,
            isCompleted: true,
            completedAt: Date(timeIntervalSince1970: 5_000),
            repeatRule: .daily,
            recurrenceSeriesID: seriesID
        )
        try repository.save(currentTask)
        try repository.save(duplicateTask)
        try repository.save(completedHistory)

        var editedTask = currentTask
        editedTask.title = "Listening updated"

        try repository.updateRecurringInstance(editedTask, previousSeriesID: seriesID)

        let storedTasks = try repository.fetchAll()
        XCTAssertEqual(storedTasks.filter { !$0.isCompleted }.count, 1)
        XCTAssertEqual(storedTasks.first(where: { $0.id == currentTask.id })?.title, "Listening updated")
        XCTAssertNotNil(storedTasks.first(where: { $0.id == completedHistory.id }))
    }
}
