import XCTest
import SwiftData
import FocusSessionCore
@testable import FocusSession

@MainActor
final class CurrentSessionViewModelTests: XCTestCase {
    func testStartSessionTransitionsIntoFocusingForSelectedTodayTask() throws {
        let harness = try makeHarness()
        let task = try saveTask(
            title: "Ship first vertical slice",
            estimatedMinutes: 25,
            in: harness.tasksRepository
        )
        harness.viewModel.selectTask(task)

        harness.viewModel.startSession()

        XCTAssertEqual(harness.viewModel.phaseText, "Focusing")
        XCTAssertEqual(harness.viewModel.remainingMinutesText, "25 min")
        XCTAssertNil(harness.viewModel.errorMessage)
    }

    func testStartSessionWritesRuntimeSnapshotForSelectedTodayTask() throws {
        let snapshotStore = RuntimeSnapshotStore(containerURL: makeTemporaryContainerURL())
        let harness = try makeHarness(snapshotStore: snapshotStore)
        let task = try saveTask(
            title: "Persist current session",
            estimatedMinutes: 25,
            in: harness.tasksRepository
        )
        harness.viewModel.selectTask(task)

        harness.viewModel.startSession()

        let snapshot = try snapshotStore.read()
        XCTAssertEqual(snapshot.intention, "Persist current session")
        XCTAssertEqual(snapshot.plannedDurationSeconds, 1500)
    }

    func testPauseAndResumeSessionFollowReducerPhases() throws {
        let harness = try makeHarness()
        let task = try saveTask(
            title: "Protect the flow",
            estimatedMinutes: 25,
            in: harness.tasksRepository
        )
        harness.viewModel.selectTask(task)

        harness.viewModel.startSession()
        harness.viewModel.pauseSession()
        XCTAssertEqual(harness.viewModel.phaseText, "Paused")

        harness.viewModel.resumeSession()
        XCTAssertEqual(harness.viewModel.phaseText, "Focusing")
    }

    func testExtendSessionIncreasesRemainingMinutes() throws {
        let harness = try makeHarness()
        let task = try saveTask(
            title: "Finish the main session UI",
            estimatedMinutes: 25,
            in: harness.tasksRepository
        )
        harness.viewModel.selectTask(task)

        harness.viewModel.startSession()
        harness.viewModel.extendSession(byMinutes: 5)

        XCTAssertEqual(harness.viewModel.remainingMinutesText, "30 min")
    }

    func testFinishSessionTransitionsIntoReflecting() throws {
        let soundPlayer = RecordingCurrentSessionSoundEffectPlayer()
        let harness = try makeHarness(soundEffectPlayer: soundPlayer)
        let task = try saveTask(
            title: "Wrap up the focus block",
            estimatedMinutes: 25,
            in: harness.tasksRepository
        )
        harness.viewModel.selectTask(task)

        harness.viewModel.startSession()
        harness.viewModel.finishSession()

        XCTAssertEqual(harness.viewModel.phaseText, "Reflecting")
        XCTAssertTrue(harness.viewModel.showReflectionComposer)
        XCTAssertNil(harness.viewModel.errorMessage)
        XCTAssertEqual(
            soundPlayer.requests,
            [SoundPlaybackRequest(assetName: "eventually.wav", volume: 0.65)]
        )
    }

    func testFinishSessionWhilePausedTransitionsIntoReflecting() throws {
        let harness = try makeHarness()
        let task = try saveTask(
            title: "Finish from pause",
            estimatedMinutes: 25,
            in: harness.tasksRepository
        )
        harness.viewModel.selectTask(task)

        harness.viewModel.startSession()
        harness.viewModel.pauseSession()
        harness.viewModel.finishSession()

        XCTAssertEqual(harness.viewModel.phaseText, "Reflecting")
        XCTAssertTrue(harness.viewModel.showReflectionComposer)
        XCTAssertNil(harness.viewModel.errorMessage)
    }

    func testFinishSessionClearsRuntimeSnapshot() throws {
        let snapshotStore = RuntimeSnapshotStore(containerURL: makeTemporaryContainerURL())
        let harness = try makeHarness(snapshotStore: snapshotStore)
        let task = try saveTask(
            title: "Persist and clear",
            estimatedMinutes: 25,
            in: harness.tasksRepository
        )
        harness.viewModel.selectTask(task)

        harness.viewModel.startSession()
        harness.viewModel.finishSession()

        XCTAssertThrowsError(try snapshotStore.read())
    }

    func testSubmittedReflectionCanStartAgainAfterSelectingAnotherTodayTask() throws {
        let harness = try makeHarness()
        let firstTask = try saveTask(
            title: "First block",
            estimatedMinutes: 25,
            in: harness.tasksRepository
        )
        let secondTask = try saveTask(
            title: "Second block",
            estimatedMinutes: 25,
            in: harness.tasksRepository
        )
        harness.viewModel.selectTask(firstTask)

        harness.viewModel.startSession()
        harness.viewModel.finishSession()
        harness.viewModel.selectReflectionMood(.focused)
        harness.viewModel.submitReflection()

        harness.viewModel.selectTask(secondTask)
        harness.viewModel.startSession()

        XCTAssertEqual(harness.viewModel.phaseText, "Focusing")
        XCTAssertEqual(harness.viewModel.remainingMinutesText, "25 min")
        XCTAssertNil(harness.viewModel.errorMessage)
    }

    func testMenuBarTitleUsesTaskTextDuringAnActiveSession() throws {
        let harness = try makeHarness()
        let task = try saveTask(
            title: "Practice listening",
            estimatedMinutes: 30,
            in: harness.tasksRepository
        )

        XCTAssertEqual(harness.viewModel.menuBarTitle, "TodayFocus")

        harness.viewModel.selectTask(task)
        harness.viewModel.startSession()
        XCTAssertEqual(harness.viewModel.menuBarTitle, "Practice listening")

        harness.viewModel.finishSession()
        XCTAssertEqual(harness.viewModel.menuBarTitle, "TodayFocus")
    }

    func testStatusItemTitleShowsTaskAndLiveCountdownDuringActiveSession() throws {
        var currentDate = Date(timeIntervalSince1970: 1_000)
        let harness = try makeHarness(now: { currentDate })
        let task = try saveTask(
            title: "Practice listening",
            estimatedMinutes: 30,
            in: harness.tasksRepository
        )

        XCTAssertEqual(harness.viewModel.statusItemTitle(at: currentDate), "TodayFocus")

        harness.viewModel.selectTask(task)
        harness.viewModel.startSession()
        XCTAssertEqual(
            harness.viewModel.statusItemTitle(at: currentDate),
            "Practice listening · 30:00"
        )

        currentDate.addTimeInterval(61)
        XCTAssertEqual(
            harness.viewModel.statusItemTitle(at: currentDate),
            "Practice listening · 28:59"
        )

        harness.viewModel.finishSession()
        XCTAssertEqual(harness.viewModel.statusItemTitle(at: currentDate), "TodayFocus")
    }

    func testStartSessionRequiresSelectedTodayTaskWhenNoTodayTasksExist() throws {
        let harness = try makeHarness()
        harness.viewModel.intention = "Manual deep work block"

        harness.viewModel.startSession()

        XCTAssertEqual(harness.viewModel.phaseText, "Idle")
        XCTAssertEqual(harness.viewModel.errorMessage, "Create a task in Today first.")
    }

    func testStartSessionRequiresSelectedTodayTaskWhenTodayTasksExist() throws {
        let harness = try makeHarness()
        _ = try saveTask(
            title: "Available today",
            estimatedMinutes: 25,
            in: harness.tasksRepository
        )
        harness.viewModel.reloadData()
        harness.viewModel.intention = "Still should not start manually"

        harness.viewModel.startSession()

        XCTAssertEqual(harness.viewModel.phaseText, "Idle")
        XCTAssertEqual(harness.viewModel.errorMessage, "Select a Today task first.")
    }

    func testStartSessionRequiresDurationAboveZero() throws {
        let harness = try makeHarness()
        let task = try saveTask(
            title: "Zero-duration block",
            estimatedMinutes: 25,
            in: harness.tasksRepository
        )
        harness.viewModel.selectTask(task)
        harness.viewModel.durationMinutes = 0

        harness.viewModel.startSession()

        XCTAssertEqual(harness.viewModel.phaseText, "Idle")
        XCTAssertEqual(harness.viewModel.errorMessage, "Turn the dial above 0 first.")
    }

    func testSelectTaskLoadsTodayPendingTasksAndConfiguresSession() throws {
        let harness = try makeHarness()
        let pendingTask = try saveTask(
            title: "Write MPC notes",
            estimatedMinutes: 35,
            in: harness.tasksRepository
        )
        _ = try saveTask(
            title: "Old completed task",
            estimatedMinutes: 20,
            isCompleted: true,
            completedAt: Date(),
            in: harness.tasksRepository
        )
        harness.viewModel.reloadData()

        XCTAssertEqual(harness.viewModel.availableTasks.map(\.title), ["Write MPC notes"])

        harness.viewModel.selectTask(pendingTask)

        XCTAssertEqual(harness.viewModel.selectedTaskID, pendingTask.id)
        XCTAssertEqual(harness.viewModel.durationMinutes, 35)
    }

    func testAvailableTaskSelectionsFlattenParentTaskIntoRemainingSubtasks() throws {
        let harness = try makeHarness()
        let parentTask = FocusTask(
            title: "Practice Listening",
            estimatedMinutes: 45,
            subtasks: [
                TaskSubtask(title: "Stairs"),
                TaskSubtask(title: "Sentence shadowing")
            ],
            createdAt: Date(timeIntervalSince1970: 2_000)
        )
        let standaloneTask = FocusTask(
            title: "Write notes",
            estimatedMinutes: 20,
            createdAt: Date(timeIntervalSince1970: 1_000)
        )
        try harness.tasksRepository.save(parentTask)
        try harness.tasksRepository.save(standaloneTask)

        harness.viewModel.reloadData()

        XCTAssertEqual(
            harness.viewModel.availableTaskSelections.map(\.selectorTitle),
            [
                "Practice Listening / Stairs",
                "Practice Listening / Sentence shadowing",
                "Write notes"
            ]
        )
        XCTAssertEqual(
            harness.viewModel.availableTaskSelections.map(\.activeTitle),
            ["Stairs", "Sentence shadowing", "Write notes"]
        )
    }

    func testAvailableTasksOnlyIncludeTodayVisibleTasks() throws {
        let now = Date(timeIntervalSince1970: 3_000)
        let harness = try makeHarness(now: { now })
        _ = try saveTask(
            title: "Visible today",
            estimatedMinutes: 25,
            in: harness.tasksRepository
        )
        _ = try saveTask(
            title: "Visible tomorrow",
            estimatedMinutes: 25,
            visibleFrom: now.addingTimeInterval(60 * 60),
            in: harness.tasksRepository
        )
        harness.viewModel.reloadData()

        XCTAssertEqual(harness.viewModel.availableTasks.map(\.title), ["Visible today"])
    }

    func testSelectTaskIgnoresTasksOutsideTodayList() throws {
        let now = Date(timeIntervalSince1970: 4_000)
        let harness = try makeHarness(now: { now })
        let futureTask = try saveTask(
            title: "Later task",
            estimatedMinutes: 25,
            visibleFrom: now.addingTimeInterval(60 * 60),
            in: harness.tasksRepository
        )

        harness.viewModel.selectTask(futureTask)

        XCTAssertNil(harness.viewModel.selectedTaskID)
        XCTAssertTrue(harness.viewModel.availableTasks.isEmpty)
    }

    func testSelectTaskSubtaskUsesCombinedSelectorTitleAndSubtaskSessionTitle() throws {
        let harness = try makeHarness()
        let task = FocusTask(
            title: "Practice Listening",
            estimatedMinutes: 45,
            subtasks: [
                TaskSubtask(title: "Stairs"),
                TaskSubtask(title: "Sentence shadowing")
            ]
        )
        try harness.tasksRepository.save(task)
        let selectedSubtask = try XCTUnwrap(task.subtasks.last)

        harness.viewModel.selectTask(task, subtask: selectedSubtask)

        XCTAssertEqual(harness.viewModel.selectedTaskTitle, "Practice Listening / Sentence shadowing")
        XCTAssertEqual(harness.viewModel.durationMinutes, 45)

        harness.viewModel.startSession()

        XCTAssertEqual(harness.viewModel.currentIntention, "Sentence shadowing")
        XCTAssertEqual(harness.viewModel.menuBarTitle, "Sentence shadowing")
    }

    func testRemainingTimeCountsDownAndPausesCleanly() throws {
        var currentDate = Date(timeIntervalSince1970: 1_000)
        let harness = try makeHarness(now: { currentDate })
        let task = try saveTask(
            title: "Run a real pomodoro",
            estimatedMinutes: 25,
            in: harness.tasksRepository
        )
        harness.viewModel.selectTask(task)

        harness.viewModel.startSession()
        XCTAssertEqual(harness.viewModel.remainingTimeText(at: currentDate), "25:00")

        currentDate.addTimeInterval(5 * 60)
        XCTAssertEqual(harness.viewModel.remainingTimeText(at: currentDate), "20:00")

        harness.viewModel.pauseSession()
        currentDate.addTimeInterval(4 * 60)
        XCTAssertEqual(harness.viewModel.remainingTimeText(at: currentDate), "20:00")

        harness.viewModel.resumeSession()
        currentDate.addTimeInterval(60)
        XCTAssertEqual(harness.viewModel.remainingTimeText(at: currentDate), "19:00")
    }

    func testFinishSessionEntersReflectingWithoutPersistingCompletedRecord() throws {
        var currentDate = Date(timeIntervalSince1970: 5_000)
        let harness = try makeHarness(now: { currentDate })
        let task = try saveTask(
            title: "Write RL notes",
            estimatedMinutes: 25,
            in: harness.tasksRepository
        )
        harness.viewModel.selectTask(task)

        harness.viewModel.startSession()
        currentDate.addTimeInterval(10 * 60)
        harness.viewModel.finishSession()

        XCTAssertEqual(harness.viewModel.phaseText, "Reflecting")
        XCTAssertTrue(harness.viewModel.showReflectionComposer)
        let records = try harness.focusRepository.fetchAll()
        XCTAssertEqual(records.count, 0)
    }

    func testInitLoadsRecentSessionsFromHistory() throws {
        let harness = try makeHarness()
        try harness.focusRepository.save(
            FocusSessionRecord(
                intention: "Review dynamic programming",
                startedAt: Date(timeIntervalSince1970: 2_000),
                endedAt: Date(timeIntervalSince1970: 3_500),
                notes: "Value iteration and policy iteration comparison.",
                wasCompleted: true
            )
        )

        let refreshedViewModel = CurrentSessionViewModel(
            snapshotStore: nil,
            focusSessionRepository: harness.focusRepository,
            tasksRepository: harness.tasksRepository
        )

        XCTAssertEqual(refreshedViewModel.recentSessions.count, 1)
        XCTAssertEqual(refreshedViewModel.recentSessions.first?.title, "Review dynamic programming")
        XCTAssertEqual(
            refreshedViewModel.recentSessions.first?.notePreview,
            "Value iteration and policy iteration comparison."
        )
    }

    func testSubmitReflectionPersistsMoodNotesAndRefreshesRecentSessions() throws {
        var currentDate = Date(timeIntervalSince1970: 8_000)
        let harness = try makeHarness(now: { currentDate })
        let task = try saveTask(
            title: "Study policy iteration",
            estimatedMinutes: 25,
            in: harness.tasksRepository
        )
        harness.viewModel.selectTask(task)
        harness.viewModel.sessionNotes = "Need to clarify why policy evaluation converges."

        harness.viewModel.startSession()
        currentDate.addTimeInterval(15 * 60)
        harness.viewModel.finishSession()
        harness.viewModel.selectReflectionMood(.focused)
        harness.viewModel.submitReflection()

        let records = try harness.focusRepository.fetchAll()
        XCTAssertEqual(records.first?.notes, "Need to clarify why policy evaluation converges.")
        XCTAssertEqual(records.first?.mood, .focused)
        XCTAssertEqual(harness.viewModel.recentSessions.count, 1)
        XCTAssertEqual(harness.viewModel.recentSessions.first?.title, "Study policy iteration")
        XCTAssertEqual(harness.viewModel.sessionNotes, "")
        let storedTask = try XCTUnwrap(
            try harness.tasksRepository.fetchAll().first(where: { $0.id == task.id })
        )
        XCTAssertTrue(storedTask.isCompleted)
        XCTAssertEqual(storedTask.completedAt, currentDate)
        XCTAssertNil(harness.viewModel.selectedTaskID)
        XCTAssertEqual(harness.viewModel.availableTasks, [])
    }

    func testSubmitReflectionCompletesOnlySelectedSubtaskAndClearsSelection() throws {
        var currentDate = Date(timeIntervalSince1970: 8_000)
        let harness = try makeHarness(now: { currentDate })
        let task = FocusTask(
            title: "Practice Listening",
            estimatedMinutes: 45,
            subtasks: [
                TaskSubtask(title: "Stairs"),
                TaskSubtask(title: "Sentence shadowing")
            ]
        )
        try harness.tasksRepository.save(task)
        let selectedSubtask = try XCTUnwrap(task.subtasks.first)

        harness.viewModel.selectTask(task, subtask: selectedSubtask)
        harness.viewModel.startSession()
        currentDate.addTimeInterval(45 * 60)
        harness.viewModel.finishSession()
        harness.viewModel.selectReflectionMood(.focused)
        harness.viewModel.submitReflection()

        let storedTask = try XCTUnwrap(
            try harness.tasksRepository.fetchAll().first(where: { $0.id == task.id })
        )
        XCTAssertFalse(storedTask.isCompleted)
        XCTAssertEqual(storedTask.subtasks.map(\.isCompleted), [true, false])
        XCTAssertNil(harness.viewModel.selectedTaskSelection)
        XCTAssertEqual(
            harness.viewModel.availableTaskSelections.map(\.selectorTitle),
            ["Practice Listening / Sentence shadowing"]
        )
    }

    func testSubmittingReflectionForLastRemainingSubtaskCompletesParentTaskAndSettlesLinkedContribution() throws {
        var currentDate = Date(timeIntervalSince1970: 8_000)
        let container = try FocusSessionModelContainer.makeInMemory()
        let modelContext = ModelContext(container)
        let focusRepository = FocusSessionRepository(modelContext: modelContext)
        let tasksRepository = TasksRepository(modelContext: modelContext)
        let planRepository = PlanGoalsRepository(modelContext: modelContext)
        let linkedPlanSubtask = PlanGoalSubtask(
            id: UUID(),
            title: "Listening total",
            baselineValue: 0,
            targetValue: 4,
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
                subtasks: [linkedPlanSubtask]
            )
        )
        let task = FocusTask(
            title: "Practice Listening",
            estimatedMinutes: 45,
            subtasks: [
                TaskSubtask(title: "Stairs", isCompleted: true),
                TaskSubtask(title: "Sentence shadowing")
            ],
            linkedSubtaskID: linkedPlanSubtask.id,
            contributionValue: 1
        )
        try tasksRepository.save(task)
        let coordinator = LinkedTaskSettlementCoordinator(
            tasksRepository: tasksRepository,
            planGoalsRepository: planRepository
        )
        let viewModel = CurrentSessionViewModel(
            snapshotStore: nil,
            focusSessionRepository: focusRepository,
            tasksRepository: tasksRepository,
            linkedTaskSettlementCoordinator: coordinator,
            now: { currentDate }
        )
        let selectedSubtask = try XCTUnwrap(task.subtasks.last)

        viewModel.selectTask(task, subtask: selectedSubtask)
        viewModel.startSession()
        currentDate.addTimeInterval(45 * 60)
        viewModel.finishSession()
        viewModel.selectReflectionMood(.focused)
        viewModel.submitReflection()

        let storedTask = try XCTUnwrap(
            try tasksRepository.fetchAll().first(where: { $0.id == task.id })
        )
        XCTAssertTrue(storedTask.isCompleted)
        XCTAssertEqual(storedTask.subtasks.map(\.isCompleted), [true, true])
        XCTAssertNil(storedTask.linkedSubtaskID)
        XCTAssertEqual(storedTask.settledLinkedSubtaskID, linkedPlanSubtask.id)
        XCTAssertNil(viewModel.selectedTaskSelection)
        XCTAssertEqual(viewModel.availableTaskSelections, [])

        let refreshedGoal = try XCTUnwrap(try planRepository.fetchAll().first)
        XCTAssertEqual(refreshedGoal.subtasks.first?.baselineValue, 1)
    }

    func testSubmitReflectionSettlesLinkedTaskContributionIntoSubtaskAndUnlinksTask() throws {
        var currentDate = Date(timeIntervalSince1970: 8_000)
        let container = try FocusSessionModelContainer.makeInMemory()
        let modelContext = ModelContext(container)
        let focusRepository = FocusSessionRepository(modelContext: modelContext)
        let tasksRepository = TasksRepository(modelContext: modelContext)
        let planRepository = PlanGoalsRepository(modelContext: modelContext)
        let subtask = PlanGoalSubtask(
            id: UUID(),
            title: "A",
            baselineValue: 0,
            targetValue: 4,
            unitLabel: "次",
            trackingMode: .quantified,
            goalSharePercent: 100
        )
        try planRepository.save(
            PlanGoal(
                title: "RL",
                status: .inProgress,
                startAt: Date(timeIntervalSince1970: 1_000),
                endAt: Date(timeIntervalSince1970: 2_000),
                subtasks: [subtask]
            )
        )
        let task = FocusTask(
            title: "Linked focus block",
            estimatedMinutes: 25,
            linkedSubtaskID: subtask.id,
            contributionValue: 1
        )
        try tasksRepository.save(task)
        let coordinator = LinkedTaskSettlementCoordinator(
            tasksRepository: tasksRepository,
            planGoalsRepository: planRepository
        )
        let viewModel = CurrentSessionViewModel(
            snapshotStore: nil,
            focusSessionRepository: focusRepository,
            tasksRepository: tasksRepository,
            linkedTaskSettlementCoordinator: coordinator,
            now: { currentDate }
        )
        viewModel.selectTask(task)

        viewModel.startSession()
        currentDate.addTimeInterval(25 * 60)
        viewModel.finishSession()
        viewModel.selectReflectionMood(.focused)
        viewModel.submitReflection()

        let storedTask = try XCTUnwrap(
            try tasksRepository.fetchAll().first(where: { $0.id == task.id })
        )
        XCTAssertTrue(storedTask.isCompleted)
        XCTAssertNil(storedTask.linkedSubtaskID)
        XCTAssertEqual(storedTask.settledLinkedSubtaskID, subtask.id)

        let refreshedGoal = try XCTUnwrap(try planRepository.fetchAll().first)
        XCTAssertEqual(refreshedGoal.subtasks.first?.baselineValue, 1)
    }

    func testSubmitReflectionAndContinueEpisodeRestartsSameTaskWithoutCompletingIt() throws {
        var currentDate = Date(timeIntervalSince1970: 8_000)
        let harness = try makeHarness(now: { currentDate })
        let task = try saveTask(
            title: "Study policy iteration",
            estimatedMinutes: 25,
            in: harness.tasksRepository
        )
        harness.viewModel.selectTask(task)
        harness.viewModel.sessionNotes = "Need one more block."

        harness.viewModel.startSession()
        currentDate.addTimeInterval(15 * 60)
        harness.viewModel.finishSession()
        harness.viewModel.selectReflectionMood(.focused)
        harness.viewModel.submitReflectionAndContinueEpisode()

        let records = try harness.focusRepository.fetchAll()
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?.notes, "Need one more block.")
        XCTAssertEqual(records.first?.mood, .focused)
        XCTAssertEqual(harness.viewModel.phaseText, "Focusing")
        XCTAssertEqual(harness.viewModel.remainingMinutesText, "25 min")
        XCTAssertEqual(harness.viewModel.selectedTaskID, task.id)
        XCTAssertEqual(harness.viewModel.currentIntention, "Study policy iteration")
        XCTAssertTrue(try XCTUnwrap(harness.tasksRepository.task(id: task.id)).isCompleted == false)
        XCTAssertEqual(harness.viewModel.sessionNotes, "")
        XCTAssertNil(harness.viewModel.selectedReflectionMood)
    }

    func testSubmitReflectionAndContinueEpisodeKeepsLinkedContributionUnsettled() throws {
        var currentDate = Date(timeIntervalSince1970: 8_000)
        let container = try FocusSessionModelContainer.makeInMemory()
        let modelContext = ModelContext(container)
        let focusRepository = FocusSessionRepository(modelContext: modelContext)
        let tasksRepository = TasksRepository(modelContext: modelContext)
        let planRepository = PlanGoalsRepository(modelContext: modelContext)
        let subtask = PlanGoalSubtask(
            id: UUID(),
            title: "A",
            baselineValue: 0,
            targetValue: 4,
            unitLabel: "次",
            trackingMode: .quantified,
            goalSharePercent: 100
        )
        try planRepository.save(
            PlanGoal(
                title: "RL",
                status: .inProgress,
                startAt: Date(timeIntervalSince1970: 1_000),
                endAt: Date(timeIntervalSince1970: 2_000),
                subtasks: [subtask]
            )
        )
        let task = FocusTask(
            title: "Linked focus block",
            estimatedMinutes: 25,
            linkedSubtaskID: subtask.id,
            contributionValue: 1
        )
        try tasksRepository.save(task)
        let coordinator = LinkedTaskSettlementCoordinator(
            tasksRepository: tasksRepository,
            planGoalsRepository: planRepository
        )
        let viewModel = CurrentSessionViewModel(
            snapshotStore: nil,
            focusSessionRepository: focusRepository,
            tasksRepository: tasksRepository,
            linkedTaskSettlementCoordinator: coordinator,
            now: { currentDate }
        )
        viewModel.selectTask(task)

        viewModel.startSession()
        currentDate.addTimeInterval(25 * 60)
        viewModel.finishSession()
        viewModel.selectReflectionMood(.focused)
        viewModel.submitReflectionAndContinueEpisode()

        let storedTask = try XCTUnwrap(try tasksRepository.task(id: task.id))
        XCTAssertFalse(storedTask.isCompleted)
        XCTAssertEqual(storedTask.linkedSubtaskID, subtask.id)
        XCTAssertNil(storedTask.settledLinkedSubtaskID)
        XCTAssertEqual(viewModel.phaseText, "Focusing")

        let refreshedGoal = try XCTUnwrap(try planRepository.fetchAll().first)
        XCTAssertEqual(refreshedGoal.subtasks.first?.baselineValue, 0)
    }

    func testSubmitReflectionAndContinueEpisodeStaysCompletedWhenSelectionDisappears() throws {
        var currentDate = Date(timeIntervalSince1970: 8_000)
        let harness = try makeHarness(now: { currentDate })
        let task = try saveTask(
            title: "Temporary block",
            estimatedMinutes: 25,
            in: harness.tasksRepository
        )
        harness.viewModel.selectTask(task)

        harness.viewModel.startSession()
        currentDate.addTimeInterval(15 * 60)
        harness.viewModel.finishSession()
        harness.viewModel.selectReflectionMood(.focused)
        try harness.tasksRepository.completeTask(id: task.id, completedAt: currentDate)

        harness.viewModel.submitReflectionAndContinueEpisode()

        XCTAssertEqual(harness.viewModel.phaseText, "Completed")
        XCTAssertFalse(harness.viewModel.showReflectionComposer)
        XCTAssertEqual(harness.viewModel.errorMessage, "Unable to continue because the selected Today task is no longer available.")
        XCTAssertNil(harness.viewModel.selectedTaskSelection)
        XCTAssertEqual(try harness.focusRepository.fetchAll().count, 1)
    }

    func testPrepareNextSessionReturnsToIdleAndClearsCompletedDraft() throws {
        let harness = try makeHarness()
        let task = try saveTask(
            title: "Close the focus loop",
            estimatedMinutes: 25,
            in: harness.tasksRepository
        )
        harness.viewModel.selectTask(task)
        harness.viewModel.sessionNotes = "Keep this visible after finish."

        harness.viewModel.startSession()
        harness.viewModel.finishSession()
        harness.viewModel.selectReflectionMood(.neutral)
        harness.viewModel.submitReflection()
        harness.viewModel.prepareNextSession()

        XCTAssertEqual(harness.viewModel.phaseText, "Idle")
        XCTAssertEqual(harness.viewModel.sessionNotes, "")
        XCTAssertNil(harness.viewModel.selectedTaskID)
    }

    func testCountdownCompletionTriggersReflectionOnlyOnce() throws {
        var currentDate = Date(timeIntervalSince1970: 12_000)
        let harness = try makeHarness(now: { currentDate })
        let task = try saveTask(
            title: "Auto-finish block",
            estimatedMinutes: 25,
            in: harness.tasksRepository
        )
        harness.viewModel.selectTask(task)

        harness.viewModel.startSession()
        currentDate.addTimeInterval(25 * 60)
        harness.viewModel.handleTimelineTick(at: currentDate)
        harness.viewModel.handleTimelineTick(at: currentDate.addingTimeInterval(1))

        XCTAssertEqual(harness.viewModel.phaseText, "Reflecting")
        XCTAssertTrue(harness.viewModel.showReflectionComposer)
        XCTAssertEqual(try harness.focusRepository.fetchAll().count, 0)
    }

    private func makeHarness(
        snapshotStore: RuntimeSnapshotStore? = nil,
        soundEffectPlayer: SoundEffectPlaying? = nil,
        now: @escaping () -> Date = Date.init
    ) throws -> (
        viewModel: CurrentSessionViewModel,
        focusRepository: FocusSessionRepository,
        tasksRepository: TasksRepository
    ) {
        let container = try FocusSessionModelContainer.makeInMemory()
        let modelContext = ModelContext(container)
        let focusRepository = FocusSessionRepository(modelContext: modelContext)
        let tasksRepository = TasksRepository(modelContext: modelContext)
        let viewModel = CurrentSessionViewModel(
            snapshotStore: snapshotStore,
            focusSessionRepository: focusRepository,
            tasksRepository: tasksRepository,
            soundEffectPlayer: soundEffectPlayer,
            now: now
        )
        return (viewModel, focusRepository, tasksRepository)
    }

    private func saveTask(
        title: String,
        estimatedMinutes: Int,
        visibleFrom: Date? = nil,
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        in tasksRepository: TasksRepository
    ) throws -> FocusTask {
        let task = FocusTask(
            title: title,
            estimatedMinutes: estimatedMinutes,
            isCompleted: isCompleted,
            completedAt: completedAt,
            visibleFrom: visibleFrom
        )
        try tasksRepository.save(task)
        return task
    }

    private func makeTemporaryContainerURL() -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}

private final class RecordingCurrentSessionSoundEffectPlayer: SoundEffectPlaying {
    private(set) var requests: [SoundPlaybackRequest] = []

    func play(_ request: SoundPlaybackRequest) {
        requests.append(request)
    }
}
