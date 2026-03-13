import Foundation
import SwiftData
import FocusSessionCore

@MainActor
final class FocusSessionRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func save(_ record: FocusSessionRecord) throws {
        modelContext.insert(StoredFocusSessionRecord(record: record))
        try modelContext.save()
    }

    func fetchAll() throws -> [FocusSessionRecord] {
        var descriptor = FetchDescriptor<StoredFocusSessionRecord>(
            sortBy: [SortDescriptor(\.startedAt)]
        )
        descriptor.fetchLimit = 1000
        return try modelContext.fetch(descriptor).map(\.domainModel)
    }

    func delete(id: UUID) throws {
        let recordID = id
        let descriptor = FetchDescriptor<StoredFocusSessionRecord>(
            predicate: #Predicate<StoredFocusSessionRecord> { $0.id == recordID }
        )
        if let storedRecord = try modelContext.fetch(descriptor).first {
            modelContext.delete(storedRecord)
            try modelContext.save()
        }
    }

    func deleteAll() throws {
        let descriptor = FetchDescriptor<StoredFocusSessionRecord>()
        try modelContext.fetch(descriptor).forEach(modelContext.delete)
        try modelContext.save()
    }
}
