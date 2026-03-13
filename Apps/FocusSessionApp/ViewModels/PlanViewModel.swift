import CoreGraphics
import Foundation
import SwiftData

enum GoalComposerMode: Equatable {
    case create
    case edit(UUID)
}

private enum SubtaskComposerMode: Equatable {
    case create(goalID: UUID, subtaskID: UUID)
    case edit(goalID: UUID, subtaskID: UUID)

    var goalID: UUID {
        switch self {
        case let .create(goalID, _), let .edit(goalID, _):
            goalID
        }
    }

    var subtaskID: UUID {
        switch self {
        case let .create(_, subtaskID), let .edit(_, subtaskID):
            subtaskID
        }
    }

    var isEditing: Bool {
        if case .edit = self {
            return true
        }
        return false
    }
}

struct SubtaskSiblingShareRow: Equatable, Identifiable {
    let id: UUID
    let title: String
    let shareText: String
}

@MainActor
final class PlanViewModel: ObservableObject {
    @Published private(set) var goals: [PlanGoal] = []
    @Published private(set) var tasks: [FocusTask] = []
    @Published var referenceDate: Date
    @Published private(set) var visibleWindow: DateInterval
    @Published private(set) var focusedGoalID: UUID?
    @Published var isPresentingGoalSheet = false
    @Published var isPresentingSubtaskSheet = false
    @Published var isPresentingTaskLinkSheet = false
    @Published var newGoalTitle = ""
    @Published var newGoalNotes = ""
    @Published var newGoalStatus: PlanGoalStatus = .notStarted
    @Published var newGoalStartAt: Date
    @Published var newGoalEndAt: Date
    @Published var subtaskDraftTitle = ""
    @Published var subtaskDraftBaselineValue = "0"
    @Published var subtaskDraftTargetValue = "100"
    @Published var subtaskDraftUnitLabel = ""
    @Published var subtaskDraftTrackingMode: PlanGoalSubtaskTrackingMode = .quantified
    @Published var subtaskDraftEstimatedProgressPercent = "0"
    @Published var subtaskDraftGoalSharePercent = "100"
    @Published var selectedLinkTaskID: UUID?
    @Published var linkTaskContributionValue = "1"
    @Published private(set) var errorMessage: String?
    @Published private var goalComposerSubtaskShareDrafts: [UUID: String] = [:]
    @Published private var siblingGoalShareDrafts: [UUID: String] = [:]
    @Published private var timelineDetailMonthSpan = 12

    private let repository: PlanGoalsRepository
    private let tasksRepository: TasksRepository
    private let now: () -> Date
    private let calendar: Calendar
    private let zoomMonthSteps = [1, 3, 6, 12]
    private var goalComposerMode: GoalComposerMode = .create
    private var subtaskComposerMode: SubtaskComposerMode?
    private var subtaskDraftUsesEstimatedConversion = false
    private var subtaskDraftBaselineWasEditedManually = false

    init(
        repository: PlanGoalsRepository? = nil,
        tasksRepository: TasksRepository? = nil,
        now: @escaping () -> Date = Date.init,
        calendar: Calendar = .autoupdatingCurrent
    ) {
        let currentDate = now()
        if let repository {
            self.repository = repository
        } else {
            self.repository = PlanGoalsRepository(
                modelContext: ModelContext(FocusSessionModelContainer.shared)
            )
        }
        if let tasksRepository {
            self.tasksRepository = tasksRepository
        } else {
            self.tasksRepository = TasksRepository(
                modelContext: ModelContext(FocusSessionModelContainer.shared)
            )
        }
        self.now = now
        self.calendar = calendar
        referenceDate = currentDate
        visibleWindow = Self.makeMonthWindow(
            around: currentDate,
            monthSpan: 12,
            calendar: calendar
        )
        newGoalStartAt = currentDate
        newGoalEndAt = currentDate.addingTimeInterval(14 * 24 * 60 * 60)
        load()
    }

    var timelineGoals: [PlanGoal] {
        let window = visibleWindow
        return goals.filter { goal in
            goal.endAt > window.start && goal.startAt < window.end
        }
    }

    var visibleMonthSpanForPresentation: Int {
        timelineDetailMonthSpan
    }

    var activeGoals: [PlanGoal] {
        goals.filter { !$0.status.isTerminal }
    }

    var completedGoals: [PlanGoal] {
        goals.filter { $0.status == .completed }
    }

    var noMansLandGoals: [PlanGoal] {
        goals.filter(\.status.isTerminal)
    }

    var isEditingGoal: Bool {
        if case .edit = goalComposerMode {
            return true
        }
        return false
    }

    var isEditingSubtask: Bool {
        subtaskComposerMode?.isEditing ?? false
    }

    var goalComposerSubtaskShareRows: [SubtaskSiblingShareRow] {
        guard let goal = currentGoalForGoalComposer else {
            return []
        }

        return goal.subtasks.map { subtask in
            SubtaskSiblingShareRow(
                id: subtask.id,
                title: subtask.title,
                shareText: goalComposerSubtaskShareDrafts[subtask.id] ?? Self.formatMetricValue(subtask.goalSharePercent)
            )
        }
    }

    var goalComposerAllocatedGoalSharePercent: Double {
        let subtaskShares = goalComposerSubtaskShareRows.compactMap { row in
            Double(row.shareText.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return PlanGoalSubtask.roundedGoalSharePercent(subtaskShares.reduce(0, +))
    }

    var goalComposerRemainingGoalSharePercent: Double {
        max(0, PlanGoalSubtask.roundedGoalSharePercent(100 - goalComposerAllocatedGoalSharePercent))
    }

    var linkedTasksForEditingSubtask: [FocusTask] {
        guard let subtaskComposerMode else {
            return []
        }

        return linkedTasks(forSubtaskID: subtaskComposerMode.subtaskID)
    }

    var linkableTasks: [FocusTask] {
        sortTasksForLinking(tasks.filter(isTaskLinkableForSubtask))
    }

    var currentSubtaskPreviewValue: Double {
        switch subtaskDraftTrackingMode {
        case .estimated:
            return parsedSubtaskEstimatedProgressPercent ?? currentEditingSubtask?.baselineValue ?? 0
        case .quantified:
            let baselineValue = effectiveQuantifiedDraftBaselineValue ?? currentEditingSubtask?.baselineValue ?? 0
            let completedContribution = linkedTasksForEditingSubtask
                .filter(\.isCompleted)
                .reduce(0) { partialResult, task in
                    partialResult + (task.contributionValue ?? 0)
                }
            return baselineValue + completedContribution
        }
    }

    var currentSubtaskPreviewProgressPercent: Int? {
        switch subtaskDraftTrackingMode {
        case .estimated:
            let progress = parsedSubtaskEstimatedProgressPercent ?? currentEditingSubtask?.baselineValue ?? 0
            return min(max(Int(progress.rounded()), 0), 100)
        case .quantified:
            let targetValue = parsedSubtaskTargetValue ?? currentEditingSubtask?.targetValue ?? 0
            guard targetValue > 0 else {
                return nil
            }

            let previewSubtask = PlanGoalSubtask(
                id: subtaskComposerMode?.subtaskID ?? UUID(),
                title: subtaskDraftTitle,
                baselineValue: currentSubtaskPreviewValue,
                targetValue: targetValue,
                unitLabel: subtaskDraftUnitLabel,
                trackingMode: .quantified,
                goalSharePercent: parsedSubtaskGoalSharePercent ?? currentEditingSubtask?.goalSharePercent ?? 100
            )
            return previewSubtask.progressPercent
        }
    }

    var activeSubtaskForComposer: PlanGoalSubtask? {
        currentEditingSubtask
    }

    var subtaskSiblingShareRows: [SubtaskSiblingShareRow] {
        guard let goal = currentGoalForSubtaskComposer else {
            return []
        }

        return goal.subtasks
            .filter { $0.id != subtaskComposerMode?.subtaskID }
            .map { subtask in
                SubtaskSiblingShareRow(
                    id: subtask.id,
                    title: subtask.title,
                    shareText: siblingGoalShareDrafts[subtask.id] ?? Self.formatMetricValue(subtask.goalSharePercent)
                )
            }
    }

    var subtaskDraftSupportsTaskLinking: Bool {
        subtaskDraftTrackingMode == .quantified
    }

    var subtaskAllocatedGoalSharePercent: Double {
        let siblingShares = subtaskSiblingShareRows.compactMap { row in
            Double(row.shareText.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        let currentShare = parsedSubtaskGoalSharePercent ?? 0
        return PlanGoalSubtask.roundedGoalSharePercent(currentShare + siblingShares.reduce(0, +))
    }

    var subtaskRemainingGoalSharePercent: Double {
        max(0, PlanGoalSubtask.roundedGoalSharePercent(100 - subtaskAllocatedGoalSharePercent))
    }

    func load() {
        do {
            let fetchedGoals = try repository.fetchAll()
            let fetchedTasks = try tasksRepository.fetchAll()
            goals = sortGoals(fetchedGoals)
            tasks = sortTasksForLinking(fetchedTasks)
            errorMessage = nil
        } catch {
            goals = []
            tasks = []
            errorMessage = "Unable to load goals."
        }
    }

    func presentCreateSheet() {
        goalComposerMode = .create
        resetGoalComposer()
        errorMessage = nil
        isPresentingGoalSheet = true
    }

    func presentEditSheet(for goal: PlanGoal) {
        goalComposerMode = .edit(goal.id)
        newGoalTitle = goal.title
        newGoalNotes = goal.notes ?? ""
        newGoalStatus = goal.status
        newGoalStartAt = goal.startAt
        newGoalEndAt = goal.endAt
        prepareGoalComposerSubtaskShareDrafts(for: goal)
        errorMessage = nil
        isPresentingGoalSheet = true
    }

    func dismissGoalSheet() {
        goalComposerMode = .create
        resetGoalComposer()
        errorMessage = nil
        isPresentingGoalSheet = false
    }

    @discardableResult
    func saveGoal() -> Bool {
        let trimmedTitle = newGoalTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            errorMessage = "Goal title is required."
            return false
        }

        guard newGoalEndAt > newGoalStartAt else {
            errorMessage = "End time must be later than start time."
            return false
        }

        let trimmedNotes = newGoalNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        let goal: PlanGoal

        switch goalComposerMode {
        case .create:
            goal = PlanGoal(
                title: trimmedTitle,
                notes: trimmedNotes.isEmpty ? nil : trimmedNotes,
                status: newGoalStatus,
                startAt: newGoalStartAt,
                endAt: newGoalEndAt,
                createdAt: now(),
                subtasks: [],
                displayOrder: nextDisplayOrder
            )
        case let .edit(id):
            guard let existingGoal = goals.first(where: { $0.id == id }) else {
                errorMessage = "Unable to find goal."
                return false
            }
            var updatedSubtasks = existingGoal.subtasks
            if !updatedSubtasks.isEmpty {
                guard let updatedGoalSharePercents = parsedGoalComposerSubtaskSharePercents(for: existingGoal) else {
                    return false
                }

                updatedSubtasks = updatedSubtasks.map { subtask in
                    var updatedSubtask = subtask
                    if let updatedGoalSharePercent = updatedGoalSharePercents[subtask.id] {
                        updatedSubtask.goalSharePercent = PlanGoalSubtask.roundedGoalSharePercent(updatedGoalSharePercent)
                    }
                    return updatedSubtask
                }
                updatedSubtasks = PlanGoalSubtask.normalizedGoalSharePercents(in: updatedSubtasks)
            }
            goal = PlanGoal(
                id: existingGoal.id,
                title: trimmedTitle,
                notes: trimmedNotes.isEmpty ? nil : trimmedNotes,
                status: newGoalStatus,
                startAt: newGoalStartAt,
                endAt: newGoalEndAt,
                createdAt: existingGoal.createdAt,
                subtasks: updatedSubtasks,
                displayOrder: existingGoal.displayOrder
            )
        }

        do {
            switch goalComposerMode {
            case .create:
                try repository.save(goal)
            case .edit:
                try repository.update(goal)
            }
            goalComposerMode = .create
            resetGoalComposer()
            isPresentingGoalSheet = false
            load()
            return true
        } catch {
            errorMessage = "Unable to save goal."
            return false
        }
    }

    func deleteGoal(_ goal: PlanGoal) {
        do {
            try unlinkTasks(linkedTo: Set(goal.subtasks.map(\.id)))
            try repository.delete(id: goal.id)
            if focusedGoalID == goal.id {
                focusedGoalID = nil
            }
            load()
        } catch {
            errorMessage = "Unable to delete goal."
        }
    }

    func restoreGoal(_ goal: PlanGoal) {
        guard goal.status == .completed else {
            return
        }

        var updatedGoal = goal
        updatedGoal.status = .inProgress

        do {
            try repository.update(updatedGoal)
            load()
        } catch {
            errorMessage = "Unable to restore goal."
        }
    }

    func focusGoal(_ goal: PlanGoal) {
        focusedGoalID = goal.id
    }

    func moveActiveGoal(_ sourceID: UUID, to targetID: UUID) {
        guard sourceID != targetID else {
            return
        }

        var orderedActiveGoals = activeGoals
        guard
            let sourceIndex = orderedActiveGoals.firstIndex(where: { $0.id == sourceID }),
            let targetIndex = orderedActiveGoals.firstIndex(where: { $0.id == targetID })
        else {
            return
        }

        let draggedGoal = orderedActiveGoals.remove(at: sourceIndex)
        let insertionIndex = sourceIndex < targetIndex ? targetIndex : targetIndex
        orderedActiveGoals.insert(draggedGoal, at: insertionIndex)

        let reorderedGoals = orderedActiveGoals.enumerated().map { index, goal in
            var updatedGoal = goal
            updatedGoal.displayOrder = index
            return updatedGoal
        }

        do {
            for goal in reorderedGoals {
                try repository.update(goal)
            }
            load()
        } catch {
            errorMessage = "Unable to reorder goals."
        }
    }

    func moveSubtask(_ sourceID: UUID, in goalID: UUID, to targetID: UUID) {
        guard sourceID != targetID else {
            return
        }
        guard let goal = goals.first(where: { $0.id == goalID }) else {
            return
        }

        var updatedGoal = goal
        guard
            let sourceIndex = updatedGoal.subtasks.firstIndex(where: { $0.id == sourceID }),
            let targetIndex = updatedGoal.subtasks.firstIndex(where: { $0.id == targetID })
        else {
            return
        }

        let movedSubtask = updatedGoal.subtasks.remove(at: sourceIndex)
        updatedGoal.subtasks.insert(movedSubtask, at: targetIndex)

        do {
            try repository.update(updatedGoal)
            load()
        } catch {
            errorMessage = "Unable to reorder subtasks."
        }
    }

    func moveSubtaskLeft(_ subtaskID: UUID, in goalID: UUID) {
        guard
            let goal = goals.first(where: { $0.id == goalID }),
            let sourceIndex = goal.subtasks.firstIndex(where: { $0.id == subtaskID }),
            sourceIndex > 0
        else {
            return
        }

        let targetID = goal.subtasks[sourceIndex - 1].id
        moveSubtask(subtaskID, in: goalID, to: targetID)
    }

    func moveSubtaskRight(_ subtaskID: UUID, in goalID: UUID) {
        guard
            let goal = goals.first(where: { $0.id == goalID }),
            let sourceIndex = goal.subtasks.firstIndex(where: { $0.id == subtaskID }),
            sourceIndex < goal.subtasks.count - 1
        else {
            return
        }

        let targetID = goal.subtasks[sourceIndex + 1].id
        moveSubtask(subtaskID, in: goalID, to: targetID)
    }

    func incrementSubtaskValue(for goal: PlanGoal, subtask: PlanGoalSubtask) {
        guard subtask.trackingMode == .quantified else {
            return
        }
        guard var updatedGoal = goals.first(where: { $0.id == goal.id }) else {
            return
        }
        guard let subtaskIndex = updatedGoal.subtasks.firstIndex(where: { $0.id == subtask.id }) else {
            return
        }

        updatedGoal.subtasks[subtaskIndex].baselineValue += 1

        do {
            try repository.update(updatedGoal)
            load()
        } catch {
            errorMessage = "Unable to update subtask."
        }
    }

    func presentCreateSubtaskSheet(for goal: PlanGoal) {
        subtaskComposerMode = .create(goalID: goal.id, subtaskID: UUID())
        resetSubtaskComposer()
        prepareSiblingGoalShareDrafts(for: goal, excluding: subtaskComposerMode?.subtaskID)
        subtaskDraftGoalSharePercent = Self.formatMetricValue(remainingGoalSharePercent(for: goal, excluding: nil))
        errorMessage = nil
        isPresentingSubtaskSheet = true
    }

    func presentEditSubtaskSheet(for goal: PlanGoal, subtask: PlanGoalSubtask) {
        subtaskComposerMode = .edit(goalID: goal.id, subtaskID: subtask.id)
        populateSubtaskDraft(from: subtask)
        prepareSiblingGoalShareDrafts(for: goal, excluding: subtask.id)
        errorMessage = nil
        isPresentingSubtaskSheet = true
    }

    func dismissSubtaskSheet() {
        subtaskComposerMode = nil
        resetSubtaskComposer()
        errorMessage = nil
        isPresentingSubtaskSheet = false
        dismissTaskLinkSheet()
    }

    func setSubtaskDraftTrackingMode(_ mode: PlanGoalSubtaskTrackingMode) {
        guard subtaskDraftTrackingMode != mode else {
            return
        }

        let previousMode = subtaskDraftTrackingMode
        let quantifiedProgressPercent = currentSubtaskPreviewProgressPercent ?? 0

        if previousMode == .estimated && mode == .quantified {
            subtaskDraftTrackingMode = mode
            subtaskDraftUsesEstimatedConversion = true
            subtaskDraftBaselineWasEditedManually = false
            syncQuantifiedBaselineFromEstimatedProgress()
        } else if previousMode == .quantified && mode == .estimated {
            subtaskDraftEstimatedProgressPercent = Self.formatMetricValue(Double(quantifiedProgressPercent))
            subtaskDraftTrackingMode = mode
            subtaskDraftUsesEstimatedConversion = false
            subtaskDraftBaselineWasEditedManually = false
        } else {
            subtaskDraftTrackingMode = mode
        }
    }

    func setSubtaskDraftBaselineValue(_ value: String) {
        subtaskDraftBaselineValue = value
        if subtaskDraftTrackingMode == .quantified {
            subtaskDraftBaselineWasEditedManually = true
        }
    }

    func setSubtaskDraftTargetValue(_ value: String) {
        subtaskDraftTargetValue = value
        if subtaskDraftTrackingMode == .quantified,
           subtaskDraftUsesEstimatedConversion,
           !subtaskDraftBaselineWasEditedManually {
            syncQuantifiedBaselineFromEstimatedProgress()
        }
    }

    func setSiblingGoalShareText(_ value: String, for subtaskID: UUID) {
        siblingGoalShareDrafts[subtaskID] = value
    }

    func setGoalComposerSubtaskShareText(_ value: String, for subtaskID: UUID) {
        goalComposerSubtaskShareDrafts[subtaskID] = value
    }

    func setSubtaskDraftEstimatedPreviewProgress(_ progress: Double) {
        guard progress.isFinite else {
            return
        }

        let clampedProgress = min(max(progress.rounded(), 0), 100)
        subtaskDraftEstimatedProgressPercent = Self.formatMetricValue(clampedProgress)
    }

    @discardableResult
    func saveSubtask() -> Bool {
        persistCurrentSubtask(dismissAfterSave: true) != nil
    }

    func deleteSubtask(_ subtask: PlanGoalSubtask, from goal: PlanGoal) {
        var updatedGoal = goal
        updatedGoal.subtasks.removeAll { $0.id == subtask.id }

        do {
            try repository.update(updatedGoal)
            try unlinkTasks(linkedTo: [subtask.id])
            if subtaskComposerMode?.subtaskID == subtask.id {
                dismissSubtaskSheet()
            }
            load()
        } catch {
            errorMessage = "Unable to delete subtask."
        }
    }

    func presentLinkExistingTaskSheet() {
        guard prepareCurrentSubtaskForTaskLinking() != nil else {
            return
        }

        selectedLinkTaskID = nil
        linkTaskContributionValue = "1"
        errorMessage = nil
        isPresentingTaskLinkSheet = true
    }

    func dismissTaskLinkSheet() {
        isPresentingTaskLinkSheet = false
        selectedLinkTaskID = nil
        linkTaskContributionValue = "1"
    }

    func prepareSubtaskForNewTask() -> PlanGoalSubtask? {
        prepareCurrentSubtaskForTaskLinking()
    }

    func selectTaskForLink(_ task: FocusTask) {
        guard linkableTasks.contains(where: { $0.id == task.id }) else {
            return
        }
        selectedLinkTaskID = task.id
        linkTaskContributionValue = Self.formatMetricValue(task.contributionValue ?? 1)
    }

    @discardableResult
    func confirmSelectedTaskLink() -> Bool {
        guard let selectedLinkTaskID else {
            errorMessage = "Select a Today task first."
            return false
        }
        guard let task = linkableTasks.first(where: { $0.id == selectedLinkTaskID }) else {
            errorMessage = "Selected task is no longer available to link."
            return false
        }
        guard let subtask = currentEditingSubtask else {
            errorMessage = "Save the subtask first."
            return false
        }
        guard let contributionValue = parsedLinkTaskContributionValue else {
            errorMessage = "Contribution value must be a number."
            return false
        }

        let didLinkTask = linkExistingTask(task, to: subtask, contributionValue: contributionValue)
        if didLinkTask {
            dismissTaskLinkSheet()
        }
        return didLinkTask
    }

    @discardableResult
    func linkExistingTask(
        _ task: FocusTask,
        to subtask: PlanGoalSubtask,
        contributionValue: Double
    ) -> Bool {
        guard subtask.trackingMode == .quantified else {
            errorMessage = "Convert this subtask to Quantified before linking Today tasks."
            return false
        }
        guard contributionValue >= 0 else {
            errorMessage = "Contribution value must be non-negative."
            return false
        }

        var updatedTask = task
        updatedTask.linkedSubtaskID = subtask.id
        updatedTask.contributionValue = contributionValue

        do {
            try tasksRepository.update(updatedTask)
            load()
            return true
        } catch {
            errorMessage = "Unable to link task."
            return false
        }
    }

    func unlinkTask(_ task: FocusTask) {
        var updatedTask = task
        updatedTask.linkedSubtaskID = nil
        updatedTask.contributionValue = nil

        do {
            try tasksRepository.update(updatedTask)
            load()
        } catch {
            errorMessage = "Unable to unlink task."
        }
    }

    func currentValue(for subtask: PlanGoalSubtask) -> Double {
        guard subtask.trackingMode == .quantified else {
            return subtask.baselineValue
        }

        let completedContribution = linkedTasks(for: subtask)
            .filter(\.isCompleted)
            .reduce(0) { partialResult, task in
                partialResult + (task.contributionValue ?? 0)
            }
        return subtask.baselineValue + completedContribution
    }

    func progressPercent(for subtask: PlanGoalSubtask) -> Int {
        subtask.progressPercent(for: currentValue(for: subtask))
    }

    func progressPercent(for goal: PlanGoal) -> Int? {
        if goal.status == .completed {
            return 100
        }

        guard !goal.subtasks.isEmpty else {
            return nil
        }

        let normalizedSubtasks = PlanGoalSubtask.normalizedGoalSharePercents(in: goal.subtasks)
        let totalProgress = normalizedSubtasks.reduce(0.0) { partialResult, subtask in
            partialResult + Double(progressPercent(for: subtask)) * (subtask.goalSharePercent / 100)
        }
        return Int(totalProgress.rounded())
    }

    func completedSubtaskCount(for goal: PlanGoal) -> Int {
        goal.subtasks.filter { subtask in
            subtask.isCompleted(currentValue: currentValue(for: subtask))
        }.count
    }

    func linkedTaskCount(for subtask: PlanGoalSubtask) -> Int {
        linkedTasks(for: subtask).count
    }

    func linkedTasks(for subtask: PlanGoalSubtask) -> [FocusTask] {
        linkedTasks(forSubtaskID: subtask.id)
    }

    func subtaskTitle(for id: UUID) -> String? {
        goals
            .flatMap(\.subtasks)
            .first(where: { $0.id == id })?
            .title
    }

    func shiftTimeline(by direction: Int) {
        let currentWindowMonthSpan = windowMonthSpan
        guard let shiftedStart = calendar.date(
            byAdding: .month,
            value: direction * currentWindowMonthSpan,
            to: visibleWindow.start
        ) else {
            return
        }
        visibleWindow = Self.window(
            startingAt: shiftedStart,
            monthSpan: currentWindowMonthSpan,
            calendar: calendar
        )
    }

    func jumpToToday() {
        referenceDate = now()
        visibleWindow = Self.makeMonthWindow(
            around: referenceDate,
            monthSpan: windowMonthSpan,
            calendar: calendar
        )
    }

    func adjustTimelineZoom(deltaY: CGFloat, anchorDate: Date?) {
        let currentSpan = timelineDetailMonthSpan
        let nextSpan = nextZoomMonthSpan(for: deltaY, currentSpan: currentSpan)
        guard nextSpan != currentSpan else { return }
        timelineDetailMonthSpan = nextSpan
    }

    static func todayMarkerTitle(referenceDate: Date, calendar: Calendar = .autoupdatingCurrent) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "M月d日"
        return "今日 \(formatter.string(from: referenceDate))"
    }

    static func formatMetricValue(_ value: Double) -> String {
        if value.rounded() == value {
            return String(Int(value))
        }

        return value.formatted(.number.precision(.fractionLength(0 ... 2)))
    }

    private var currentEditingSubtask: PlanGoalSubtask? {
        guard let subtaskComposerMode else {
            return nil
        }
        return goals
            .first(where: { $0.id == subtaskComposerMode.goalID })?
            .subtasks
            .first(where: { $0.id == subtaskComposerMode.subtaskID })
    }

    private var currentGoalForSubtaskComposer: PlanGoal? {
        guard let subtaskComposerMode else {
            return nil
        }

        return goals.first(where: { $0.id == subtaskComposerMode.goalID })
    }

    private var currentGoalForGoalComposer: PlanGoal? {
        guard case let .edit(goalID) = goalComposerMode else {
            return nil
        }

        return goals.first(where: { $0.id == goalID })
    }

    private var parsedSubtaskBaselineValue: Double? {
        Double(subtaskDraftBaselineValue.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private var parsedSubtaskEstimatedProgressPercent: Double? {
        Double(subtaskDraftEstimatedProgressPercent.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private var parsedSubtaskTargetValue: Double? {
        Double(subtaskDraftTargetValue.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private var parsedSubtaskGoalSharePercent: Double? {
        Double(subtaskDraftGoalSharePercent.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private var parsedLinkTaskContributionValue: Double? {
        Double(linkTaskContributionValue.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private var effectiveQuantifiedDraftBaselineValue: Double? {
        if subtaskDraftUsesEstimatedConversion && !subtaskDraftBaselineWasEditedManually {
            return derivedBaselineFromEstimatedProgress(using: parsedSubtaskTargetValue)
        }

        return parsedSubtaskBaselineValue
    }

    private func prepareCurrentSubtaskForTaskLinking() -> PlanGoalSubtask? {
        guard subtaskDraftSupportsTaskLinking else {
            errorMessage = "Convert this subtask to Quantified to link Today tasks."
            return nil
        }

        guard let savedSubtaskID = persistCurrentSubtask(dismissAfterSave: false) else {
            return nil
        }

        return goals
            .flatMap(\.subtasks)
            .first(where: { $0.id == savedSubtaskID })
    }

    private func persistCurrentSubtask(dismissAfterSave: Bool) -> UUID? {
        guard let subtaskComposerMode else {
            errorMessage = "Unable to find subtask."
            return nil
        }

        let trimmedTitle = subtaskDraftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            errorMessage = "Subtask title is required."
            return nil
        }

        guard let goalSharePercent = parsedSubtaskGoalSharePercent else {
            errorMessage = "Goal share must be a number."
            return nil
        }
        guard goalSharePercent >= 0 else {
            errorMessage = "Goal share must be non-negative."
            return nil
        }

        guard var goal = goals.first(where: { $0.id == subtaskComposerMode.goalID }) else {
            errorMessage = "Unable to find goal."
            return nil
        }

        let siblingShares = parsedSiblingGoalSharePercents(for: goal) ?? [:]
        guard !siblingShares.isEmpty || goal.subtasks.filter({ $0.id != subtaskComposerMode.subtaskID }).isEmpty else {
            return nil
        }

        let totalShare = PlanGoalSubtask.roundedGoalSharePercent(goalSharePercent + siblingShares.values.reduce(0, +))
        guard totalShare <= 100.01 else {
            errorMessage = "Allocated subtask shares can't exceed 100%."
            return nil
        }

        let subtask: PlanGoalSubtask
        switch subtaskDraftTrackingMode {
        case .estimated:
            guard let progressPercent = parsedSubtaskEstimatedProgressPercent else {
                errorMessage = "Estimated progress must be a number."
                return nil
            }
            guard (0 ... 100).contains(progressPercent) else {
                errorMessage = "Estimated progress must be between 0 and 100."
                return nil
            }
            guard linkedTasksForEditingSubtask.isEmpty else {
                errorMessage = "Estimated subtasks can't link Today tasks. Unlink tasks first."
                return nil
            }

            subtask = PlanGoalSubtask(
                id: subtaskComposerMode.subtaskID,
                title: trimmedTitle,
                baselineValue: progressPercent,
                targetValue: 100,
                unitLabel: "%",
                trackingMode: .estimated,
                goalSharePercent: PlanGoalSubtask.roundedGoalSharePercent(goalSharePercent)
            )
        case .quantified:
            guard let baselineValue = effectiveQuantifiedDraftBaselineValue else {
                errorMessage = "Baseline value must be a number."
                return nil
            }
            guard let targetValue = parsedSubtaskTargetValue else {
                errorMessage = "Target value must be a number."
                return nil
            }
            guard targetValue > 0 else {
                errorMessage = "Target value must be greater than 0."
                return nil
            }

            let trimmedUnitLabel = subtaskDraftUnitLabel.trimmingCharacters(in: .whitespacesAndNewlines)
            subtask = PlanGoalSubtask(
                id: subtaskComposerMode.subtaskID,
                title: trimmedTitle,
                baselineValue: baselineValue,
                targetValue: targetValue,
                unitLabel: trimmedUnitLabel,
                trackingMode: .quantified,
                goalSharePercent: PlanGoalSubtask.roundedGoalSharePercent(goalSharePercent)
            )
        }

        goal.subtasks = goal.subtasks.map { existingSubtask in
            guard let siblingShare = siblingShares[existingSubtask.id] else {
                return existingSubtask
            }

            var updatedSubtask = existingSubtask
            updatedSubtask.goalSharePercent = PlanGoalSubtask.roundedGoalSharePercent(siblingShare)
            return updatedSubtask
        }

        if let existingIndex = goal.subtasks.firstIndex(where: { $0.id == subtask.id }) {
            goal.subtasks[existingIndex] = subtask
        } else {
            goal.subtasks.append(subtask)
        }
        goal.subtasks = PlanGoalSubtask.normalizedGoalSharePercents(in: goal.subtasks)

        do {
            try repository.update(goal)
            self.subtaskComposerMode = .edit(goalID: goal.id, subtaskID: subtask.id)
            load()

            if dismissAfterSave {
                dismissSubtaskSheet()
            } else {
                if let savedSubtask = goals
                    .first(where: { $0.id == goal.id })?
                    .subtasks
                    .first(where: { $0.id == subtask.id }) {
                    populateSubtaskDraft(from: savedSubtask)
                } else {
                    populateSubtaskDraft(from: subtask)
                }
                prepareSiblingGoalShareDrafts(for: goal, excluding: subtask.id)
            }
            return subtask.id
        } catch {
            errorMessage = "Unable to save subtask."
            return nil
        }
    }

    private func unlinkTasks(linkedTo subtaskIDs: Set<UUID>) throws {
        guard !subtaskIDs.isEmpty else {
            return
        }

        let affectedTasks = try tasksRepository.fetchAll().filter { task in
            guard let linkedSubtaskID = task.linkedSubtaskID else {
                return false
            }
            return subtaskIDs.contains(linkedSubtaskID)
        }

        for task in affectedTasks {
            var updatedTask = task
            updatedTask.linkedSubtaskID = nil
            updatedTask.contributionValue = nil
            try tasksRepository.update(updatedTask)
        }
    }

    private func linkedTasks(forSubtaskID subtaskID: UUID) -> [FocusTask] {
        sortTasksForLinking(
            tasks.filter { $0.linkedSubtaskID == subtaskID }
        )
    }

    private func populateSubtaskDraft(from subtask: PlanGoalSubtask) {
        subtaskDraftTitle = subtask.title
        subtaskDraftTrackingMode = subtask.trackingMode
        subtaskDraftEstimatedProgressPercent = Self.formatMetricValue(Double(subtask.progressPercent))
        subtaskDraftBaselineValue = Self.formatMetricValue(subtask.baselineValue)
        subtaskDraftTargetValue = Self.formatMetricValue(subtask.targetValue)
        subtaskDraftUnitLabel = subtask.trackingMode == .estimated ? "" : subtask.unitLabel
        subtaskDraftGoalSharePercent = Self.formatMetricValue(subtask.goalSharePercent)
        subtaskDraftUsesEstimatedConversion = false
        subtaskDraftBaselineWasEditedManually = false
    }

    private func resetGoalComposer() {
        let currentDate = now()
        newGoalTitle = ""
        newGoalNotes = ""
        newGoalStatus = .notStarted
        newGoalStartAt = currentDate
        newGoalEndAt = currentDate.addingTimeInterval(14 * 24 * 60 * 60)
        goalComposerSubtaskShareDrafts = [:]
    }

    private func resetSubtaskComposer() {
        subtaskDraftTitle = ""
        subtaskDraftBaselineValue = "0"
        subtaskDraftTargetValue = "100"
        subtaskDraftUnitLabel = ""
        subtaskDraftTrackingMode = .quantified
        subtaskDraftEstimatedProgressPercent = "0"
        subtaskDraftGoalSharePercent = "100"
        selectedLinkTaskID = nil
        linkTaskContributionValue = "1"
        siblingGoalShareDrafts = [:]
        subtaskDraftUsesEstimatedConversion = false
        subtaskDraftBaselineWasEditedManually = false
    }

    private func parsedSiblingGoalSharePercents(for goal: PlanGoal) -> [UUID: Double]? {
        var parsedShares: [UUID: Double] = [:]

        for sibling in goal.subtasks where sibling.id != subtaskComposerMode?.subtaskID {
            let draftText = siblingGoalShareDrafts[sibling.id] ?? Self.formatMetricValue(sibling.goalSharePercent)
            guard let parsedShare = Double(draftText.trimmingCharacters(in: .whitespacesAndNewlines)) else {
                errorMessage = "Every sibling goal share must be a number."
                return nil
            }
            guard parsedShare >= 0 else {
                errorMessage = "Goal share must be non-negative."
                return nil
            }
            parsedShares[sibling.id] = parsedShare
        }

        return parsedShares
    }

    private func prepareSiblingGoalShareDrafts(for goal: PlanGoal, excluding subtaskID: UUID?) {
        siblingGoalShareDrafts = Dictionary(
            uniqueKeysWithValues: goal.subtasks
                .filter { $0.id != subtaskID }
                .map { subtask in
                    (subtask.id, Self.formatMetricValue(subtask.goalSharePercent))
                }
        )
    }

    private func prepareGoalComposerSubtaskShareDrafts(for goal: PlanGoal) {
        goalComposerSubtaskShareDrafts = Dictionary(
            uniqueKeysWithValues: goal.subtasks.map { subtask in
                (subtask.id, Self.formatMetricValue(subtask.goalSharePercent))
            }
        )
    }

    private func parsedGoalComposerSubtaskSharePercents(for goal: PlanGoal) -> [UUID: Double]? {
        var parsedShares: [UUID: Double] = [:]

        for subtask in goal.subtasks {
            let draftText = goalComposerSubtaskShareDrafts[subtask.id] ?? Self.formatMetricValue(subtask.goalSharePercent)
            guard let parsedShare = Double(draftText.trimmingCharacters(in: .whitespacesAndNewlines)) else {
                errorMessage = "Every subtask goal share must be a number."
                return nil
            }
            guard parsedShare >= 0 else {
                errorMessage = "Goal share must be non-negative."
                return nil
            }
            parsedShares[subtask.id] = parsedShare
        }

        let totalShare = PlanGoalSubtask.roundedGoalSharePercent(parsedShares.values.reduce(0, +))
        guard totalShare <= 100.01 else {
            errorMessage = "Allocated subtask shares can't exceed 100%."
            return nil
        }

        return parsedShares
    }

    private func remainingGoalSharePercent(for goal: PlanGoal, excluding subtaskID: UUID?) -> Double {
        let allocated = goal.subtasks
            .filter { $0.id != subtaskID }
            .reduce(0.0) { partialResult, subtask in
                partialResult + subtask.goalSharePercent
            }
        return max(0, PlanGoalSubtask.roundedGoalSharePercent(100 - allocated))
    }

    private func syncQuantifiedBaselineFromEstimatedProgress() {
        guard let derivedBaseline = derivedBaselineFromEstimatedProgress(using: parsedSubtaskTargetValue) else {
            return
        }

        subtaskDraftBaselineValue = Self.formatMetricValue(derivedBaseline)
    }

    private func derivedBaselineFromEstimatedProgress(using targetValue: Double?) -> Double? {
        guard
            let progressPercent = parsedSubtaskEstimatedProgressPercent,
            let targetValue,
            targetValue > 0
        else {
            return nil
        }

        return (progressPercent / 100) * targetValue
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

    private var nextDisplayOrder: Int {
        (goals.map(\.displayOrder).filter { $0 >= 0 }.max() ?? -1) + 1
    }

    private func sortTasksForLinking(_ tasks: [FocusTask]) -> [FocusTask] {
        tasks.sorted { lhs, rhs in
            if lhs.isCompleted != rhs.isCompleted {
                return lhs.isCompleted == false
            }
            if lhs.priority.sortOrder != rhs.priority.sortOrder {
                return lhs.priority.sortOrder < rhs.priority.sortOrder
            }
            if lhs.createdAt != rhs.createdAt {
                return lhs.createdAt > rhs.createdAt
            }
            return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
        }
    }

    private func isTaskLinkableForSubtask(_ task: FocusTask) -> Bool {
        guard !task.isCompleted else {
            return false
        }

        return task.isVisibleInToday(at: now()) || task.isRepeating
    }

    private var windowMonthSpan: Int {
        max(1, calendar.dateComponents([.month], from: visibleWindow.start, to: visibleWindow.end).month ?? 1)
    }

    private func nextZoomMonthSpan(for deltaY: CGFloat, currentSpan: Int) -> Int {
        guard deltaY != 0 else { return currentSpan }

        if deltaY > 0 {
            return zoomMonthSteps.last(where: { $0 < currentSpan }) ?? currentSpan
        }

        return zoomMonthSteps.first(where: { $0 > currentSpan }) ?? currentSpan
    }

    private static func makeMonthWindow(
        around anchorDate: Date,
        monthSpan: Int,
        calendar: Calendar
    ) -> DateInterval {
        let clampedMonthSpan = min(max(monthSpan, 1), 12)
        let anchorMonthStart = calendar.date(
            from: calendar.dateComponents([.year, .month], from: anchorDate)
        ) ?? anchorDate

        if clampedMonthSpan == 12 {
            let yearStart = calendar.date(
                from: calendar.dateComponents([.year], from: anchorDate)
            ) ?? anchorMonthStart
            return window(startingAt: yearStart, monthSpan: clampedMonthSpan, calendar: calendar)
        }

        let leadingMonths = (clampedMonthSpan - 1) / 2
        let start = calendar.date(
            byAdding: .month,
            value: -leadingMonths,
            to: anchorMonthStart
        ) ?? anchorMonthStart
        return window(startingAt: start, monthSpan: clampedMonthSpan, calendar: calendar)
    }

    private static func window(
        startingAt start: Date,
        monthSpan: Int,
        calendar: Calendar
    ) -> DateInterval {
        let end = calendar.date(
            byAdding: .month,
            value: monthSpan,
            to: start
        ) ?? start.addingTimeInterval(TimeInterval(monthSpan) * 30 * 24 * 60 * 60)
        return DateInterval(start: start, end: end)
    }
}
