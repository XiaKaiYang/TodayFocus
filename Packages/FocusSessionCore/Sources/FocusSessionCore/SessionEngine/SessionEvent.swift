import Foundation

public enum SessionEvent: Equatable, Sendable {
    case startSession(intention: String, durationSeconds: Int)
    case pause
    case resume
    case finishFocus
    case submitReflection
    case startBreak(durationSeconds: Int)
    case skipBreak
    case finishBreak
    case abandon
    case extend(minutes: Int)
}
