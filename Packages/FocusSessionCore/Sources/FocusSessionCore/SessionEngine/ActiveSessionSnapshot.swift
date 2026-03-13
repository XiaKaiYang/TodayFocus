import Foundation

public struct ActiveSessionSnapshot: Codable, Equatable, Sendable {
    public var intention: String
    public var plannedDurationSeconds: Int
    public var startedAt: Date

    public init(
        intention: String,
        plannedDurationSeconds: Int,
        startedAt: Date = .now
    ) {
        self.intention = intention
        self.plannedDurationSeconds = plannedDurationSeconds
        self.startedAt = startedAt
    }
}
