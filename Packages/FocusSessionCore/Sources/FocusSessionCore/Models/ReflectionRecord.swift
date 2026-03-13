import Foundation

public enum SessionReflectionMood: String, Codable, Equatable, Sendable, CaseIterable {
    case focused
    case neutral
    case distracted
}

public typealias ReflectionMood = SessionReflectionMood

public struct ReflectionRecord: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var focusSessionID: UUID
    public var mood: SessionReflectionMood
    public var notes: String
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        focusSessionID: UUID,
        mood: SessionReflectionMood,
        notes: String = "",
        createdAt: Date = .now
    ) {
        self.id = id
        self.focusSessionID = focusSessionID
        self.mood = mood
        self.notes = notes
        self.createdAt = createdAt
    }
}
