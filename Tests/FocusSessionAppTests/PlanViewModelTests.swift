import SwiftData
import XCTest
@testable import FocusSession

@MainActor
final class PlanViewModelTests: XCTestCase {
    func testCreateGoalPersistsAndAppendsToManualOrder() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = PlanGoalsRepository(modelContext: ModelContext(container))
        let viewModel = PlanViewModel(
            repository: repository,
            tasksRepository: TasksRepository(modelContext: ModelContext(container)),
            now: { Date(timeIntervalSince1970: 50_000) }
        )

        viewModel.presentCreateSheet()
        viewModel.newGoalTitle = "Long paper writing"
        viewModel.newGoalNotes = "第一版"
        viewModel.newGoalStatus = .notStarted
        viewModel.newGoalStartAt = Date(timeIntervalSince1970: 90_000)
        viewModel.newGoalEndAt = Date(timeIntervalSince1970: 100_000)
        XCTAssertTrue(viewModel.saveGoal())

        viewModel.presentCreateSheet()
        viewModel.newGoalTitle = "Study MPC"
        viewModel.newGoalNotes = "先推导再整理"
        viewModel.newGoalStatus = .inProgress
        viewModel.newGoalStartAt = Date(timeIntervalSince1970: 70_000)
        viewModel.newGoalEndAt = Date(timeIntervalSince1970: 80_000)
        XCTAssertTrue(viewModel.saveGoal())

        XCTAssertEqual(viewModel.goals.map(\.title), ["Long paper writing", "Study MPC"])
        XCTAssertEqual(viewModel.goals.map(\.displayOrder), [0, 1])
        XCTAssertEqual(viewModel.activeGoals.first?.status, .notStarted)
    }

    func testEditGoalCanReallocateSubtaskGoalShares() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = PlanGoalsRepository(modelContext: ModelContext(container))
        let tasksRepository = TasksRepository(modelContext: ModelContext(container))
        let outline = PlanGoalSubtask(
            id: UUID(),
            title: "Outline",
            baselineValue: 0,
            targetValue: 100,
            trackingMode: .estimated,
            goalSharePercent: 25
        )
        let draft = PlanGoalSubtask(
            id: UUID(),
            title: "Draft",
            baselineValue: 0,
            targetValue: 100,
            trackingMode: .estimated,
            goalSharePercent: 75
        )
        let goal = PlanGoal(
            title: "Ship thesis",
            status: .inProgress,
            startAt: Date(timeIntervalSince1970: 60_000),
            endAt: Date(timeIntervalSince1970: 70_000),
            subtasks: [outline, draft]
        )
        try repository.save(goal)
        let viewModel = PlanViewModel(
            repository: repository,
            tasksRepository: tasksRepository,
            now: { Date(timeIntervalSince1970: 50_000) }
        )

        viewModel.presentEditSheet(for: goal)

        XCTAssertEqual(viewModel.goalComposerSubtaskShareRows.map(\.title), ["Outline", "Draft"])
        XCTAssertEqual(viewModel.goalComposerAllocatedGoalSharePercent, 100)
        XCTAssertEqual(viewModel.goalComposerRemainingGoalSharePercent, 0)

        viewModel.setGoalComposerSubtaskShareText("40", for: outline.id)
        viewModel.setGoalComposerSubtaskShareText("60", for: draft.id)

        XCTAssertEqual(viewModel.goalComposerAllocatedGoalSharePercent, 100)
        XCTAssertTrue(viewModel.saveGoal())
        XCTAssertEqual(viewModel.goals.first?.subtasks.map(\.goalSharePercent), [40, 60])
    }

    func testCreateSubtaskPersistsQuantifiedMetrics() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = PlanGoalsRepository(modelContext: ModelContext(container))
        let tasksRepository = TasksRepository(modelContext: ModelContext(container))
        let existingGoal = PlanGoal(
            title: "Ship thesis",
            status: .inProgress,
            startAt: Date(timeIntervalSince1970: 60_000),
            endAt: Date(timeIntervalSince1970: 70_000)
        )
        try repository.save(existingGoal)
        let viewModel = PlanViewModel(
            repository: repository,
            tasksRepository: tasksRepository,
            now: { Date(timeIntervalSince1970: 50_000) }
        )

        viewModel.presentCreateSubtaskSheet(for: existingGoal)
        viewModel.subtaskDraftTitle = "Draft"
        viewModel.subtaskDraftBaselineValue = "12"
        viewModel.subtaskDraftTargetValue = "20"
        viewModel.subtaskDraftUnitLabel = "页"
        viewModel.subtaskDraftGoalSharePercent = "100"

        XCTAssertTrue(viewModel.saveSubtask())
        XCTAssertEqual(viewModel.goals.count, 1)
        XCTAssertEqual(viewModel.goals.first?.subtasks.map(\.title), ["Draft"])
        XCTAssertEqual(viewModel.goals.first?.subtasks.map(\.baselineValue), [12])
        XCTAssertEqual(viewModel.goals.first?.subtasks.map(\.targetValue), [20])
        XCTAssertEqual(viewModel.goals.first?.subtasks.map(\.unitLabel), ["页"])
        XCTAssertEqual(viewModel.goals.first?.subtasks.map(\.trackingMode), [.quantified])
        XCTAssertEqual(viewModel.goals.first?.subtasks.map(\.goalSharePercent), [100])
    }

    func testCreateEstimatedSubtaskPersistsTrackingModeAndGoalShare() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = PlanGoalsRepository(modelContext: ModelContext(container))
        let tasksRepository = TasksRepository(modelContext: ModelContext(container))
        let goal = PlanGoal(
            title: "Ship thesis",
            status: .inProgress,
            startAt: Date(timeIntervalSince1970: 60_000),
            endAt: Date(timeIntervalSince1970: 70_000)
        )
        try repository.save(goal)
        let viewModel = PlanViewModel(
            repository: repository,
            tasksRepository: tasksRepository,
            now: { Date(timeIntervalSince1970: 50_000) }
        )

        viewModel.presentCreateSubtaskSheet(for: goal)
        viewModel.subtaskDraftTrackingMode = .estimated
        viewModel.subtaskDraftTitle = "Outline the argument"
        viewModel.subtaskDraftEstimatedProgressPercent = "35"
        viewModel.subtaskDraftGoalSharePercent = "100"

        XCTAssertTrue(viewModel.saveSubtask())
        XCTAssertEqual(viewModel.goals.first?.subtasks.map(\.title), ["Outline the argument"])
        XCTAssertEqual(viewModel.goals.first?.subtasks.map(\.trackingMode), [.estimated])
        XCTAssertEqual(viewModel.goals.first?.subtasks.map(\.goalSharePercent), [100])
        XCTAssertEqual(viewModel.goals.first?.subtasks.map(\.baselineValue), [35])
        XCTAssertEqual(viewModel.goals.first?.subtasks.map(\.targetValue), [100])
    }

    func testSetEstimatedPreviewProgressClampsAndRoundsDraggedValue() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = PlanGoalsRepository(modelContext: ModelContext(container))
        let tasksRepository = TasksRepository(modelContext: ModelContext(container))
        let goal = PlanGoal(
            title: "Ship thesis",
            status: .inProgress,
            startAt: Date(timeIntervalSince1970: 60_000),
            endAt: Date(timeIntervalSince1970: 70_000)
        )
        try repository.save(goal)
        let viewModel = PlanViewModel(
            repository: repository,
            tasksRepository: tasksRepository,
            now: { Date(timeIntervalSince1970: 50_000) }
        )

        viewModel.presentCreateSubtaskSheet(for: goal)
        viewModel.subtaskDraftTrackingMode = .estimated

        viewModel.setSubtaskDraftEstimatedPreviewProgress(35.6)
        XCTAssertEqual(viewModel.subtaskDraftEstimatedProgressPercent, "36")

        viewModel.setSubtaskDraftEstimatedPreviewProgress(-2)
        XCTAssertEqual(viewModel.subtaskDraftEstimatedProgressPercent, "0")

        viewModel.setSubtaskDraftEstimatedPreviewProgress(140)
        XCTAssertEqual(viewModel.subtaskDraftEstimatedProgressPercent, "100")
    }

    func testGoalProgressDerivesFromBaselineAndCompletedLinkedTasks() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = PlanGoalsRepository(modelContext: ModelContext(container))
        let tasksRepository = TasksRepository(modelContext: ModelContext(container))
        let draftSubtask = PlanGoalSubtask(
            id: UUID(),
            title: "Draft",
            baselineValue: 20,
            targetValue: 100,
            unitLabel: "%",
            trackingMode: .quantified,
            goalSharePercent: 25
        )
        let experimentSubtask = PlanGoalSubtask(
            id: UUID(),
            title: "Experiments",
            baselineValue: 1,
            targetValue: 5,
            unitLabel: "次",
            trackingMode: .quantified,
            goalSharePercent: 75
        )
        let goal = PlanGoal(
            title: "Research sprint",
            status: .inProgress,
            startAt: Date(timeIntervalSince1970: 100_000),
            endAt: Date(timeIntervalSince1970: 200_000),
            createdAt: Date(timeIntervalSince1970: 90_000),
            subtasks: [draftSubtask, experimentSubtask]
        )
        try repository.save(goal)
        try tasksRepository.save(
            FocusTask(
                title: "Write draft section",
                estimatedMinutes: 30,
                priority: .high,
                isCompleted: true,
                createdAt: Date(timeIntervalSince1970: 91_000),
                completedAt: Date(timeIntervalSince1970: 92_000),
                linkedSubtaskID: draftSubtask.id,
                contributionValue: 30
            )
        )
        try tasksRepository.save(
            FocusTask(
                title: "Draft but not finished",
                estimatedMinutes: 30,
                priority: .medium,
                linkedSubtaskID: draftSubtask.id,
                contributionValue: 10
            )
        )
        try tasksRepository.save(
            FocusTask(
                title: "Run experiment",
                estimatedMinutes: 45,
                priority: .medium,
                isCompleted: true,
                createdAt: Date(timeIntervalSince1970: 93_000),
                completedAt: Date(timeIntervalSince1970: 94_000),
                linkedSubtaskID: experimentSubtask.id,
                contributionValue: 2
            )
        )

        let viewModel = PlanViewModel(
            repository: repository,
            tasksRepository: tasksRepository,
            now: { Date(timeIntervalSince1970: 50_000) }
        )

        let storedGoal = try XCTUnwrap(viewModel.goals.first)
        XCTAssertEqual(viewModel.currentValue(for: draftSubtask), 50)
        XCTAssertEqual(viewModel.progressPercent(for: draftSubtask), 50)
        XCTAssertEqual(viewModel.linkedTaskCount(for: draftSubtask), 1)
        XCTAssertEqual(viewModel.currentValue(for: experimentSubtask), 3)
        XCTAssertEqual(viewModel.progressPercent(for: experimentSubtask), 60)
        XCTAssertEqual(viewModel.progressPercent(for: storedGoal), 58)
        XCTAssertEqual(viewModel.completedSubtaskCount(for: storedGoal), 0)
    }

    func testIncrementSubtaskValueAddsOneToQuantifiedBaselineAndPersists() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = PlanGoalsRepository(modelContext: ModelContext(container))
        let tasksRepository = TasksRepository(modelContext: ModelContext(container))
        let subtask = PlanGoalSubtask(
            id: UUID(),
            title: "Draft pages",
            baselineValue: 2,
            targetValue: 10,
            unitLabel: "页",
            trackingMode: .quantified,
            goalSharePercent: 100
        )
        let goal = PlanGoal(
            title: "Write thesis",
            status: .inProgress,
            startAt: Date(timeIntervalSince1970: 100_000),
            endAt: Date(timeIntervalSince1970: 200_000),
            subtasks: [subtask]
        )
        try repository.save(goal)

        let viewModel = PlanViewModel(
            repository: repository,
            tasksRepository: tasksRepository,
            now: { Date(timeIntervalSince1970: 50_000) }
        )

        let storedGoal = try XCTUnwrap(viewModel.goals.first)
        let storedSubtask = try XCTUnwrap(storedGoal.subtasks.first)
        XCTAssertEqual(viewModel.currentValue(for: storedSubtask), 2)

        viewModel.incrementSubtaskValue(for: storedGoal, subtask: storedSubtask)

        let updatedGoal = try XCTUnwrap(viewModel.goals.first)
        let updatedSubtask = try XCTUnwrap(updatedGoal.subtasks.first)
        XCTAssertEqual(updatedSubtask.baselineValue, 3)
        XCTAssertEqual(viewModel.currentValue(for: updatedSubtask), 3)
    }

    func testSaveSubtaskAllowsUnallocatedGoalShareForFutureSubtasks() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = PlanGoalsRepository(modelContext: ModelContext(container))
        let tasksRepository = TasksRepository(modelContext: ModelContext(container))
        let goal = PlanGoal(
            title: "Research sprint",
            status: .inProgress,
            startAt: Date(timeIntervalSince1970: 100_000),
            endAt: Date(timeIntervalSince1970: 200_000),
            createdAt: Date(timeIntervalSince1970: 90_000)
        )
        try repository.save(goal)

        let viewModel = PlanViewModel(
            repository: repository,
            tasksRepository: tasksRepository,
            now: { Date(timeIntervalSince1970: 50_000) }
        )

        viewModel.presentCreateSubtaskSheet(for: goal)
        viewModel.subtaskDraftTrackingMode = .estimated
        viewModel.subtaskDraftTitle = "Polish intro"
        viewModel.subtaskDraftEstimatedProgressPercent = "0"
        viewModel.subtaskDraftGoalSharePercent = "30"

        XCTAssertTrue(viewModel.saveSubtask())
        XCTAssertEqual(viewModel.goals.first?.subtasks.map(\.goalSharePercent), [30])
    }

    func testMoveActiveGoalsUpdatesSavedOrderAndTimelineOrder() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = PlanGoalsRepository(modelContext: ModelContext(container))
        let tasksRepository = TasksRepository(modelContext: ModelContext(container))
        let goalOne = PlanGoal(
            title: "Goal one",
            status: .inProgress,
            startAt: Date(timeIntervalSince1970: 10_000),
            endAt: Date(timeIntervalSince1970: 20_000),
            displayOrder: 0
        )
        let goalTwo = PlanGoal(
            title: "Goal two",
            status: .notStarted,
            startAt: Date(timeIntervalSince1970: 11_000),
            endAt: Date(timeIntervalSince1970: 21_000),
            displayOrder: 1
        )
        let goalThree = PlanGoal(
            title: "Goal three",
            status: .inProgress,
            startAt: Date(timeIntervalSince1970: 12_000),
            endAt: Date(timeIntervalSince1970: 22_000),
            displayOrder: 2
        )
        try repository.save(goalOne)
        try repository.save(goalTwo)
        try repository.save(goalThree)

        let viewModel = PlanViewModel(
            repository: repository,
            tasksRepository: tasksRepository,
            now: { Date(timeIntervalSince1970: 50_000) }
        )

        viewModel.moveActiveGoal(goalThree.id, to: goalOne.id)

        XCTAssertEqual(viewModel.activeGoals.map(\.title), ["Goal three", "Goal one", "Goal two"])
        XCTAssertEqual(viewModel.timelineGoals.map(\.title), ["Goal three", "Goal one", "Goal two"])
        let reloadedGoals = try repository.fetchAll()
        XCTAssertEqual(reloadedGoals.map(\.title), ["Goal three", "Goal one", "Goal two"])
        XCTAssertEqual(reloadedGoals.map(\.displayOrder), [0, 1, 2])
    }

    func testMoveSubtaskUpdatesSavedOrderWithinGoal() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = PlanGoalsRepository(modelContext: ModelContext(container))
        let tasksRepository = TasksRepository(modelContext: ModelContext(container))
        let outline = PlanGoalSubtask(
            id: UUID(),
            title: "Outline",
            baselineValue: 0,
            targetValue: 100,
            trackingMode: .estimated,
            goalSharePercent: 30
        )
        let draft = PlanGoalSubtask(
            id: UUID(),
            title: "Draft",
            baselineValue: 0,
            targetValue: 100,
            trackingMode: .estimated,
            goalSharePercent: 30
        )
        let polish = PlanGoalSubtask(
            id: UUID(),
            title: "Polish",
            baselineValue: 0,
            targetValue: 100,
            trackingMode: .estimated,
            goalSharePercent: 40
        )
        let goal = PlanGoal(
            title: "Ship article",
            status: .inProgress,
            startAt: Date(timeIntervalSince1970: 10_000),
            endAt: Date(timeIntervalSince1970: 20_000),
            subtasks: [outline, draft, polish]
        )
        try repository.save(goal)

        let viewModel = PlanViewModel(
            repository: repository,
            tasksRepository: tasksRepository,
            now: { Date(timeIntervalSince1970: 50_000) }
        )

        viewModel.moveSubtask(polish.id, in: goal.id, to: outline.id)

        XCTAssertEqual(
            viewModel.goals.first?.subtasks.map(\.title),
            ["Polish", "Outline", "Draft"]
        )
        XCTAssertEqual(
            try repository.fetchAll().first?.subtasks.map(\.title),
            ["Polish", "Outline", "Draft"]
        )
    }

    func testMoveSubtaskLeftSwapsWithPreviousNeighbor() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = PlanGoalsRepository(modelContext: ModelContext(container))
        let tasksRepository = TasksRepository(modelContext: ModelContext(container))
        let outline = PlanGoalSubtask(id: UUID(), title: "Outline", trackingMode: .estimated, goalSharePercent: 30)
        let draft = PlanGoalSubtask(id: UUID(), title: "Draft", trackingMode: .estimated, goalSharePercent: 30)
        let polish = PlanGoalSubtask(id: UUID(), title: "Polish", trackingMode: .estimated, goalSharePercent: 40)
        let goal = PlanGoal(
            title: "Ship article",
            status: .inProgress,
            startAt: Date(timeIntervalSince1970: 10_000),
            endAt: Date(timeIntervalSince1970: 20_000),
            subtasks: [outline, draft, polish]
        )
        try repository.save(goal)

        let viewModel = PlanViewModel(
            repository: repository,
            tasksRepository: tasksRepository,
            now: { Date(timeIntervalSince1970: 50_000) }
        )

        viewModel.moveSubtaskLeft(draft.id, in: goal.id)

        XCTAssertEqual(
            viewModel.goals.first?.subtasks.map(\.title),
            ["Draft", "Outline", "Polish"]
        )
        XCTAssertEqual(
            try repository.fetchAll().first?.subtasks.map(\.title),
            ["Draft", "Outline", "Polish"]
        )
    }

    func testMoveSubtaskRightSwapsWithNextNeighbor() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = PlanGoalsRepository(modelContext: ModelContext(container))
        let tasksRepository = TasksRepository(modelContext: ModelContext(container))
        let outline = PlanGoalSubtask(id: UUID(), title: "Outline", trackingMode: .estimated, goalSharePercent: 30)
        let draft = PlanGoalSubtask(id: UUID(), title: "Draft", trackingMode: .estimated, goalSharePercent: 30)
        let polish = PlanGoalSubtask(id: UUID(), title: "Polish", trackingMode: .estimated, goalSharePercent: 40)
        let goal = PlanGoal(
            title: "Ship article",
            status: .inProgress,
            startAt: Date(timeIntervalSince1970: 10_000),
            endAt: Date(timeIntervalSince1970: 20_000),
            subtasks: [outline, draft, polish]
        )
        try repository.save(goal)

        let viewModel = PlanViewModel(
            repository: repository,
            tasksRepository: tasksRepository,
            now: { Date(timeIntervalSince1970: 50_000) }
        )

        viewModel.moveSubtaskRight(draft.id, in: goal.id)

        XCTAssertEqual(
            viewModel.goals.first?.subtasks.map(\.title),
            ["Outline", "Polish", "Draft"]
        )
        XCTAssertEqual(
            try repository.fetchAll().first?.subtasks.map(\.title),
            ["Outline", "Polish", "Draft"]
        )
    }

    func testCompletedAndUnfinishedGoalsAppearInNoMansLandWhileTimelineStillShowsThem() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = PlanGoalsRepository(modelContext: ModelContext(container))
        let tasksRepository = TasksRepository(modelContext: ModelContext(container))
        let activeGoal = PlanGoal(
            title: "Active goal",
            status: .inProgress,
            startAt: Date(timeIntervalSince1970: 10_000),
            endAt: Date(timeIntervalSince1970: 20_000),
            displayOrder: 0
        )
        let completedGoal = PlanGoal(
            title: "Completed goal",
            status: .completed,
            startAt: Date(timeIntervalSince1970: 11_000),
            endAt: Date(timeIntervalSince1970: 21_000),
            displayOrder: 1
        )
        let unfinishedGoal = PlanGoal(
            title: "Unfinished goal",
            status: .unfinished,
            startAt: Date(timeIntervalSince1970: 12_000),
            endAt: Date(timeIntervalSince1970: 22_000),
            displayOrder: 2
        )
        try repository.save(activeGoal)
        try repository.save(completedGoal)
        try repository.save(unfinishedGoal)

        let viewModel = PlanViewModel(
            repository: repository,
            tasksRepository: tasksRepository,
            now: { Date(timeIntervalSince1970: 50_000) }
        )

        XCTAssertEqual(viewModel.activeGoals.map(\.title), ["Active goal"])
        XCTAssertEqual(viewModel.noMansLandGoals.map(\.title), ["Completed goal", "Unfinished goal"])
        XCTAssertEqual(
            viewModel.timelineGoals.map(\.title),
            ["Active goal", "Completed goal", "Unfinished goal"]
        )
    }

    func testSaveSubtaskRejectsGoalShareTotalsThatExceedOneHundredPercent() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = PlanGoalsRepository(modelContext: ModelContext(container))
        let tasksRepository = TasksRepository(modelContext: ModelContext(container))
        let existingSubtask = PlanGoalSubtask(
            id: UUID(),
            title: "Draft",
            baselineValue: 20,
            targetValue: 100,
            unitLabel: "%",
            trackingMode: .estimated,
            goalSharePercent: 90
        )
        let goal = PlanGoal(
            title: "Research sprint",
            status: .inProgress,
            startAt: Date(timeIntervalSince1970: 100_000),
            endAt: Date(timeIntervalSince1970: 200_000),
            createdAt: Date(timeIntervalSince1970: 90_000),
            subtasks: [existingSubtask]
        )
        try repository.save(goal)

        let viewModel = PlanViewModel(
            repository: repository,
            tasksRepository: tasksRepository,
            now: { Date(timeIntervalSince1970: 50_000) }
        )

        viewModel.presentCreateSubtaskSheet(for: goal)
        viewModel.subtaskDraftTrackingMode = .estimated
        viewModel.subtaskDraftTitle = "Polish intro"
        viewModel.subtaskDraftEstimatedProgressPercent = "0"
        viewModel.subtaskDraftGoalSharePercent = "20"

        XCTAssertFalse(viewModel.saveSubtask())
        XCTAssertEqual(viewModel.errorMessage, "Allocated subtask shares can't exceed 100%.")
    }

    func testEstimatedSubtaskCanConvertToQuantifiedUsingSameProgressPercent() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = PlanGoalsRepository(modelContext: ModelContext(container))
        let tasksRepository = TasksRepository(modelContext: ModelContext(container))
        let subtask = PlanGoalSubtask(
            id: UUID(),
            title: "Outline the paper",
            baselineValue: 40,
            targetValue: 100,
            unitLabel: "%",
            trackingMode: .estimated,
            goalSharePercent: 100
        )
        let goal = PlanGoal(
            title: "Write thesis",
            status: .inProgress,
            startAt: Date(timeIntervalSince1970: 100_000),
            endAt: Date(timeIntervalSince1970: 200_000),
            subtasks: [subtask]
        )
        try repository.save(goal)

        let viewModel = PlanViewModel(
            repository: repository,
            tasksRepository: tasksRepository,
            now: { Date(timeIntervalSince1970: 50_000) }
        )

        viewModel.presentEditSubtaskSheet(for: goal, subtask: subtask)
        viewModel.setSubtaskDraftTrackingMode(.quantified)
        viewModel.setSubtaskDraftTargetValue("20")
        viewModel.subtaskDraftUnitLabel = "页"

        XCTAssertEqual(viewModel.subtaskDraftBaselineValue, "8")
        XCTAssertTrue(viewModel.saveSubtask())
        XCTAssertEqual(viewModel.goals.first?.subtasks.map(\.trackingMode), [.quantified])
        XCTAssertEqual(viewModel.goals.first?.subtasks.map(\.baselineValue), [8])
        XCTAssertEqual(viewModel.goals.first?.subtasks.map(\.targetValue), [20])
        XCTAssertEqual(viewModel.progressPercent(for: try XCTUnwrap(viewModel.goals.first).subtasks[0]), 40)
    }

    func testGoalProgressTreatsUnallocatedShareAsIncompleteRemainder() throws {
        let subtask = PlanGoalSubtask(
            title: "Only known milestone",
            baselineValue: 50,
            targetValue: 100,
            unitLabel: "%",
            trackingMode: .estimated,
            goalSharePercent: 30
        )
        let goal = PlanGoal(
            title: "Write thesis",
            status: .inProgress,
            startAt: Date(timeIntervalSince1970: 100_000),
            endAt: Date(timeIntervalSince1970: 200_000),
            subtasks: [subtask]
        )
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = PlanGoalsRepository(modelContext: ModelContext(container))
        let tasksRepository = TasksRepository(modelContext: ModelContext(container))
        try repository.save(goal)

        let viewModel = PlanViewModel(
            repository: repository,
            tasksRepository: tasksRepository,
            now: { Date(timeIntervalSince1970: 50_000) }
        )

        XCTAssertEqual(viewModel.progressPercent(for: try XCTUnwrap(viewModel.goals.first)), 15)
    }

    func testTimelineGoalsIncludeCompletedAndUnfinishedGoalsInsideVisibleWindow() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = PlanGoalsRepository(modelContext: ModelContext(container))
        let tasksRepository = TasksRepository(modelContext: ModelContext(container))
        let completedGoal = PlanGoal(
            title: "Archived thesis milestone",
            status: .completed,
            startAt: Date(timeIntervalSince1970: 100_000),
            endAt: Date(timeIntervalSince1970: 120_000),
            createdAt: Date(timeIntervalSince1970: 90_000)
        )
        let activeGoal = PlanGoal(
            title: "Active thesis milestone",
            status: .inProgress,
            startAt: Date(timeIntervalSince1970: 110_000),
            endAt: Date(timeIntervalSince1970: 130_000),
            createdAt: Date(timeIntervalSince1970: 91_000)
        )
        let unfinishedGoal = PlanGoal(
            title: "Missed thesis milestone",
            status: .unfinished,
            startAt: Date(timeIntervalSince1970: 112_000),
            endAt: Date(timeIntervalSince1970: 132_000),
            createdAt: Date(timeIntervalSince1970: 92_000)
        )
        try repository.save(completedGoal)
        try repository.save(activeGoal)
        try repository.save(unfinishedGoal)

        let viewModel = PlanViewModel(
            repository: repository,
            tasksRepository: tasksRepository,
            now: { Date(timeIntervalSince1970: 115_000) }
        )

        XCTAssertEqual(
            viewModel.timelineGoals.map(\.title),
            ["Archived thesis milestone", "Active thesis milestone", "Missed thesis milestone"]
        )
    }

    func testInvalidGoalRangeKeepsComposerOpenAndShowsError() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = PlanGoalsRepository(modelContext: ModelContext(container))
        let viewModel = PlanViewModel(
            repository: repository,
            tasksRepository: TasksRepository(modelContext: ModelContext(container))
        )

        viewModel.presentCreateSheet()
        viewModel.newGoalTitle = "Invalid goal"
        viewModel.newGoalStartAt = Date(timeIntervalSince1970: 10_000)
        viewModel.newGoalEndAt = Date(timeIntervalSince1970: 9_000)

        XCTAssertFalse(viewModel.saveGoal())
        XCTAssertTrue(viewModel.isPresentingGoalSheet)
        XCTAssertEqual(viewModel.errorMessage, "End time must be later than start time.")
    }

    func testTimelineScaleWindowsRespectReferenceDate() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.firstWeekday = 2

        let referenceDate = date(
            year: 2026,
            month: 3,
            day: 10,
            hour: 8,
            minute: 0,
            calendar: calendar
        )

        let dayWindow = PlanTimelineScale.day.window(containing: referenceDate, calendar: calendar)
        let weekWindow = PlanTimelineScale.week.window(containing: referenceDate, calendar: calendar)
        let monthWindow = PlanTimelineScale.month.window(containing: referenceDate, calendar: calendar)

        XCTAssertEqual(dayWindow.start, date(year: 2026, month: 3, day: 10, hour: 0, minute: 0, calendar: calendar))
        XCTAssertEqual(dayWindow.end, date(year: 2026, month: 3, day: 11, hour: 0, minute: 0, calendar: calendar))
        XCTAssertEqual(weekWindow.start, date(year: 2026, month: 3, day: 9, hour: 0, minute: 0, calendar: calendar))
        XCTAssertEqual(weekWindow.end, date(year: 2026, month: 3, day: 16, hour: 0, minute: 0, calendar: calendar))
        XCTAssertEqual(monthWindow.start, date(year: 2026, month: 1, day: 1, hour: 0, minute: 0, calendar: calendar))
        XCTAssertEqual(monthWindow.end, date(year: 2027, month: 1, day: 1, hour: 0, minute: 0, calendar: calendar))
    }

    func testMonthScaleShiftsByYearInsteadOfSingleMonth() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let referenceDate = date(
            year: 2026,
            month: 3,
            day: 10,
            hour: 8,
            minute: 0,
            calendar: calendar
        )

        let shifted = PlanTimelineScale.month.shiftedReferenceDate(
            from: referenceDate,
            direction: 1,
            calendar: calendar
        )

        XCTAssertEqual(
            shifted,
            date(year: 2027, month: 3, day: 10, hour: 8, minute: 0, calendar: calendar)
        )
    }

    func testTodayMarkerLabelShowsMonthAndDay() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let referenceDate = date(
            year: 2026,
            month: 3,
            day: 10,
            hour: 8,
            minute: 0,
            calendar: calendar
        )

        XCTAssertEqual(
            PlanViewModel.todayMarkerTitle(referenceDate: referenceDate, calendar: calendar),
            "今日 3月10日"
        )
    }

    func testZoomInPreservesAnnualVisibleWindowWhileIncreasingDetailLevel() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let currentDate = date(
            year: 2026,
            month: 3,
            day: 10,
            hour: 8,
            minute: 0,
            calendar: calendar
        )
        let repository = PlanGoalsRepository(modelContext: ModelContext(try FocusSessionModelContainer.makeInMemory()))
        let tasksRepository = TasksRepository(modelContext: ModelContext(try FocusSessionModelContainer.makeInMemory()))
        let viewModel = PlanViewModel(
            repository: repository,
            tasksRepository: tasksRepository,
            now: { currentDate },
            calendar: calendar
        )

        let initialWindow = viewModel.visibleWindow
        let anchorDate = date(
            year: 2026,
            month: 5,
            day: 20,
            hour: 12,
            minute: 0,
            calendar: calendar
        )

        viewModel.adjustTimelineZoom(deltaY: 1, anchorDate: anchorDate)

        XCTAssertEqual(viewModel.visibleWindow, initialWindow)
        XCTAssertEqual(viewModel.visibleMonthSpanForPresentation, 6)
    }

    func testShiftTimelineMovesWholeYearEvenWhenDetailZoomIsActive() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let currentDate = date(
            year: 2026,
            month: 3,
            day: 10,
            hour: 8,
            minute: 0,
            calendar: calendar
        )
        let repository = PlanGoalsRepository(modelContext: ModelContext(try FocusSessionModelContainer.makeInMemory()))
        let tasksRepository = TasksRepository(modelContext: ModelContext(try FocusSessionModelContainer.makeInMemory()))
        let viewModel = PlanViewModel(
            repository: repository,
            tasksRepository: tasksRepository,
            now: { currentDate },
            calendar: calendar
        )

        let anchorDate = date(year: 2026, month: 5, day: 20, hour: 12, minute: 0, calendar: calendar)
        viewModel.adjustTimelineZoom(deltaY: 1, anchorDate: anchorDate)

        viewModel.shiftTimeline(by: 1)

        XCTAssertEqual(
            viewModel.visibleWindow.start,
            date(year: 2027, month: 1, day: 1, hour: 0, minute: 0, calendar: calendar)
        )
        XCTAssertEqual(
            viewModel.visibleWindow.end,
            date(year: 2028, month: 1, day: 1, hour: 0, minute: 0, calendar: calendar)
        )
        XCTAssertEqual(viewModel.visibleMonthSpanForPresentation, 6)
    }

    func testJumpToTodayKeepsAnnualWindowWhenDetailZoomIsActive() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let currentDate = date(
            year: 2026,
            month: 3,
            day: 10,
            hour: 8,
            minute: 0,
            calendar: calendar
        )
        let repository = PlanGoalsRepository(modelContext: ModelContext(try FocusSessionModelContainer.makeInMemory()))
        let tasksRepository = TasksRepository(modelContext: ModelContext(try FocusSessionModelContainer.makeInMemory()))
        let viewModel = PlanViewModel(
            repository: repository,
            tasksRepository: tasksRepository,
            now: { currentDate },
            calendar: calendar
        )

        let anchorDate = date(year: 2026, month: 5, day: 20, hour: 12, minute: 0, calendar: calendar)
        viewModel.adjustTimelineZoom(deltaY: 1, anchorDate: anchorDate)
        viewModel.shiftTimeline(by: 1)

        viewModel.jumpToToday()

        XCTAssertEqual(
            viewModel.visibleWindow.start,
            date(year: 2026, month: 1, day: 1, hour: 0, minute: 0, calendar: calendar)
        )
        XCTAssertEqual(
            viewModel.visibleWindow.end,
            date(year: 2027, month: 1, day: 1, hour: 0, minute: 0, calendar: calendar)
        )
        XCTAssertEqual(viewModel.visibleMonthSpanForPresentation, 6)
    }

    func testVisibleMonthSpanForPresentationTracksDetailZoomLevel() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let currentDate = date(year: 2026, month: 3, day: 12, hour: 12, minute: 0, calendar: calendar)
        let repository = PlanGoalsRepository(modelContext: ModelContext(try FocusSessionModelContainer.makeInMemory()))
        let tasksRepository = TasksRepository(modelContext: ModelContext(try FocusSessionModelContainer.makeInMemory()))
        let viewModel = PlanViewModel(
            repository: repository,
            tasksRepository: tasksRepository,
            now: { currentDate },
            calendar: calendar
        )

        XCTAssertEqual(viewModel.visibleMonthSpanForPresentation, 12)

        let anchorDate = date(year: 2026, month: 5, day: 20, hour: 12, minute: 0, calendar: calendar)
        viewModel.adjustTimelineZoom(deltaY: 1, anchorDate: anchorDate)

        XCTAssertEqual(viewModel.visibleMonthSpanForPresentation, 6)
    }

    func testFocusGoalStoresFocusedGoalIdentifier() throws {
        let goal = PlanGoal(
            title: "Focus RL",
            status: .inProgress,
            startAt: Date(timeIntervalSince1970: 100_000),
            endAt: Date(timeIntervalSince1970: 200_000)
        )
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = PlanGoalsRepository(modelContext: ModelContext(container))
        let tasksRepository = TasksRepository(modelContext: ModelContext(container))
        let viewModel = PlanViewModel(repository: repository, tasksRepository: tasksRepository)

        viewModel.focusGoal(goal)

        XCTAssertEqual(viewModel.focusedGoalID, goal.id)
    }

    func testLinkExistingTaskMovesContributionBetweenSubtasks() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = PlanGoalsRepository(modelContext: ModelContext(container))
        let tasksRepository = TasksRepository(modelContext: ModelContext(container))
        let reportSubtask = PlanGoalSubtask(
            id: UUID(),
            title: "Report",
            baselineValue: 0,
            targetValue: 10,
            unitLabel: "页",
            trackingMode: .quantified,
            goalSharePercent: 50
        )
        let paperSubtask = PlanGoalSubtask(
            id: UUID(),
            title: "Paper",
            baselineValue: 0,
            targetValue: 10,
            unitLabel: "页",
            trackingMode: .quantified,
            goalSharePercent: 50
        )
        let goal = PlanGoal(
            title: "Write outputs",
            status: .inProgress,
            startAt: Date(timeIntervalSince1970: 10_000),
            endAt: Date(timeIntervalSince1970: 20_000),
            subtasks: [reportSubtask, paperSubtask]
        )
        let task = FocusTask(
            title: "Finish introduction",
            estimatedMinutes: 30,
            priority: .high,
            isCompleted: true,
            createdAt: Date(timeIntervalSince1970: 11_000),
            completedAt: Date(timeIntervalSince1970: 12_000),
            linkedSubtaskID: reportSubtask.id,
            contributionValue: 4
        )
        try repository.save(goal)
        try tasksRepository.save(task)

        let viewModel = PlanViewModel(
            repository: repository,
            tasksRepository: tasksRepository,
            now: { Date(timeIntervalSince1970: 50_000) }
        )

        XCTAssertTrue(viewModel.linkExistingTask(task, to: paperSubtask, contributionValue: 6))
        XCTAssertEqual(viewModel.progressPercent(for: reportSubtask), 0)
        XCTAssertEqual(viewModel.progressPercent(for: paperSubtask), 60)
    }

    func testLinkableTasksIncludeVisibleTodayTasksAndHiddenRecurringTasks() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = PlanGoalsRepository(modelContext: ModelContext(container))
        let tasksRepository = TasksRepository(modelContext: ModelContext(container))
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Shanghai") ?? .current
        let now = date(year: 2026, month: 3, day: 12, hour: 9, minute: 0, calendar: calendar)

        try tasksRepository.save(
            FocusTask(
                title: "Visible today task",
                estimatedMinutes: 25,
                priority: .high,
                createdAt: now.addingTimeInterval(-300)
            )
        )
        try tasksRepository.save(
            FocusTask(
                title: "Completed task",
                estimatedMinutes: 25,
                priority: .medium,
                isCompleted: true,
                createdAt: now.addingTimeInterval(-600),
                completedAt: now.addingTimeInterval(-60)
            )
        )
        try tasksRepository.save(
            FocusTask(
                title: "Hidden recurring task",
                estimatedMinutes: 25,
                priority: .low,
                repeatRule: .daily,
                visibleFrom: now.addingTimeInterval(3600),
                recurrenceSeriesID: UUID()
            )
        )

        let viewModel = PlanViewModel(
            repository: repository,
            tasksRepository: tasksRepository,
            now: { now },
            calendar: calendar
        )

        XCTAssertEqual(
            viewModel.linkableTasks.map(\.title),
            ["Visible today task", "Hidden recurring task"]
        )
    }

    func testConfirmSelectedTaskLinkRejectsTaskThatIsNoLongerVisibleInToday() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = PlanGoalsRepository(modelContext: ModelContext(container))
        let tasksRepository = TasksRepository(modelContext: ModelContext(container))
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Shanghai") ?? .current
        let now = date(year: 2026, month: 3, day: 12, hour: 9, minute: 0, calendar: calendar)
        let subtask = PlanGoalSubtask(
            id: UUID(),
            title: "Report",
            baselineValue: 0,
            targetValue: 10,
            unitLabel: "页",
            trackingMode: .quantified,
            goalSharePercent: 100
        )
        let goal = PlanGoal(
            title: "Write outputs",
            status: .inProgress,
            startAt: now.addingTimeInterval(-7_200),
            endAt: now.addingTimeInterval(7_200),
            subtasks: [subtask]
        )
        let task = FocusTask(
            title: "Visible draft task",
            estimatedMinutes: 25,
            priority: .high,
            createdAt: now.addingTimeInterval(-300)
        )
        try repository.save(goal)
        try tasksRepository.save(task)

        let viewModel = PlanViewModel(
            repository: repository,
            tasksRepository: tasksRepository,
            now: { now },
            calendar: calendar
        )

        viewModel.presentEditSubtaskSheet(for: goal, subtask: subtask)
        viewModel.presentLinkExistingTaskSheet()
        viewModel.selectTaskForLink(task)

        var hiddenTask = task
        hiddenTask.isCompleted = true
        hiddenTask.completedAt = now
        try tasksRepository.update(hiddenTask)
        viewModel.load()

        XCTAssertFalse(viewModel.confirmSelectedTaskLink())
        XCTAssertEqual(viewModel.errorMessage, "Selected task is no longer available to link.")
    }

    func testLinkableTasksIncludeVisibleDailyAndWeeklyTasks() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = PlanGoalsRepository(modelContext: ModelContext(container))
        let tasksRepository = TasksRepository(modelContext: ModelContext(container))
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Shanghai") ?? .current
        let now = date(year: 2026, month: 3, day: 12, hour: 9, minute: 0, calendar: calendar)

        try tasksRepository.save(
            FocusTask(
                title: "Daily linked candidate",
                estimatedMinutes: 25,
                priority: .high,
                repeatRule: .daily,
                recurrenceSeriesID: UUID()
            )
        )
        try tasksRepository.save(
            FocusTask(
                title: "Weekly linked candidate",
                estimatedMinutes: 25,
                priority: .medium,
                repeatRule: .weekly,
                repeatWeekday: .friday,
                recurrenceSeriesID: UUID()
            )
        )

        let viewModel = PlanViewModel(
            repository: repository,
            tasksRepository: tasksRepository,
            now: { now },
            calendar: calendar
        )

        XCTAssertEqual(
            Set(viewModel.linkableTasks.map(\.title)),
            Set(["Daily linked candidate", "Weekly linked candidate"])
        )
    }

    func testLinkedTaskCountIncludesDailyAndWeeklyRecurringTasks() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = PlanGoalsRepository(modelContext: ModelContext(container))
        let tasksRepository = TasksRepository(modelContext: ModelContext(container))
        let subtask = PlanGoalSubtask(
            id: UUID(),
            title: "Write report",
            baselineValue: 0,
            targetValue: 10,
            unitLabel: "页",
            trackingMode: .quantified,
            goalSharePercent: 100
        )
        let goal = PlanGoal(
            title: "Research sprint",
            status: .inProgress,
            startAt: Date(timeIntervalSince1970: 10_000),
            endAt: Date(timeIntervalSince1970: 20_000),
            subtasks: [subtask]
        )
        try repository.save(goal)
        try tasksRepository.save(
            FocusTask(
                title: "Daily linked task",
                estimatedMinutes: 25,
                priority: .high,
                linkedSubtaskID: subtask.id,
                contributionValue: 1,
                repeatRule: .daily,
                recurrenceSeriesID: UUID()
            )
        )
        try tasksRepository.save(
            FocusTask(
                title: "Weekly linked task",
                estimatedMinutes: 25,
                priority: .medium,
                linkedSubtaskID: subtask.id,
                contributionValue: 1,
                repeatRule: .weekly,
                repeatWeekday: .monday,
                recurrenceSeriesID: UUID()
            )
        )

        let viewModel = PlanViewModel(
            repository: repository,
            tasksRepository: tasksRepository,
            now: { Date(timeIntervalSince1970: 50_000) }
        )

        XCTAssertEqual(viewModel.linkedTaskCount(for: subtask), 2)
    }

    func testRecurringLinkedTaskSeriesCountsAsSingleActiveLinkAndUnlinkKeepsCompletedContributionHistory() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let modelContext = ModelContext(container)
        let repository = PlanGoalsRepository(modelContext: modelContext)
        let tasksRepository = TasksRepository(modelContext: modelContext)
        let subtask = PlanGoalSubtask(
            id: UUID(),
            title: "Listening",
            baselineValue: 0,
            targetValue: 10,
            unitLabel: "次",
            trackingMode: .quantified,
            goalSharePercent: 100
        )
        try repository.save(
            PlanGoal(
                title: "English",
                status: .inProgress,
                startAt: Date(timeIntervalSince1970: 10_000),
                endAt: Date(timeIntervalSince1970: 20_000),
                subtasks: [subtask]
            )
        )

        let seriesID = UUID()
        let completedHistory = FocusTask(
            title: "Listening history",
            estimatedMinutes: 25,
            priority: .high,
            isCompleted: true,
            completedAt: Date(timeIntervalSince1970: 15_000),
            linkedSubtaskID: subtask.id,
            contributionValue: 2,
            repeatRule: .daily,
            recurrenceSeriesID: seriesID
        )
        let activeTask = FocusTask(
            title: "Listening",
            estimatedMinutes: 25,
            priority: .high,
            linkedSubtaskID: subtask.id,
            contributionValue: 1,
            repeatRule: .daily,
            recurrenceSeriesID: seriesID
        )
        let duplicateActiveTask = FocusTask(
            title: "Listening",
            estimatedMinutes: 25,
            priority: .high,
            linkedSubtaskID: subtask.id,
            contributionValue: 1,
            repeatRule: .daily,
            visibleFrom: Date(timeIntervalSince1970: 30_000),
            recurrenceSeriesID: seriesID
        )
        try tasksRepository.save(completedHistory)
        try tasksRepository.save(activeTask)
        try tasksRepository.save(duplicateActiveTask)

        let viewModel = PlanViewModel(
            repository: repository,
            tasksRepository: tasksRepository,
            now: { Date(timeIntervalSince1970: 12_000) }
        )

        XCTAssertEqual(viewModel.linkedTaskCount(for: subtask), 1)
        XCTAssertEqual(viewModel.linkedTasks(for: subtask).map(\.id), [activeTask.id])
        XCTAssertEqual(viewModel.currentValue(for: subtask), 2)

        viewModel.unlinkTask(activeTask)

        XCTAssertEqual(viewModel.linkedTaskCount(for: subtask), 0)
        XCTAssertEqual(viewModel.linkedTasks(for: subtask), [])
        XCTAssertEqual(viewModel.currentValue(for: subtask), 2)
    }

    private func date(
        year: Int,
        month: Int,
        day: Int,
        hour: Int,
        minute: Int,
        calendar: Calendar
    ) -> Date {
        calendar.date(
            from: DateComponents(
                timeZone: calendar.timeZone,
                year: year,
                month: month,
                day: day,
                hour: hour,
                minute: minute
            )
        )!
    }
}
