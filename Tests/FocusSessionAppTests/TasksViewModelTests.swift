import SwiftData
import XCTest
@testable import FocusSession

@MainActor
final class TasksViewModelTests: XCTestCase {
    func testPresentCreateSheetAndSuccessfulCreateWithTimeRangeDismissesIt() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = TasksRepository(modelContext: ModelContext(container))
        let viewModel = TasksViewModel(repository: repository)
        viewModel.presentCreateSheet()

        XCTAssertTrue(viewModel.isPresentingCreateSheet)

        viewModel.newTaskTitle = "Ship blocker polish"
        viewModel.newTaskDetails = "把网站规则也接上"
        viewModel.newEstimatedMinutes = 40
        viewModel.newTaskPriority = .medium
        viewModel.usesTimeRange = true
        viewModel.newTaskStartAt = Date(timeIntervalSince1970: 10_000)
        viewModel.newTaskEndAt = Date(timeIntervalSince1970: 12_400)

        XCTAssertTrue(viewModel.createTask())

        XCTAssertEqual(viewModel.tasks.map(\.title), ["Ship blocker polish"])
        XCTAssertEqual(viewModel.tasks.first?.priority, .medium)
        XCTAssertEqual(viewModel.tasks.first?.startAt, Date(timeIntervalSince1970: 10_000))
        XCTAssertEqual(viewModel.tasks.first?.endAt, Date(timeIntervalSince1970: 12_400))
        XCTAssertEqual(viewModel.newTaskTitle, "")
        XCTAssertEqual(viewModel.newTaskDetails, "")
        XCTAssertEqual(viewModel.newEstimatedMinutes, 25)
        XCTAssertEqual(viewModel.newTaskPriority, .none)
        XCTAssertFalse(viewModel.isPresentingCreateSheet)
    }

    func testPresentCreateSheetCanPrefillSubtaskLinkAndContribution() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = TasksRepository(modelContext: ModelContext(container))
        let linkedSubtaskID = UUID()
        let viewModel = TasksViewModel(repository: repository)

        viewModel.presentCreateSheet(
            linkedSubtaskID: linkedSubtaskID,
            linkedSubtaskTitle: "Report",
            contributionValue: 2.5
        )

        XCTAssertEqual(viewModel.linkedSubtaskID, linkedSubtaskID)
        XCTAssertEqual(viewModel.linkedSubtaskTitle, "Report")
        XCTAssertEqual(viewModel.contributionValueText, "2.5")
    }

    func testPresentCreateSheetDefaultsPriorityToNoneAndNoTimeRange() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = TasksRepository(modelContext: ModelContext(container))
        let viewModel = TasksViewModel(repository: repository)

        viewModel.newTaskPriority = .high
        viewModel.presentCreateSheet()

        XCTAssertEqual(viewModel.newTaskPriority, .none)
        XCTAssertFalse(viewModel.usesTimeRange)
        XCTAssertEqual(viewModel.newTaskRepeatRule, .none)
        XCTAssertEqual(viewModel.newTaskRepeatWeekday, .monday)
    }

    func testCreateTaskWithoutTimeRangePersistsNilSchedule() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = TasksRepository(modelContext: ModelContext(container))
        let viewModel = TasksViewModel(repository: repository)
        viewModel.presentCreateSheet()
        viewModel.newTaskTitle = "No schedule task"
        viewModel.usesTimeRange = false

        XCTAssertTrue(viewModel.saveTask())

        XCTAssertEqual(viewModel.tasks.first?.startAt, nil)
        XCTAssertEqual(viewModel.tasks.first?.endAt, nil)
    }

    func testInvalidCreateKeepsSheetOpenAndShowsError() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = TasksRepository(modelContext: ModelContext(container))
        let viewModel = TasksViewModel(repository: repository)
        viewModel.presentCreateSheet()
        viewModel.newTaskTitle = "   "

        XCTAssertFalse(viewModel.createTask())

        XCTAssertTrue(viewModel.isPresentingCreateSheet)
        XCTAssertEqual(viewModel.errorMessage, "Task title is required.")
    }

    func testStartFocusUsesTaskCallback() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = TasksRepository(modelContext: ModelContext(container))
        let task = FocusTask(title: "Review policy iteration", estimatedMinutes: 25)
        try repository.save(task)

        var startedTask: FocusTask?
        let viewModel = TasksViewModel(
            repository: repository,
            onStartTask: { task, _ in
                startedTask = task
            }
        )

        viewModel.startFocus(for: task)

        XCTAssertEqual(startedTask?.id, task.id)
        XCTAssertEqual(startedTask?.title, "Review policy iteration")
    }

    func testStartFocusUsesTaskAndSubtaskCallbackForParentSelection() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = TasksRepository(modelContext: ModelContext(container))
        let task = FocusTask(
            title: "Practice listening",
            estimatedMinutes: 45,
            subtasks: [
                TaskSubtask(title: "Stairs"),
                TaskSubtask(title: "Sentence shadowing")
            ]
        )
        try repository.save(task)

        var startedTask: FocusTask?
        var startedSubtask: TaskSubtask?
        let viewModel = TasksViewModel(
            repository: repository,
            onStartTask: { task, subtask in
                startedTask = task
                startedSubtask = subtask
            }
        )
        let selectedSubtask = try XCTUnwrap(task.subtasks.last)

        viewModel.startFocus(for: task, subtask: selectedSubtask)

        XCTAssertEqual(startedTask?.id, task.id)
        XCTAssertEqual(startedSubtask?.id, selectedSubtask.id)
        XCTAssertEqual(startedSubtask?.title, "Sentence shadowing")
    }

    func testTasksAreGroupedByPriorityWhileCompletedTasksMoveToTrash() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = TasksRepository(modelContext: ModelContext(container))

        try repository.save(
            FocusTask(
                title: "High pending",
                estimatedMinutes: 25,
                priority: .high,
                createdAt: Date(timeIntervalSince1970: 300)
            )
        )
        try repository.save(
            FocusTask(
                title: "High done",
                estimatedMinutes: 25,
                priority: .high,
                isCompleted: true,
                createdAt: Date(timeIntervalSince1970: 100),
                completedAt: Date(timeIntervalSince1970: 400)
            )
        )
        try repository.save(
            FocusTask(
                title: "Medium pending",
                estimatedMinutes: 25,
                priority: .medium,
                createdAt: Date(timeIntervalSince1970: 200)
            )
        )
        try repository.save(
            FocusTask(
                title: "Low pending",
                estimatedMinutes: 25,
                priority: .low,
                createdAt: Date(timeIntervalSince1970: 150)
            )
        )
        try repository.save(
            FocusTask(
                title: "No priority",
                estimatedMinutes: 25,
                priority: .none,
                createdAt: Date(timeIntervalSince1970: 250)
            )
        )

        let viewModel = TasksViewModel(repository: repository)

        XCTAssertEqual(viewModel.prioritySections.map(\.priority), [.high, .medium, .low, .none])
        XCTAssertEqual(viewModel.prioritySections[0].tasks.map(\.title), ["High pending"])
        XCTAssertEqual(viewModel.prioritySections[1].tasks.map(\.title), ["Medium pending"])
        XCTAssertEqual(viewModel.prioritySections[2].tasks.map(\.title), ["Low pending"])
        XCTAssertEqual(viewModel.prioritySections[3].tasks.map(\.title), ["No priority"])
        XCTAssertEqual(viewModel.trashedTasks.map(\.title), ["High done"])
    }

    func testPrioritySectionsHideEmptyGroups() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = TasksRepository(modelContext: ModelContext(container))

        try repository.save(
            FocusTask(
                title: "High pending",
                estimatedMinutes: 25,
                priority: .high,
                createdAt: Date(timeIntervalSince1970: 300)
            )
        )
        try repository.save(
            FocusTask(
                title: "No priority",
                estimatedMinutes: 25,
                priority: .none,
                createdAt: Date(timeIntervalSince1970: 250)
            )
        )

        let viewModel = TasksViewModel(repository: repository)

        XCTAssertEqual(viewModel.prioritySections.map(\.priority), [.high, .none])
        XCTAssertEqual(viewModel.prioritySections[0].tasks.map(\.title), ["High pending"])
        XCTAssertEqual(viewModel.prioritySections[1].tasks.map(\.title), ["No priority"])
    }

    func testEditSheetLoadsTaskAndSaveUpdatesPriorityAndSchedule() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = TasksRepository(modelContext: ModelContext(container))
        let originalTask = FocusTask(
            title: "Practice listening",
            details: "Section A",
            estimatedMinutes: 25,
            priority: .low,
            startAt: Date(timeIntervalSince1970: 1_000),
            endAt: Date(timeIntervalSince1970: 2_500)
        )
        try repository.save(originalTask)

        let viewModel = TasksViewModel(repository: repository)

        viewModel.presentEditSheet(for: originalTask)
        viewModel.newTaskTitle = "Practice listening deeply"
        viewModel.newTaskDetails = "Section B"
        viewModel.newEstimatedMinutes = 45
        viewModel.newTaskPriority = .high
        viewModel.newTaskStartAt = Date(timeIntervalSince1970: 3_000)
        viewModel.newTaskEndAt = Date(timeIntervalSince1970: 5_700)

        XCTAssertTrue(viewModel.saveTask())

        let reloaded = try repository.fetchAll()
        XCTAssertEqual(reloaded.first?.title, "Practice listening deeply")
        XCTAssertEqual(reloaded.first?.details, "Section B")
        XCTAssertEqual(reloaded.first?.estimatedMinutes, 45)
        XCTAssertEqual(reloaded.first?.priority, .high)
        XCTAssertEqual(reloaded.first?.startAt, Date(timeIntervalSince1970: 3_000))
        XCTAssertEqual(reloaded.first?.endAt, Date(timeIntervalSince1970: 5_700))
        XCTAssertFalse(viewModel.isPresentingCreateSheet)
    }

    func testEditLinkedTaskPreservesSubtaskLinkMetadata() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = TasksRepository(modelContext: ModelContext(container))
        let originalTask = FocusTask(
            title: "Linked task",
            estimatedMinutes: 25,
            priority: .medium,
            linkedSubtaskID: UUID(),
            contributionValue: 3
        )
        try repository.save(originalTask)

        let viewModel = TasksViewModel(repository: repository)
        viewModel.presentEditSheet(for: originalTask)
        viewModel.newTaskTitle = "Linked task updated"

        XCTAssertTrue(viewModel.saveTask())

        let reloaded = try repository.fetchAll()
        XCTAssertEqual(reloaded.first?.linkedSubtaskID, originalTask.linkedSubtaskID)
        XCTAssertEqual(reloaded.first?.contributionValue, 3)
    }

    func testInvalidScheduleKeepsComposerOpenAndShowsError() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = TasksRepository(modelContext: ModelContext(container))
        let viewModel = TasksViewModel(repository: repository)
        viewModel.presentCreateSheet()
        viewModel.newTaskTitle = "Schedule review"
        viewModel.usesTimeRange = true
        viewModel.newTaskStartAt = Date(timeIntervalSince1970: 5_000)
        viewModel.newTaskEndAt = Date(timeIntervalSince1970: 4_000)

        XCTAssertFalse(viewModel.saveTask())

        XCTAssertTrue(viewModel.isPresentingCreateSheet)
        XCTAssertEqual(viewModel.errorMessage, "End time must be later than start time.")
    }

    func testEditTaskCanClearExistingTimeRange() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = TasksRepository(modelContext: ModelContext(container))
        let originalTask = FocusTask(
            title: "Scheduled task",
            estimatedMinutes: 25,
            priority: .medium,
            startAt: Date(timeIntervalSince1970: 1_000),
            endAt: Date(timeIntervalSince1970: 2_500)
        )
        try repository.save(originalTask)

        let viewModel = TasksViewModel(repository: repository)
        viewModel.presentEditSheet(for: originalTask)
        viewModel.usesTimeRange = false

        XCTAssertTrue(viewModel.saveTask())

        let reloaded = try repository.fetchAll()
        XCTAssertEqual(reloaded.first?.startAt, nil)
        XCTAssertEqual(reloaded.first?.endAt, nil)
    }

    func testMarkTaskCompletedSetsCompletedStateAndCannotReopenIt() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = TasksRepository(modelContext: ModelContext(container))
        let initialNow = Date(timeIntervalSince1970: 8_000)
        let completedNow = Date(timeIntervalSince1970: 9_000)
        let task = FocusTask(
            title: "Finish RL reading",
            estimatedMinutes: 25,
            priority: .high,
            createdAt: initialNow
        )
        try repository.save(task)

        let viewModel = TasksViewModel(
            repository: repository,
            now: { completedNow }
        )

        viewModel.markTaskCompleted(task)

        XCTAssertEqual(viewModel.tasks.first?.isCompleted, true)
        XCTAssertEqual(viewModel.tasks.first?.completedAt, completedNow)
        XCTAssertEqual(viewModel.tasks.count, 1)

        viewModel.markTaskCompleted(task)

        XCTAssertEqual(viewModel.tasks.first?.isCompleted, true)
        XCTAssertEqual(viewModel.tasks.first?.completedAt, completedNow)
        XCTAssertEqual(viewModel.tasks.count, 1)
    }

    func testRestoreTaskMovesItOutOfTrashAndBackIntoPrioritySections() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = TasksRepository(modelContext: ModelContext(container))
        let task = FocusTask(
            title: "Recover task",
            estimatedMinutes: 25,
            priority: .medium,
            isCompleted: true,
            createdAt: Date(timeIntervalSince1970: 1_000),
            completedAt: Date(timeIntervalSince1970: 2_000)
        )
        try repository.save(task)

        let viewModel = TasksViewModel(repository: repository)

        XCTAssertEqual(viewModel.trashedTasks.map(\.title), ["Recover task"])

        viewModel.restoreTask(task)

        XCTAssertEqual(viewModel.trashedTasks, [])
        XCTAssertEqual(viewModel.prioritySections.map(\.priority), [.medium])
        XCTAssertEqual(viewModel.prioritySections.first?.tasks.map(\.title), ["Recover task"])
        XCTAssertEqual(viewModel.prioritySections.first?.tasks.first?.isCompleted, false)
        XCTAssertEqual(viewModel.prioritySections.first?.tasks.first?.completedAt, nil)
    }

    func testMarkTaskCompletedSettlesSingleLinkedTaskContributionIntoSubtaskAndUnlinksTask() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let modelContext = ModelContext(container)
        let repository = TasksRepository(modelContext: modelContext)
        let planRepository = PlanGoalsRepository(modelContext: modelContext)
        let subtask = PlanGoalSubtask(
            id: UUID(),
            title: "RL",
            baselineValue: 0,
            targetValue: 5,
            unitLabel: "次",
            trackingMode: .quantified,
            goalSharePercent: 100
        )
        try planRepository.save(
            PlanGoal(
                title: "Master RL",
                status: .inProgress,
                startAt: Date(timeIntervalSince1970: 1_000),
                endAt: Date(timeIntervalSince1970: 2_000),
                subtasks: [subtask]
            )
        )
        let task = FocusTask(
            title: "Finish RL",
            estimatedMinutes: 30,
            priority: .high,
            linkedSubtaskID: subtask.id,
            contributionValue: 1
        )
        try repository.save(task)

        let coordinator = LinkedTaskSettlementCoordinator(
            tasksRepository: repository,
            planGoalsRepository: planRepository
        )
        let viewModel = TasksViewModel(
            repository: repository,
            linkedTaskSettlementCoordinator: coordinator,
            now: { Date(timeIntervalSince1970: 9_000) }
        )

        viewModel.markTaskCompleted(task)

        let storedTask = try XCTUnwrap(try repository.fetchAll().first(where: { $0.id == task.id }))
        XCTAssertTrue(storedTask.isCompleted)
        XCTAssertNil(storedTask.linkedSubtaskID)
        XCTAssertNil(storedTask.contributionValue)
        XCTAssertEqual(storedTask.settledLinkedSubtaskID, subtask.id)
        XCTAssertEqual(storedTask.settledContributionValue, 1)

        let refreshedGoal = try XCTUnwrap(try planRepository.fetchAll().first)
        XCTAssertEqual(refreshedGoal.subtasks.first?.baselineValue, 1)

        let planViewModel = PlanViewModel(
            repository: planRepository,
            tasksRepository: repository,
            now: { Date(timeIntervalSince1970: 9_000) }
        )
        let refreshedSubtask = try XCTUnwrap(planViewModel.goals.first?.subtasks.first)
        XCTAssertEqual(planViewModel.currentValue(for: refreshedSubtask), 1)
        XCTAssertEqual(planViewModel.linkedTaskCount(for: refreshedSubtask), 0)
    }

    func testRestoreSettledLinkedTaskSubtractsContributionAndRelinksTask() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let modelContext = ModelContext(container)
        let repository = TasksRepository(modelContext: modelContext)
        let planRepository = PlanGoalsRepository(modelContext: modelContext)
        let subtask = PlanGoalSubtask(
            id: UUID(),
            title: "A",
            baselineValue: 1,
            targetValue: 10,
            unitLabel: "次",
            trackingMode: .quantified,
            goalSharePercent: 100
        )
        try planRepository.save(
            PlanGoal(
                title: "Ship paper",
                status: .inProgress,
                startAt: Date(timeIntervalSince1970: 1_000),
                endAt: Date(timeIntervalSince1970: 2_000),
                subtasks: [subtask]
            )
        )
        let task = FocusTask(
            title: "Recovered linked task",
            estimatedMinutes: 25,
            priority: .medium,
            isCompleted: true,
            completedAt: Date(timeIntervalSince1970: 5_000),
            settledLinkedSubtaskID: subtask.id,
            settledContributionValue: 1
        )
        try repository.save(task)

        let coordinator = LinkedTaskSettlementCoordinator(
            tasksRepository: repository,
            planGoalsRepository: planRepository
        )
        let viewModel = TasksViewModel(
            repository: repository,
            linkedTaskSettlementCoordinator: coordinator
        )

        viewModel.restoreTask(task)

        let storedTask = try XCTUnwrap(try repository.fetchAll().first(where: { $0.id == task.id }))
        XCTAssertFalse(storedTask.isCompleted)
        XCTAssertNil(storedTask.completedAt)
        XCTAssertEqual(storedTask.linkedSubtaskID, subtask.id)
        XCTAssertEqual(storedTask.contributionValue, 1)
        XCTAssertNil(storedTask.settledLinkedSubtaskID)
        XCTAssertNil(storedTask.settledContributionValue)

        let refreshedGoal = try XCTUnwrap(try planRepository.fetchAll().first)
        XCTAssertEqual(refreshedGoal.subtasks.first?.baselineValue, 0)
    }

    func testRestoreSettledLinkedTaskShowsErrorWhenSubtaskNoLongerSupportsLinking() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let modelContext = ModelContext(container)
        let repository = TasksRepository(modelContext: modelContext)
        let planRepository = PlanGoalsRepository(modelContext: modelContext)
        let subtask = PlanGoalSubtask(
            id: UUID(),
            title: "A",
            baselineValue: 2,
            targetValue: 10,
            unitLabel: "次",
            trackingMode: .quantified,
            goalSharePercent: 100
        )
        let goal = PlanGoal(
            title: "Ship paper",
            status: .inProgress,
            startAt: Date(timeIntervalSince1970: 1_000),
            endAt: Date(timeIntervalSince1970: 2_000),
            subtasks: [subtask]
        )
        try planRepository.save(goal)
        let task = FocusTask(
            title: "Recovered linked task",
            estimatedMinutes: 25,
            priority: .medium,
            isCompleted: true,
            completedAt: Date(timeIntervalSince1970: 5_000),
            settledLinkedSubtaskID: subtask.id,
            settledContributionValue: 1
        )
        try repository.save(task)

        var updatedGoal = try XCTUnwrap(try planRepository.fetchAll().first)
        updatedGoal.subtasks[0].trackingMode = .estimated
        updatedGoal.subtasks[0].baselineValue = 20
        updatedGoal.subtasks[0].targetValue = 100
        try planRepository.update(updatedGoal)

        let coordinator = LinkedTaskSettlementCoordinator(
            tasksRepository: repository,
            planGoalsRepository: planRepository
        )
        let viewModel = TasksViewModel(
            repository: repository,
            linkedTaskSettlementCoordinator: coordinator
        )

        viewModel.restoreTask(task)

        XCTAssertEqual(
            viewModel.errorMessage,
            "This linked subtask no longer supports task linking, so the task can't be restored."
        )
        let storedTask = try XCTUnwrap(try repository.fetchAll().first(where: { $0.id == task.id }))
        XCTAssertTrue(storedTask.isCompleted)
        XCTAssertEqual(storedTask.settledLinkedSubtaskID, subtask.id)
    }

    func testSaveTaskPersistsRecurringSettingsFromSharedComposer() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = TasksRepository(modelContext: ModelContext(container))
        let viewModel = TasksViewModel(repository: repository)

        viewModel.presentCreateSheet()
        viewModel.newTaskTitle = "Weekly review"
        viewModel.newTaskRepeatRule = .weekly
        viewModel.newTaskRepeatWeekday = .thursday

        XCTAssertTrue(viewModel.createTask())

        let storedTask = try repository.fetchAll().first
        XCTAssertEqual(storedTask?.repeatRule, .weekly)
        XCTAssertEqual(storedTask?.repeatWeekday, .thursday)
        XCTAssertNotNil(storedTask?.recurrenceSeriesID)
    }

    func testSaveTaskPersistsFiniteRepeatCountsFromSharedComposer() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = TasksRepository(modelContext: ModelContext(container))
        let viewModel = TasksViewModel(repository: repository)

        viewModel.presentCreateSheet()
        viewModel.newTaskTitle = "Read one paper"
        viewModel.newTaskRepeatRule = .daily
        viewModel.newTaskRepeatCountText = "13"

        XCTAssertTrue(viewModel.createTask())

        let storedTask = try repository.fetchAll().first
        XCTAssertEqual(storedTask?.repeatRule, .daily)
        XCTAssertEqual(storedTask?.repeatTotalCount, 13)
        XCTAssertEqual(storedTask?.repeatRemainingCount, 13)
    }

    func testCompletingDailyRepeatingTaskCreatesHiddenSuccessorForNextMorning() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = TasksRepository(modelContext: ModelContext(container))
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Shanghai") ?? .current
        let completionDate = makeDate(
            year: 2026,
            month: 3,
            day: 11,
            hour: 21,
            minute: 20,
            calendar: calendar
        )
        let task = FocusTask(
            title: "Daily drill",
            estimatedMinutes: 25,
            priority: .medium,
            repeatRule: .daily,
            recurrenceSeriesID: UUID()
        )
        try repository.save(task)

        let viewModel = TasksViewModel(
            repository: repository,
            now: { completionDate },
            calendar: calendar
        )

        viewModel.markTaskCompleted(task)

        let storedTasks = try repository.fetchAll().sorted { $0.createdAt < $1.createdAt }
        XCTAssertEqual(storedTasks.count, 2)
        XCTAssertEqual(storedTasks.filter(\.isCompleted).count, 1)
        let successor = try XCTUnwrap(storedTasks.first(where: { $0.isCompleted == false }))
        XCTAssertEqual(successor.repeatRule, .daily)
        XCTAssertEqual(successor.recurrenceSeriesID, task.recurrenceSeriesID)
        XCTAssertEqual(
            successor.visibleFrom,
            makeDate(year: 2026, month: 3, day: 12, hour: 6, minute: 0, calendar: calendar)
        )
        XCTAssertEqual(viewModel.prioritySections.flatMap(\.tasks), [])
    }

    func testCompletingWeeklyRepeatingTaskCreatesSuccessorOnSelectedWeekdayMorning() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = TasksRepository(modelContext: ModelContext(container))
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Shanghai") ?? .current
        let completionDate = makeDate(
            year: 2026,
            month: 3,
            day: 11,
            hour: 10,
            minute: 0,
            calendar: calendar
        )
        let seriesID = UUID()
        let task = FocusTask(
            title: "Weekly sync",
            estimatedMinutes: 25,
            priority: .medium,
            repeatRule: .weekly,
            repeatWeekday: .friday,
            recurrenceSeriesID: seriesID
        )
        try repository.save(task)

        let viewModel = TasksViewModel(
            repository: repository,
            now: { completionDate },
            calendar: calendar
        )

        viewModel.markTaskCompleted(task)

        let successor = try XCTUnwrap(try repository.fetchAll().first(where: { $0.isCompleted == false }))
        XCTAssertEqual(successor.repeatRule, .weekly)
        XCTAssertEqual(successor.repeatWeekday, .friday)
        XCTAssertEqual(successor.recurrenceSeriesID, seriesID)
        XCTAssertEqual(
            successor.visibleFrom,
            makeDate(year: 2026, month: 3, day: 13, hour: 6, minute: 0, calendar: calendar)
        )
    }

    func testFutureRecurringInstancesStayHiddenUntilVisibleFrom() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = TasksRepository(modelContext: ModelContext(container))
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Shanghai") ?? .current
        let visibleFrom = makeDate(year: 2026, month: 3, day: 12, hour: 6, minute: 0, calendar: calendar)
        let hiddenTask = FocusTask(
            title: "Tomorrow drill",
            estimatedMinutes: 25,
            priority: .high,
            repeatRule: .daily,
            visibleFrom: visibleFrom,
            recurrenceSeriesID: UUID()
        )
        try repository.save(hiddenTask)

        let hiddenViewModel = TasksViewModel(
            repository: repository,
            now: { self.makeDate(year: 2026, month: 3, day: 11, hour: 21, minute: 20, calendar: calendar) }
        )
        let visibleViewModel = TasksViewModel(
            repository: repository,
            now: { self.makeDate(year: 2026, month: 3, day: 12, hour: 6, minute: 5, calendar: calendar) }
        )

        XCTAssertEqual(hiddenViewModel.prioritySections.flatMap(\.tasks), [])
        XCTAssertEqual(visibleViewModel.prioritySections.flatMap(\.tasks).map(\.title), ["Tomorrow drill"])
    }

    func testTomorrowScopeIncludesActiveRecurringTasksAndTomorrowFirstAppearancesOnly() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = TasksRepository(modelContext: ModelContext(container))
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Shanghai") ?? .current
        let today = makeDate(year: 2026, month: 3, day: 11, hour: 9, minute: 0, calendar: calendar)
        let tomorrowMorning = makeDate(year: 2026, month: 3, day: 12, hour: 6, minute: 0, calendar: calendar)
        let dayAfterTomorrowMorning = makeDate(year: 2026, month: 3, day: 13, hour: 6, minute: 0, calendar: calendar)

        try repository.save(
            FocusTask(
                title: "Recurring already active",
                estimatedMinutes: 25,
                priority: .high,
                repeatRule: .daily,
                repeatTotalCount: 5,
                repeatRemainingCount: 4,
                visibleFrom: makeDate(year: 2026, month: 3, day: 10, hour: 6, minute: 0, calendar: calendar),
                recurrenceSeriesID: UUID()
            )
        )
        try repository.save(
            FocusTask(
                title: "Recurring starts tomorrow",
                estimatedMinutes: 30,
                priority: .medium,
                repeatRule: .weekly,
                repeatWeekday: .thursday,
                visibleFrom: tomorrowMorning,
                recurrenceSeriesID: UUID()
            )
        )
        try repository.save(
            FocusTask(
                title: "One-time tomorrow",
                estimatedMinutes: 20,
                priority: .low,
                visibleFrom: tomorrowMorning
            )
        )
        try repository.save(
            FocusTask(
                title: "Today only",
                estimatedMinutes: 15,
                priority: .high
            )
        )
        try repository.save(
            FocusTask(
                title: "Future recurring",
                estimatedMinutes: 40,
                priority: .medium,
                repeatRule: .weekly,
                repeatWeekday: .friday,
                visibleFrom: dayAfterTomorrowMorning,
                recurrenceSeriesID: UUID()
            )
        )
        try repository.save(
            FocusTask(
                title: "Future one-time",
                estimatedMinutes: 15,
                priority: .low,
                visibleFrom: dayAfterTomorrowMorning
            )
        )
        try repository.save(
            FocusTask(
                title: "Completed recurring",
                estimatedMinutes: 25,
                priority: .medium,
                isCompleted: true,
                completedAt: today,
                repeatRule: .daily,
                recurrenceSeriesID: UUID()
            )
        )

        let viewModel = TasksViewModel(
            repository: repository,
            now: { today },
            calendar: calendar
        )

        XCTAssertEqual(
            viewModel.prioritySections(in: .today).flatMap(\.tasks).map(\.title),
            ["Today only", "Recurring already active"]
        )
        XCTAssertEqual(
            viewModel.prioritySections(in: .tomorrow).flatMap(\.tasks).map(\.title),
            ["Recurring already active", "Recurring starts tomorrow", "One-time tomorrow"]
        )
    }

    func testRecurringProgressTextUsesCurrentIndexOverTotalAndInfinityForUnlimitedRepeats() {
        let finiteTask = FocusTask(
            title: "Finite repeating",
            repeatRule: .daily,
            repeatTotalCount: 5,
            repeatRemainingCount: 4
        )
        let infiniteTask = FocusTask(
            title: "Infinite repeating",
            repeatRule: .weekly,
            repeatWeekday: .monday
        )

        XCTAssertEqual(finiteTask.recurrenceProgressText, "2/5")
        XCTAssertEqual(infiniteTask.recurrenceProgressText, "∞")
    }

    func testCompletingRepeatingLinkedTaskPreservesSubtaskMetadataOnSuccessor() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = TasksRepository(modelContext: ModelContext(container))
        let linkedSubtaskID = UUID()
        let seriesID = UUID()
        let task = FocusTask(
            title: "Draft one section",
            estimatedMinutes: 30,
            priority: .high,
            linkedSubtaskID: linkedSubtaskID,
            contributionValue: 2.5,
            repeatRule: .daily,
            recurrenceSeriesID: seriesID
        )
        try repository.save(task)

        let viewModel = TasksViewModel(
            repository: repository,
            now: { Date(timeIntervalSince1970: 1_773_700_800) }
        )

        viewModel.markTaskCompleted(task)

        let successor = try XCTUnwrap(try repository.fetchAll().first(where: { $0.isCompleted == false }))
        XCTAssertEqual(successor.linkedSubtaskID, linkedSubtaskID)
        XCTAssertEqual(successor.contributionValue, 2.5)
        XCTAssertEqual(successor.recurrenceSeriesID, seriesID)
    }

    func testCompletingFinalFiniteRepeatingTaskDoesNotCreateSuccessor() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = TasksRepository(modelContext: ModelContext(container))
        let task = FocusTask(
            title: "Final drill",
            estimatedMinutes: 20,
            priority: .medium,
            repeatRule: .daily,
            repeatTotalCount: 3,
            repeatRemainingCount: 1,
            recurrenceSeriesID: UUID()
        )
        try repository.save(task)

        let viewModel = TasksViewModel(
            repository: repository,
            now: { Date(timeIntervalSince1970: 1_773_700_800) }
        )

        viewModel.markTaskCompleted(task)

        let storedTasks = try repository.fetchAll()
        XCTAssertEqual(storedTasks.count, 1)
        XCTAssertEqual(storedTasks.filter(\.isCompleted).count, 1)
    }

    func testCompletingFinalFiniteRepeatingLinkedTaskSettlesOnlyFinalOccurrence() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let modelContext = ModelContext(container)
        let repository = TasksRepository(modelContext: modelContext)
        let planRepository = PlanGoalsRepository(modelContext: modelContext)
        let subtask = PlanGoalSubtask(
            id: UUID(),
            title: "Weekly drills",
            baselineValue: 0,
            targetValue: 5,
            unitLabel: "次",
            trackingMode: .quantified,
            goalSharePercent: 100
        )
        try planRepository.save(
            PlanGoal(
                title: "Practice",
                status: .inProgress,
                startAt: Date(timeIntervalSince1970: 1_000),
                endAt: Date(timeIntervalSince1970: 2_000),
                subtasks: [subtask]
            )
        )
        let seriesID = UUID()
        let previousCompletedTask = FocusTask(
            title: "Drill week 1",
            estimatedMinutes: 20,
            priority: .medium,
            isCompleted: true,
            completedAt: Date(timeIntervalSince1970: 4_000),
            linkedSubtaskID: subtask.id,
            contributionValue: 1,
            repeatRule: .weekly,
            repeatWeekday: .monday,
            repeatTotalCount: 3,
            repeatRemainingCount: 2,
            recurrenceSeriesID: seriesID
        )
        let finalTask = FocusTask(
            title: "Drill week 3",
            estimatedMinutes: 20,
            priority: .medium,
            linkedSubtaskID: subtask.id,
            contributionValue: 1,
            repeatRule: .weekly,
            repeatWeekday: .monday,
            repeatTotalCount: 3,
            repeatRemainingCount: 1,
            recurrenceSeriesID: seriesID
        )
        try repository.save(previousCompletedTask)
        try repository.save(finalTask)

        let coordinator = LinkedTaskSettlementCoordinator(
            tasksRepository: repository,
            planGoalsRepository: planRepository
        )
        let viewModel = TasksViewModel(
            repository: repository,
            linkedTaskSettlementCoordinator: coordinator,
            now: { Date(timeIntervalSince1970: 1_773_700_800) }
        )

        viewModel.markTaskCompleted(finalTask)

        let storedTasks = try repository.fetchAll()
        XCTAssertEqual(storedTasks.count, 2)
        let refreshedFinalTask = try XCTUnwrap(storedTasks.first(where: { $0.id == finalTask.id }))
        let refreshedHistoryTask = try XCTUnwrap(storedTasks.first(where: { $0.id == previousCompletedTask.id }))
        XCTAssertTrue(refreshedFinalTask.isCompleted)
        XCTAssertNil(refreshedFinalTask.linkedSubtaskID)
        XCTAssertEqual(refreshedFinalTask.settledLinkedSubtaskID, subtask.id)
        XCTAssertEqual(refreshedHistoryTask.linkedSubtaskID, subtask.id)

        let refreshedGoal = try XCTUnwrap(try planRepository.fetchAll().first)
        XCTAssertEqual(refreshedGoal.subtasks.first?.baselineValue, 1)

        let planViewModel = PlanViewModel(
            repository: planRepository,
            tasksRepository: repository,
            now: { Date(timeIntervalSince1970: 1_773_700_800) }
        )
        let refreshedSubtask = try XCTUnwrap(planViewModel.goals.first?.subtasks.first)
        XCTAssertEqual(planViewModel.currentValue(for: refreshedSubtask), 2)
        XCTAssertEqual(planViewModel.linkedTaskCount(for: refreshedSubtask), 0)
    }

    func testEditSheetLoadsTaskSubtasksAndSavePersistsSubtaskChanges() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = TasksRepository(modelContext: ModelContext(container))
        let originalTask = FocusTask(
            title: "Listening practice",
            estimatedMinutes: 30,
            priority: .high,
            subtasks: [
                TaskSubtask(title: "Part A"),
                TaskSubtask(title: "Part B")
            ]
        )
        try repository.save(originalTask)

        let viewModel = TasksViewModel(repository: repository)
        viewModel.presentEditSheet(for: originalTask)

        XCTAssertEqual(viewModel.taskSubtasksDraft.map(\.title), ["Part A", "Part B"])

        let firstID = try XCTUnwrap(viewModel.taskSubtasksDraft.first?.id)
        let secondID = try XCTUnwrap(viewModel.taskSubtasksDraft.last?.id)
        viewModel.updateTaskSubtaskDraftTitle("Part A revised", id: firstID)
        viewModel.removeTaskSubtaskDraft(id: secondID)
        viewModel.addTaskSubtaskDraft()
        let thirdID = try XCTUnwrap(viewModel.taskSubtasksDraft.last?.id)
        viewModel.updateTaskSubtaskDraftTitle("Part C", id: thirdID)

        XCTAssertTrue(viewModel.saveTask())

        let reloadedTask = try XCTUnwrap(try repository.fetchAll().first)
        XCTAssertEqual(reloadedTask.subtasks.map(\.title), ["Part A revised", "Part C"])
        XCTAssertEqual(reloadedTask.subtasks.map(\.isCompleted), [false, false])
    }

    func testEditingLinkedRecurringTaskSubtasksCollapsesDuplicateActiveSeriesTasksAndKeepsSinglePlanLink() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let modelContext = ModelContext(container)
        let repository = TasksRepository(modelContext: modelContext)
        let planRepository = PlanGoalsRepository(modelContext: modelContext)
        let linkedSubtask = PlanGoalSubtask(
            id: UUID(),
            title: "Listening card",
            baselineValue: 0,
            targetValue: 10,
            unitLabel: "次",
            trackingMode: .quantified,
            goalSharePercent: 100
        )
        try planRepository.save(
            PlanGoal(
                title: "English",
                status: .inProgress,
                startAt: Date(timeIntervalSince1970: 1_000),
                endAt: Date(timeIntervalSince1970: 2_000),
                subtasks: [linkedSubtask]
            )
        )

        let seriesID = UUID()
        let currentTask = FocusTask(
            title: "Listening",
            estimatedMinutes: 30,
            priority: .high,
            subtasks: [TaskSubtask(title: "ladder Training")],
            createdAt: Date(timeIntervalSince1970: 10_000),
            linkedSubtaskID: linkedSubtask.id,
            contributionValue: 1,
            repeatRule: .daily,
            recurrenceSeriesID: seriesID
        )
        let duplicateTask = FocusTask(
            title: "Listening",
            estimatedMinutes: 30,
            priority: .high,
            subtasks: [TaskSubtask(title: "ladder Training")],
            createdAt: Date(timeIntervalSince1970: 20_000),
            linkedSubtaskID: linkedSubtask.id,
            contributionValue: 1,
            repeatRule: .daily,
            visibleFrom: Date(timeIntervalSince1970: 20_000),
            recurrenceSeriesID: seriesID
        )
        try repository.save(currentTask)
        try repository.save(duplicateTask)

        let viewModel = TasksViewModel(repository: repository)
        viewModel.presentEditSheet(for: currentTask)
        viewModel.addTaskSubtaskDraft()
        let reviewID = try XCTUnwrap(viewModel.taskSubtasksDraft.last?.id)
        viewModel.updateTaskSubtaskDraftTitle("Review", id: reviewID)

        XCTAssertTrue(viewModel.saveTask())

        let activeTasks = try repository.fetchAll().filter { !$0.isCompleted }
        XCTAssertEqual(activeTasks.count, 1)

        let refreshedTask = try XCTUnwrap(activeTasks.first(where: { $0.id == currentTask.id }))
        XCTAssertEqual(refreshedTask.recurrenceSeriesID, seriesID)
        XCTAssertEqual(refreshedTask.subtasks.map { $0.title }, ["ladder Training", "Review"])

        let planViewModel = PlanViewModel(
            repository: planRepository,
            tasksRepository: repository,
            now: { Date(timeIntervalSince1970: 10_000) }
        )
        let refreshedLinkedSubtask = try XCTUnwrap(planViewModel.goals.first?.subtasks.first)
        XCTAssertEqual(planViewModel.linkedTaskCount(for: refreshedLinkedSubtask), 1)
    }

    func testCompletingEditedRecurringTaskProducesSingleSuccessorWithUpdatedSubtasks() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = TasksRepository(modelContext: ModelContext(container))
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Shanghai") ?? .current

        let seriesID = UUID()
        let currentTask = FocusTask(
            title: "Listening",
            estimatedMinutes: 30,
            priority: .high,
            subtasks: [TaskSubtask(title: "ladder Training")],
            createdAt: Date(timeIntervalSince1970: 10_000),
            repeatRule: .daily,
            recurrenceSeriesID: seriesID
        )
        let duplicateTask = FocusTask(
            title: "Listening",
            estimatedMinutes: 30,
            priority: .high,
            subtasks: [TaskSubtask(title: "ladder Training")],
            createdAt: Date(timeIntervalSince1970: 20_000),
            repeatRule: .daily,
            visibleFrom: Date(timeIntervalSince1970: 20_000),
            recurrenceSeriesID: seriesID
        )
        try repository.save(currentTask)
        try repository.save(duplicateTask)

        let viewModel = TasksViewModel(repository: repository)
        viewModel.presentEditSheet(for: currentTask)
        viewModel.addTaskSubtaskDraft()
        let reviewID = try XCTUnwrap(viewModel.taskSubtasksDraft.last?.id)
        viewModel.updateTaskSubtaskDraftTitle("Review", id: reviewID)
        XCTAssertTrue(viewModel.saveTask())

        let completedAt = makeDate(year: 2026, month: 3, day: 15, hour: 21, minute: 0, calendar: calendar)
        try repository.completeTask(id: currentTask.id, completedAt: completedAt, calendar: calendar)

        let storedTasks = try repository.fetchAll()
        XCTAssertEqual(storedTasks.filter { !$0.isCompleted }.count, 1)
        let successor = try XCTUnwrap(storedTasks.first(where: { $0.isCompleted == false }))
        XCTAssertEqual(successor.subtasks.map { $0.title }, ["ladder Training", "Review"])
        XCTAssertEqual(successor.recurrenceSeriesID, seriesID)
    }

    func testMarkTaskCompletedDoesNothingWhenTaskHasSubtasks() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = TasksRepository(modelContext: ModelContext(container))
        let task = FocusTask(
            title: "English drills",
            estimatedMinutes: 25,
            priority: .high,
            subtasks: [TaskSubtask(title: "Part A")]
        )
        try repository.save(task)

        let viewModel = TasksViewModel(repository: repository)
        viewModel.markTaskCompleted(task)

        let storedTask = try XCTUnwrap(try repository.fetchAll().first)
        XCTAssertFalse(storedTask.isCompleted)
        XCTAssertEqual(viewModel.prioritySections.first?.tasks.map(\.title), ["English drills"])
    }

    func testCompletingLastSubtaskAutomaticallyCompletesParentTaskAndMovesItToTrash() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = TasksRepository(modelContext: ModelContext(container))
        let task = FocusTask(
            title: "Writing drill",
            estimatedMinutes: 25,
            priority: .medium,
            subtasks: [
                TaskSubtask(title: "Draft", isCompleted: true),
                TaskSubtask(title: "Polish")
            ]
        )
        try repository.save(task)

        let viewModel = TasksViewModel(
            repository: repository,
            now: { Date(timeIntervalSince1970: 12_000) }
        )

        let remainingSubtask = try XCTUnwrap(task.subtasks.last)
        viewModel.toggleTaskSubtaskCompletion(remainingSubtask, in: task)

        XCTAssertEqual(viewModel.prioritySections.flatMap(\.tasks), [])
        XCTAssertEqual(viewModel.trashedTasks.map(\.title), ["Writing drill"])
        let storedTask = try XCTUnwrap(try repository.fetchAll().first)
        XCTAssertTrue(storedTask.isCompleted)
        XCTAssertEqual(storedTask.completedAt, Date(timeIntervalSince1970: 12_000))
    }

    func testCompletingNonFinalSubtaskKeepsParentTaskActive() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = TasksRepository(modelContext: ModelContext(container))
        let task = FocusTask(
            title: "Listening drill",
            estimatedMinutes: 25,
            priority: .medium,
            subtasks: [
                TaskSubtask(title: "Part A"),
                TaskSubtask(title: "Part B")
            ]
        )
        try repository.save(task)

        let viewModel = TasksViewModel(
            repository: repository,
            now: { Date(timeIntervalSince1970: 12_000) }
        )
        let firstSubtask = try XCTUnwrap(task.subtasks.first)

        viewModel.toggleTaskSubtaskCompletion(firstSubtask, in: task)

        XCTAssertEqual(viewModel.prioritySections.flatMap(\.tasks).map(\.title), ["Listening drill"])
        XCTAssertEqual(viewModel.trashedTasks, [])

        let storedTask = try XCTUnwrap(try repository.fetchAll().first)
        XCTAssertFalse(storedTask.isCompleted)
        XCTAssertEqual(storedTask.subtasks.map(\.isCompleted), [true, false])
    }

    func testRestoreTaskWithSubtasksResetsAllSubtasksToIncomplete() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = TasksRepository(modelContext: ModelContext(container))
        let task = FocusTask(
            title: "Recover checklist",
            estimatedMinutes: 25,
            priority: .medium,
            subtasks: [
                TaskSubtask(title: "One", isCompleted: true),
                TaskSubtask(title: "Two", isCompleted: true)
            ],
            isCompleted: true,
            completedAt: Date(timeIntervalSince1970: 2_000)
        )
        try repository.save(task)

        let viewModel = TasksViewModel(repository: repository)
        viewModel.restoreTask(task)

        let storedTask = try XCTUnwrap(try repository.fetchAll().first)
        XCTAssertFalse(storedTask.isCompleted)
        XCTAssertEqual(storedTask.subtasks.map(\.isCompleted), [false, false])
    }

    func testMoveTaskReordersWithinSamePriorityAndPersistsDisplayOrder() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = TasksRepository(modelContext: ModelContext(container))
        let first = FocusTask(
            title: "First",
            estimatedMinutes: 25,
            priority: .high,
            displayOrder: 0
        )
        let second = FocusTask(
            title: "Second",
            estimatedMinutes: 25,
            priority: .high,
            displayOrder: 1
        )
        let third = FocusTask(
            title: "Third",
            estimatedMinutes: 25,
            priority: .high,
            displayOrder: 2
        )
        try repository.save(first)
        try repository.save(second)
        try repository.save(third)

        let viewModel = TasksViewModel(repository: repository)
        viewModel.moveTask(second.id, to: first.id)

        XCTAssertEqual(viewModel.prioritySections.first?.tasks.map(\.title), ["Second", "First", "Third"])

        let storedTasks = try repository.fetchAll()
        XCTAssertEqual(storedTasks.first(where: { $0.id == second.id })?.displayOrder, 0)
        XCTAssertEqual(storedTasks.first(where: { $0.id == first.id })?.displayOrder, 1)
        XCTAssertEqual(storedTasks.first(where: { $0.id == third.id })?.displayOrder, 2)
    }

    func testMoveTaskIgnoresDifferentPriorityTarget() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = TasksRepository(modelContext: ModelContext(container))
        let highTask = FocusTask(
            title: "High",
            estimatedMinutes: 25,
            priority: .high,
            displayOrder: 0
        )
        let mediumTask = FocusTask(
            title: "Medium",
            estimatedMinutes: 25,
            priority: .medium,
            displayOrder: 0
        )
        try repository.save(highTask)
        try repository.save(mediumTask)

        let viewModel = TasksViewModel(repository: repository)
        viewModel.moveTask(highTask.id, to: mediumTask.id)

        XCTAssertEqual(viewModel.prioritySections.map(\.priority), [.high, .medium])
        XCTAssertEqual(viewModel.prioritySections[0].tasks.map(\.title), ["High"])
        XCTAssertEqual(viewModel.prioritySections[1].tasks.map(\.title), ["Medium"])
    }

    func testCreateTaskInsertsNewTaskAtTopOfPrioritySection() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = TasksRepository(modelContext: ModelContext(container))
        try repository.save(
            FocusTask(
                title: "Existing high",
                estimatedMinutes: 25,
                priority: .high,
                createdAt: Date(timeIntervalSince1970: 10_000)
            )
        )

        let viewModel = TasksViewModel(
            repository: repository,
            now: { Date(timeIntervalSince1970: 5_000) }
        )
        viewModel.presentCreateSheet()
        viewModel.newTaskTitle = "New high"
        viewModel.newTaskPriority = .high

        XCTAssertTrue(viewModel.saveTask())
        XCTAssertEqual(viewModel.prioritySections.first?.tasks.map(\.title), ["New high", "Existing high"])
    }

    private func makeDate(
        year: Int,
        month: Int,
        day: Int,
        hour: Int,
        minute: Int,
        calendar: Calendar
    ) -> Date {
        calendar.date(
            from: DateComponents(
                year: year,
                month: month,
                day: day,
                hour: hour,
                minute: minute
            )
        ) ?? Date(timeIntervalSince1970: 0)
    }
}
