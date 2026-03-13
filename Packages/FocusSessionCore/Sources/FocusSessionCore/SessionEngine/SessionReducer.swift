import Foundation

public enum NotificationKind: Equatable, Sendable {
    case sessionEndingSoon
    case breakEndingSoon
}

public enum SessionSideEffect: Equatable, Sendable {
    case persistSnapshot
    case activateBlocker
    case deactivateBlocker
    case refreshMenubar
    case scheduleNotification(NotificationKind)
}

public struct SessionTransition: Equatable, Sendable {
    public var effects: [SessionSideEffect]

    public init(effects: [SessionSideEffect]) {
        self.effects = effects
    }
}

public enum SessionReducerError: Error, Equatable {
    case invalidTransition(phase: SessionPhase, event: SessionEvent)
}

public enum SessionReducer {
    public static func reduce(
        state: inout SessionState,
        event: SessionEvent
    ) throws -> SessionTransition {
        switch (state.phase, event) {
        case (.idle, let .startSession(intention, durationSeconds)):
            state.phase = .focusing
            state.snapshot = ActiveSessionSnapshot(
                intention: intention,
                plannedDurationSeconds: durationSeconds
            )
            return SessionTransition(effects: [.persistSnapshot, .activateBlocker, .refreshMenubar])

        case (.focusing, .pause):
            state.phase = .focusPaused
            return SessionTransition(effects: [.refreshMenubar, .persistSnapshot])

        case (.focusPaused, .resume):
            state.phase = .focusing
            return SessionTransition(effects: [.refreshMenubar, .persistSnapshot])

        case (.focusing, .finishFocus), (.focusPaused, .finishFocus):
            state.phase = .reflecting
            state.snapshot = nil
            return SessionTransition(effects: [.deactivateBlocker, .refreshMenubar, .persistSnapshot])

        case (.reflecting, .submitReflection):
            state.phase = .completed
            state.snapshot = nil
            return SessionTransition(effects: [.refreshMenubar, .persistSnapshot])

        case (.focusing, .abandon), (.focusPaused, .abandon), (.breakRunning, .abandon), (.breakPaused, .abandon):
            state.phase = .abandoned
            state.snapshot = nil
            return SessionTransition(effects: [.deactivateBlocker, .refreshMenubar, .persistSnapshot])

        case (.focusing, let .extend(minutes)):
            guard var snapshot = state.snapshot else {
                throw SessionReducerError.invalidTransition(phase: state.phase, event: event)
            }
            snapshot.plannedDurationSeconds += minutes * 60
            state.snapshot = snapshot
            return SessionTransition(effects: [.persistSnapshot, .refreshMenubar])

        default:
            throw SessionReducerError.invalidTransition(phase: state.phase, event: event)
        }
    }
}
