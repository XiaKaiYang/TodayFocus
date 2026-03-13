import Foundation

public enum SessionPhase: String, Codable, Equatable, Sendable {
    case idle
    case focusing
    case focusPaused
    case breakRunning
    case breakPaused
    case reflecting
    case completed
    case abandoned
}

public struct SessionState: Equatable, Sendable {
    public var phase: SessionPhase
    public var snapshot: ActiveSessionSnapshot?

    public init(phase: SessionPhase, snapshot: ActiveSessionSnapshot? = nil) {
        self.phase = phase
        self.snapshot = snapshot
    }

    public static let idle = SessionState(phase: .idle, snapshot: nil)
}
