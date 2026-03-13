import Foundation

public struct BreakRecord: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var parentSessionID: UUID?
    public var startedAt: Date
    public var endedAt: Date
    public var wasSkipped: Bool

    public var durationSeconds: Int {
        max(0, Int(endedAt.timeIntervalSince(startedAt)))
    }

    public init(
        id: UUID = UUID(),
        parentSessionID: UUID? = nil,
        startedAt: Date,
        endedAt: Date,
        wasSkipped: Bool = false
    ) {
        self.id = id
        self.parentSessionID = parentSessionID
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.wasSkipped = wasSkipped
    }
}
