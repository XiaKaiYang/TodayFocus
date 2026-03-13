import FocusSessionCore

struct CurrentSessionSceneConfiguration {
    let showsFocusClockStage: Bool
    let showsNotesWorkspace: Bool
    let showsNotesWorkspaceChrome: Bool
    let showsEmbeddedWorkspaceBackground: Bool
    let showsHistoryNotes: Bool
    let showsDurationControls: Bool
    let showsRunningStatusBar: Bool

    static func make(phase: SessionPhase) -> CurrentSessionSceneConfiguration {
        let isNotesWorkspacePhase = phase.isNotesWorkspacePhase

        return CurrentSessionSceneConfiguration(
            showsFocusClockStage: !isNotesWorkspacePhase,
            showsNotesWorkspace: isNotesWorkspacePhase,
            showsNotesWorkspaceChrome: false,
            showsEmbeddedWorkspaceBackground: false,
            showsHistoryNotes: false,
            showsDurationControls: !isNotesWorkspacePhase,
            showsRunningStatusBar: isNotesWorkspacePhase
        )
    }

    static func shouldRevealRuntimeNoteComposer(
        phase: SessionPhase,
        isHoveringCenteredTimer: Bool,
        isEditingNotes: Bool
    ) -> Bool {
        phase.isNotesWorkspacePhase && (isHoveringCenteredTimer || isEditingNotes)
    }
}

private extension SessionPhase {
    var isNotesWorkspacePhase: Bool {
        switch self {
        case .focusing, .focusPaused, .breakRunning, .breakPaused:
            true
        case .idle, .reflecting, .completed, .abandoned:
            false
        }
    }
}
