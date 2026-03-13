import Foundation

public struct FocusSessionRecord: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var intention: String
    public var startedAt: Date
    public var endedAt: Date
    public var notes: String?
    public var mood: SessionReflectionMood?
    public var wasCompleted: Bool

    public var durationSeconds: Int {
        max(0, Int(endedAt.timeIntervalSince(startedAt)))
    }

    public init(
        id: UUID = UUID(),
        intention: String = "",
        startedAt: Date,
        endedAt: Date,
        notes: String? = nil,
        mood: SessionReflectionMood? = nil,
        wasCompleted: Bool = true
    ) {
        self.id = id
        self.intention = intention
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.notes = notes
        self.mood = mood
        self.wasCompleted = wasCompleted
    }
}
