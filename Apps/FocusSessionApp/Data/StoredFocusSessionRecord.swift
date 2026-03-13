import Foundation
import SwiftData
import FocusSessionCore

@Model
final class StoredFocusSessionRecord {
    @Attribute(.unique) var id: UUID
    var intention: String
    var startedAt: Date
    var endedAt: Date
    var notes: String?
    var moodRawValue: String?
    var wasCompleted: Bool

    init(record: FocusSessionRecord) {
        self.id = record.id
        self.intention = record.intention
        self.startedAt = record.startedAt
        self.endedAt = record.endedAt
        self.notes = record.notes
        self.moodRawValue = record.mood?.rawValue
        self.wasCompleted = record.wasCompleted
    }

    var domainModel: FocusSessionRecord {
        FocusSessionRecord(
            id: id,
            intention: intention,
            startedAt: startedAt,
            endedAt: endedAt,
            notes: notes,
            mood: moodRawValue.flatMap(SessionReflectionMood.init(rawValue:)),
            wasCompleted: wasCompleted
        )
    }
}
