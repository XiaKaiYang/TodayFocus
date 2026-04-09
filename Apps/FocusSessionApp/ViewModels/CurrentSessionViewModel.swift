import Foundation
import Combine
import FocusSessionCore
import SwiftData

struct RecentSessionSummary: Identifiable, Equatable {
    let id: UUID
    let title: String
    let notePreview: String
    let relativeEndedText: String
    let durationText: String
    let wasCompleted: Bool

    init(record: FocusSessionRecord, referenceDate: Date) {
        let relativeFormatter = RelativeDateTimeFormatter()
        relativeFormatter.unitsStyle = .full

        let trimmedIntention = record.intention.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNotes = (record.notes ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let roundedMinutes = max(1, Int(ceil(Double(record.durationSeconds) / 60)))

        id = record.id
        title = trimmedIntention.isEmpty ? "Untitled Session" : trimmedIntention
        notePreview = trimmedNotes
        relativeEndedText = relativeFormatter.localizedString(for: record.endedAt, relativeTo: referenceDate)
        durationText = "\(roundedMinutes) min"
        wasCompleted = record.wasCompleted
    }
}

private struct PendingReflectionSession: Equatable {
    let intention: String
    let startedAt: Date
    let endedAt: Date
}

private enum ReflectionSubmissionBehavior {
    case completeTask
    case continueEpisode
}

struct CurrentSessionTaskSelection: Identifiable, Hashable {
    let taskID: UUID
    let subtaskID: UUID?
    let selectorTitle: String
    let activeTitle: String
    let estimatedMinutes: Int

    var id: SelectionID {
        SelectionID(taskID: taskID, subtaskID: subtaskID)
    }

    init(task: FocusTask, subtask: TaskSubtask? = nil) {
        taskID = task.id
        subtaskID = subtask?.id
        estimatedMinutes = task.estimatedMinutes

        if let subtask {
            selectorTitle = "\(task.title) / \(subtask.title)"
            activeTitle = subtask.title
        } else {
            selectorTitle = task.title
            activeTitle = task.title
        }
    }

    static func == (lhs: CurrentSessionTaskSelection, rhs: CurrentSessionTaskSelection) -> Bool {
        lhs.taskID == rhs.taskID && lhs.subtaskID == rhs.subtaskID
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(taskID)
        hasher.combine(subtaskID)
    }

    struct SelectionID: Hashable {
        let taskID: UUID
        let subtaskID: UUID?
    }
}

@MainActor
final class CurrentSessionViewModel: ObservableObject {
    @Published var intention = ""
    @Published var sessionNotes = ""
    @Published var durationMinutes = 25
    @Published private(set) var availableTasks: [FocusTask] = []
    @Published private(set) var availableTaskSelections: [CurrentSessionTaskSelection] = []
    @Published private(set) var selectedTaskSelection: CurrentSessionTaskSelection?
    @Published private(set) var sessionState = SessionState.idle
    @Published private(set) var recentSessions: [RecentSessionSummary] = []
    @Published private(set) var selectedReflectionMood: SessionReflectionMood?
    @Published private(set) var errorMessage: String?
    private let snapshotStore: RuntimeSnapshotStore?
    private let focusSessionRepository: FocusSessionRepository
    private let tasksRepository: TasksRepository
    private let linkedTaskSettlementCoordinator: LinkedTaskSettlementCoordinator
    private let preferencesStore: AppPreferencesStore?
    private let soundEffectPlayer: SoundEffectPlaying?
    private let now: () -> Date
    private let onHistoryChanged: (() -> Void)?
    private var activeSegmentStartedAt: Date?
    private var accumulatedFocusSeconds = 0
    private var pendingReflectionSession: PendingReflectionSession?
    private var reflectionSubmissionBehavior: ReflectionSubmissionBehavior = .completeTask
    private var cancellables = Set<AnyCancellable>()

    init(
        snapshotStore: RuntimeSnapshotStore? = RuntimeSnapshotStore.defaultLocal(),
        focusSessionRepository: FocusSessionRepository? = nil,
        tasksRepository: TasksRepository? = nil,
        linkedTaskSettlementCoordinator: LinkedTaskSettlementCoordinator? = nil,
        preferencesStore: AppPreferencesStore? = nil,
        soundEffectPlayer: SoundEffectPlaying? = nil,
        now: @escaping () -> Date = Date.init,
        onHistoryChanged: (() -> Void)? = nil
    ) {
        self.snapshotStore = snapshotStore
        self.preferencesStore = preferencesStore
        self.soundEffectPlayer = soundEffectPlayer
        self.onHistoryChanged = onHistoryChanged
        if let focusSessionRepository {
            self.focusSessionRepository = focusSessionRepository
        } else {
            self.focusSessionRepository = FocusSessionRepository(
                modelContext: ModelContext(FocusSessionModelContainer.shared)
            )
        }
        let resolvedTasksRepository: TasksRepository
        if let tasksRepository {
            resolvedTasksRepository = tasksRepository
        } else {
            resolvedTasksRepository = TasksRepository(
                modelContext: ModelContext(FocusSessionModelContainer.shared)
            )
        }
        self.tasksRepository = resolvedTasksRepository
        self.linkedTaskSettlementCoordinator = linkedTaskSettlementCoordinator ?? LinkedTaskSettlementCoordinator(
            tasksRepository: resolvedTasksRepository
        )
        self.now = now
        durationMinutes = preferencesStore?.preferences.defaultFocusDurationMinutes ?? 25

        preferencesStore?.$preferences
            .receive(on: RunLoop.main)
            .sink { [weak self] preferences in
                guard let self else { return }
                if self.canConfigureSession {
                    self.durationMinutes = preferences.defaultFocusDurationMinutes
                }
                self.refreshRecentSessions()
            }
            .store(in: &cancellables)

        reloadAvailableTasks()
        refreshRecentSessions()
    }

    var currentIntention: String {
        sessionState.snapshot?.intention ?? intention
    }

    var menuBarTitle: String {
        guard shouldExposeTaskInMenuBar else {
            return "TodayFocus"
        }

        let trimmedTitle = currentIntention.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedTitle.isEmpty ? "TodayFocus" : trimmedTitle
    }

    func statusItemTitle(at currentDate: Date) -> String {
        guard shouldExposeTaskInMenuBar else {
            return "TodayFocus"
        }

        let trimmedTitle = currentIntention.trimmingCharacters(in: .whitespacesAndNewlines)
        let title = trimmedTitle.isEmpty ? "TodayFocus" : trimmedTitle
        return "\(title) · \(remainingTimeText(at: currentDate))"
    }

    var selectedTaskID: UUID? {
        selectedTaskSelection?.taskID
    }

    var selectedTaskSubtaskID: UUID? {
        selectedTaskSelection?.subtaskID
    }

    var selectedTaskTitle: String? {
        selectedTaskSelection?.selectorTitle
    }

    var canStartSelectedTaskSession: Bool {
        canConfigureSession && selectedTaskSelection != nil && durationMinutes > 0
    }

    var showReflectionComposer: Bool {
        sessionState.phase == .reflecting
    }

    var canConfigureSession: Bool {
        switch sessionState.phase {
        case .idle, .completed, .abandoned:
            true
        case .focusing, .focusPaused, .breakRunning, .breakPaused, .reflecting:
            false
        }
    }

    var canPauseSession: Bool {
        sessionState.phase == .focusing
    }

    var canResumeSession: Bool {
        sessionState.phase == .focusPaused
    }

    var canFinishSession: Bool {
        switch sessionState.phase {
        case .focusing, .focusPaused:
            true
        case .idle, .breakRunning, .breakPaused, .reflecting, .completed, .abandoned:
            false
        }
    }

    var canExtendSession: Bool {
        switch sessionState.phase {
        case .focusing, .focusPaused:
            true
        case .idle, .breakRunning, .breakPaused, .reflecting, .completed, .abandoned:
            false
        }
    }

    var canAbandonSession: Bool {
        switch sessionState.phase {
        case .focusing, .focusPaused, .breakRunning, .breakPaused:
            true
        case .idle, .reflecting, .completed, .abandoned:
            false
        }
    }

    var canPrepareNextSession: Bool {
        switch sessionState.phase {
        case .completed, .abandoned:
            true
        case .idle, .focusing, .focusPaused, .breakRunning, .breakPaused, .reflecting:
            false
        }
    }

    var phaseText: String {
        switch sessionState.phase {
        case .idle:
            "Idle"
        case .focusing:
            "Focusing"
        case .focusPaused:
            "Paused"
        case .breakRunning:
            "On Break"
        case .breakPaused:
            "Break Paused"
        case .reflecting:
            "Reflecting"
        case .completed:
            "Completed"
        case .abandoned:
            "Abandoned"
        }
    }

    var remainingMinutesText: String {
        let seconds = remainingSeconds(at: now())
        return "\(seconds / 60) min"
    }

    var dialConfigurationProgress: Double {
        FocusClockDialMath.normalizedValue(forMinutes: durationMinutes)
    }

    func remainingTimeText(at currentDate: Date) -> String {
        let seconds = remainingSeconds(at: currentDate)
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }

    func dialProgress(at currentDate: Date) -> Double {
        if canConfigureSession {
            return dialConfigurationProgress
        }

        guard let snapshot = sessionState.snapshot,
              snapshot.plannedDurationSeconds > 0 else {
            return 0
        }

        let remaining = remainingSeconds(at: currentDate)
        let elapsed = snapshot.plannedDurationSeconds - remaining
        return min(max(Double(elapsed) / Double(snapshot.plannedDurationSeconds), 0), 1)
    }

    func updateDurationFromDial(normalizedValue: Double) {
        guard canConfigureSession else {
            return
        }
        durationMinutes = FocusClockDialMath.minutes(for: normalizedValue)
    }

    func startSession() {
        guard let selectedTaskSelection else {
            errorMessage = availableTaskSelections.isEmpty
                ? "Create a task in Today first."
                : "Select a Today task first."
            return
        }

        guard durationMinutes > 0 else {
            errorMessage = "Turn the dial above 0 first."
            return
        }

        let plannedMinutes = clampedDurationMinutes(durationMinutes)
        let trimmedIntention = selectedTaskSelection.activeTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        intention = trimmedIntention
        durationMinutes = plannedMinutes

        if sessionState.phase == .completed || sessionState.phase == .abandoned {
            sessionState = .idle
            resetTracking()
        }

        dispatch(
            .startSession(
                intention: trimmedIntention,
                durationSeconds: plannedMinutes * 60
            ),
            fallbackMessage: "Unable to start session."
        )
    }

    func startTaskSession(title: String, estimatedMinutes: Int) {
        guard canConfigureSession else {
            errorMessage = "Finish the current session before starting another task."
            return
        }

        errorMessage = availableTaskSelections.isEmpty
            ? "Create a task in Today first."
            : "Select a Today task first."
    }

    func selectTask(_ task: FocusTask, subtask: TaskSubtask? = nil) {
        guard canConfigureSession else {
            return
        }

        guard !task.isCompleted && task.isVisibleInToday(at: now()) else {
            return
        }

        if let subtask {
            selectTask(
                CurrentSessionTaskSelection(task: task, subtask: subtask)
            )
            return
        }

        let remainingSubtasks = task.subtasks.filter { !$0.isCompleted }
        if task.hasSubtasks {
            guard remainingSubtasks.count == 1, let remainingSubtask = remainingSubtasks.first else {
                return
            }

            selectTask(
                CurrentSessionTaskSelection(task: task, subtask: remainingSubtask)
            )
            return
        }

        selectTask(CurrentSessionTaskSelection(task: task))
    }

    func selectTask(_ selection: CurrentSessionTaskSelection) {
        guard canConfigureSession else {
            return
        }

        reloadAvailableTasks()
        guard let refreshedSelection = availableTaskSelections.first(where: { $0 == selection }) else {
            return
        }

        selectedTaskSelection = refreshedSelection
        intention = refreshedSelection.activeTitle
        durationMinutes = clampedDurationMinutes(refreshedSelection.estimatedMinutes)
        errorMessage = nil
    }

    func pauseSession() {
        dispatch(.pause, fallbackMessage: "Unable to pause session.")
    }

    func resumeSession() {
        dispatch(.resume, fallbackMessage: "Unable to resume session.")
    }

    func finishSession() {
        finishSession(at: now())
    }

    func abandonSession() {
        dispatch(.abandon, fallbackMessage: "Unable to abandon session.")
    }

    func extendSession(byMinutes minutes: Int) {
        dispatch(.extend(minutes: minutes), fallbackMessage: "Unable to extend session.")
    }

    func reloadData() {
        reloadAvailableTasks()
        refreshRecentSessions()
    }

    func selectReflectionMood(_ mood: SessionReflectionMood) {
        guard showReflectionComposer else {
            return
        }
        selectedReflectionMood = mood
        errorMessage = nil
    }

    func submitReflection() {
        submitReflection(using: .completeTask)
    }

    func submitReflectionAndContinueEpisode() {
        let selectedTaskSelectionBeforeSubmit = selectedTaskSelection
        submitReflection(using: .continueEpisode)

        guard errorMessage == nil else {
            return
        }
        guard sessionState.phase == .completed else {
            return
        }
        guard
            let selectedTaskSelection,
            selectedTaskSelection == selectedTaskSelectionBeforeSubmit
        else {
            errorMessage = "Unable to continue because the selected Today task is no longer available."
            return
        }

        startSession()
    }

    private func submitReflection(using behavior: ReflectionSubmissionBehavior) {
        guard showReflectionComposer else {
            errorMessage = "Finish a session before submitting reflection."
            return
        }
        guard pendingReflectionSession != nil else {
            errorMessage = "Unable to find the finished session."
            return
        }
        guard selectedReflectionMood != nil else {
            errorMessage = "Choose a session mood before submitting."
            return
        }

        reflectionSubmissionBehavior = behavior
        dispatch(.submitReflection, fallbackMessage: "Unable to submit reflection.")
        reflectionSubmissionBehavior = .completeTask
    }

    func handleTimelineTick(at currentDate: Date) {
        guard sessionState.phase == .focusing else {
            return
        }
        guard remainingSeconds(at: currentDate) == 0 else {
            return
        }

        finishSession(at: currentDate)
    }

    func prepareNextSession() {
        guard canPrepareNextSession else {
            return
        }

        sessionState = .idle
        selectedTaskSelection = nil
        intention = ""
        sessionNotes = ""
        selectedReflectionMood = nil
        durationMinutes = preferencesStore?.preferences.defaultFocusDurationMinutes ?? 25
        pendingReflectionSession = nil
        resetTracking()
        errorMessage = nil
    }

    private var shouldExposeTaskInMenuBar: Bool {
        switch sessionState.phase {
        case .focusing, .focusPaused, .breakRunning, .breakPaused:
            true
        case .idle, .reflecting, .completed, .abandoned:
            false
        }
    }

    private func finishSession(at eventDate: Date) {
        dispatch(
            .finishFocus,
            fallbackMessage: "Unable to finish session.",
            eventDateOverride: eventDate
        )
    }

    private func dispatch(
        _ event: SessionEvent,
        fallbackMessage: String,
        eventDateOverride: Date? = nil
    ) {
        let previousState = sessionState
        let previousActiveSegmentStartedAt = activeSegmentStartedAt
        let previousAccumulatedFocusSeconds = accumulatedFocusSeconds
        let previousPendingReflectionSession = pendingReflectionSession
        let previousReflectionMood = selectedReflectionMood
        let previousSessionNotes = sessionNotes
        let previousReflectionSubmissionBehavior = reflectionSubmissionBehavior
        do {
            let previousSnapshot = previousState.snapshot
            let eventDate = eventDateOverride ?? now()
            _ = try SessionReducer.reduce(state: &sessionState, event: event)
            try reconcileTiming(
                after: event,
                previousState: previousState,
                previousSnapshot: previousSnapshot,
                eventDate: eventDate
            )
            try syncRuntimeSnapshot()
            errorMessage = nil
        } catch {
            sessionState = previousState
            activeSegmentStartedAt = previousActiveSegmentStartedAt
            accumulatedFocusSeconds = previousAccumulatedFocusSeconds
            pendingReflectionSession = previousPendingReflectionSession
            selectedReflectionMood = previousReflectionMood
            sessionNotes = previousSessionNotes
            reflectionSubmissionBehavior = previousReflectionSubmissionBehavior
            errorMessage = fallbackMessage
        }
    }

    private func reconcileTiming(
        after event: SessionEvent,
        previousState: SessionState,
        previousSnapshot: ActiveSessionSnapshot?,
        eventDate: Date
    ) throws {
        switch event {
        case .startSession:
            if previousState.phase == .completed || previousState.phase == .abandoned {
                sessionNotes = ""
            }
            pendingReflectionSession = nil
            selectedReflectionMood = nil
            activeSegmentStartedAt = eventDate
            accumulatedFocusSeconds = 0
            if var snapshot = sessionState.snapshot {
                snapshot.startedAt = eventDate
                sessionState.snapshot = snapshot
            }

        case .pause:
            accumulatedFocusSeconds += elapsedSeconds(
                since: activeSegmentStartedAt,
                until: eventDate
            )
            activeSegmentStartedAt = nil
            if var snapshot = sessionState.snapshot {
                snapshot.plannedDurationSeconds = remainingSeconds(
                    for: previousSnapshot,
                    runningFrom: previousState.phase == .focusing ? previousSnapshot?.startedAt ?? activeSegmentStartedAt : nil,
                    at: eventDate
                )
                snapshot.startedAt = eventDate
                sessionState.snapshot = snapshot
            }

        case .resume:
            activeSegmentStartedAt = eventDate
            if var snapshot = sessionState.snapshot {
                snapshot.startedAt = eventDate
                sessionState.snapshot = snapshot
            }

        case .finishFocus:
            if let previousSnapshot {
                pendingReflectionSession = makePendingReflectionSession(
                    from: previousSnapshot,
                    previousPhase: previousState.phase,
                    eventDate: eventDate
                )
            }
            selectedReflectionMood = nil
            playSessionEndSoundIfNeeded()
            resetTracking()

        case .submitReflection:
            guard
                let pendingReflectionSession,
                let selectedReflectionMood
            else {
                break
            }
            try persistSubmittedReflection(
                pendingReflectionSession,
                mood: selectedReflectionMood,
                shouldCompleteSelectedTask: reflectionSubmissionBehavior == .completeTask
            )
            self.pendingReflectionSession = nil

        case .abandon:
            if let previousSnapshot {
                try persistHistoryRecord(
                    from: previousSnapshot,
                    previousPhase: previousState.phase,
                    eventDate: eventDate,
                    wasCompleted: false
                )
            }
            pendingReflectionSession = nil
            selectedReflectionMood = nil
            resetTracking()

        case .extend, .startBreak, .skipBreak, .finishBreak:
            break
        }
    }

    private func syncRuntimeSnapshot() throws {
        guard let snapshotStore else {
            return
        }

        if let snapshot = sessionState.snapshot {
            try snapshotStore.write(snapshot)
        } else {
            try snapshotStore.clear()
        }
    }

    private func remainingSeconds(at currentDate: Date) -> Int {
        switch sessionState.phase {
        case .idle:
            return durationMinutes * 60
        case .focusing:
            return remainingSeconds(
                for: sessionState.snapshot,
                runningFrom: activeSegmentStartedAt,
                at: currentDate
            )
        case .focusPaused, .breakRunning, .breakPaused:
            return sessionState.snapshot?.plannedDurationSeconds ?? durationMinutes * 60
        case .reflecting, .completed, .abandoned:
            return 0
        }
    }

    private func remainingSeconds(
        for snapshot: ActiveSessionSnapshot?,
        runningFrom startDate: Date?,
        at currentDate: Date
    ) -> Int {
        guard let snapshot else {
            return 0
        }

        guard let startDate else {
            return max(0, snapshot.plannedDurationSeconds)
        }

        let elapsed = elapsedSeconds(since: startDate, until: currentDate)
        return max(0, snapshot.plannedDurationSeconds - elapsed)
    }

    private func elapsedSeconds(since startDate: Date?, until endDate: Date) -> Int {
        guard let startDate else {
            return 0
        }
        return max(0, Int(endDate.timeIntervalSince(startDate)))
    }

    private func persistHistoryRecord(
        from snapshot: ActiveSessionSnapshot,
        previousPhase: SessionPhase,
        eventDate: Date,
        wasCompleted: Bool,
        mood: SessionReflectionMood? = nil
    ) throws {
        let focusedSeconds = focusedDurationSeconds(
            previousPhase: previousPhase,
            eventDate: eventDate
        )
        let endedAt = eventDate
        let startedAt = endedAt.addingTimeInterval(-TimeInterval(max(0, focusedSeconds)))
        let normalizedNotes = sessionNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        try focusSessionRepository.save(
            FocusSessionRecord(
                intention: snapshot.intention,
                startedAt: startedAt,
                endedAt: endedAt,
                notes: normalizedNotes.isEmpty ? nil : normalizedNotes,
                mood: mood,
                wasCompleted: wasCompleted
            )
        )
        refreshRecentSessions()
        onHistoryChanged?()
    }

    private func makePendingReflectionSession(
        from snapshot: ActiveSessionSnapshot,
        previousPhase: SessionPhase,
        eventDate: Date
    ) -> PendingReflectionSession {
        let focusedSeconds = focusedDurationSeconds(
            previousPhase: previousPhase,
            eventDate: eventDate
        )
        let endedAt = eventDate
        let startedAt = endedAt.addingTimeInterval(-TimeInterval(max(0, focusedSeconds)))
        return PendingReflectionSession(
            intention: snapshot.intention,
            startedAt: startedAt,
            endedAt: endedAt
        )
    }

    private func persistSubmittedReflection(
        _ reflection: PendingReflectionSession,
        mood: SessionReflectionMood,
        shouldCompleteSelectedTask: Bool
    ) throws {
        let normalizedNotes = sessionNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        try focusSessionRepository.save(
            FocusSessionRecord(
                intention: reflection.intention,
                startedAt: reflection.startedAt,
                endedAt: reflection.endedAt,
                notes: normalizedNotes.isEmpty ? nil : normalizedNotes,
                mood: mood,
                wasCompleted: true
            )
        )
        if shouldCompleteSelectedTask {
            try completeSelectedTaskIfNeeded(at: reflection.endedAt)
        }
        sessionNotes = ""
        selectedReflectionMood = nil
        reloadAvailableTasks()
        refreshRecentSessions()
        onHistoryChanged?()
    }

    private func completeSelectedTaskIfNeeded(at completedAt: Date) throws {
        guard let selectedTaskSelection else {
            return
        }

        if let subtaskID = selectedTaskSelection.subtaskID {
            try linkedTaskSettlementCoordinator.completeSubtask(
                taskID: selectedTaskSelection.taskID,
                subtaskID: subtaskID,
                completedAt: completedAt
            )
            return
        }

        try linkedTaskSettlementCoordinator.completeTask(
            id: selectedTaskSelection.taskID,
            completedAt: completedAt
        )
    }

    private func focusedDurationSeconds(
        previousPhase: SessionPhase,
        eventDate: Date
    ) -> Int {
        switch previousPhase {
        case .focusing:
            accumulatedFocusSeconds
                + elapsedSeconds(since: activeSegmentStartedAt, until: eventDate)
        case .focusPaused:
            accumulatedFocusSeconds
        case .idle, .breakRunning, .breakPaused, .reflecting, .completed, .abandoned:
            accumulatedFocusSeconds
        }
    }

    private func resetTracking() {
        activeSegmentStartedAt = nil
        accumulatedFocusSeconds = 0
    }

    private func playSessionEndSoundIfNeeded() {
        guard selectedTaskSelection != nil else {
            return
        }

        let defaultPreferences = AppPreferences()
        soundEffectPlayer?.play(
            SoundPlaybackRequest(
                assetName: preferencesStore?.preferences.sessionEndSoundName ?? defaultPreferences.sessionEndSoundName,
                volume: preferencesStore?.preferences.sessionEndSoundVolume ?? defaultPreferences.sessionEndSoundVolume
            )
        )
    }

    private func clampedDurationMinutes(_ minutes: Int) -> Int {
        min(
            max(minutes, FocusClockDialMath.minMinutes),
            FocusClockDialMath.maxMinutes
        )
    }

    private func reloadAvailableTasks() {
        do {
            availableTasks = try tasksRepository.fetchAll()
                .filter { !$0.isCompleted && $0.isVisibleInToday(at: now()) }
                .sorted { lhs, rhs in
                    if lhs.createdAt != rhs.createdAt {
                        return lhs.createdAt > rhs.createdAt
                    }
                    return lhs.title < rhs.title
                }
            availableTaskSelections = availableTasks.flatMap(Self.taskSelections(for:))

            if let selectedTaskSelection,
               let refreshedSelection = availableTaskSelections.first(where: { $0 == selectedTaskSelection }) {
                self.selectedTaskSelection = refreshedSelection
            } else if selectedTaskSelection != nil && canConfigureSession {
                self.selectedTaskSelection = nil
                intention = ""
            }
        } catch {
            availableTasks = []
            availableTaskSelections = []
        }
    }

    private func refreshRecentSessions() {
        do {
            let fetchLimit = preferencesStore?.preferences.recentSessionsLimit ?? 8
            recentSessions = try focusSessionRepository.fetchAll()
                .sorted { lhs, rhs in
                    lhs.endedAt > rhs.endedAt
                }
                .prefix(fetchLimit)
                .map { record in
                    RecentSessionSummary(record: record, referenceDate: now())
                }
        } catch {
            recentSessions = []
        }
    }

    private static func taskSelections(for task: FocusTask) -> [CurrentSessionTaskSelection] {
        guard task.hasSubtasks else {
            return [CurrentSessionTaskSelection(task: task)]
        }

        return task.subtasks
            .filter { !$0.isCompleted }
            .map { CurrentSessionTaskSelection(task: task, subtask: $0) }
    }
}
