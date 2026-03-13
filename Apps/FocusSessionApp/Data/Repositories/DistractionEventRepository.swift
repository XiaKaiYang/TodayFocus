import Foundation
import SwiftData
import FocusSessionCore

@MainActor
final class DistractionEventRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func save(_ event: DistractionEvent) throws {
        modelContext.insert(StoredDistractionEvent(event: event))
        try modelContext.save()
    }

    func fetchAll(limit: Int = 50) throws -> [DistractionEvent] {
        var descriptor = FetchDescriptor<StoredDistractionEvent>(
            sortBy: [SortDescriptor(\.occurredAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return try modelContext.fetch(descriptor).map(\.domainModel)
    }

    func deleteAll() throws {
        let descriptor = FetchDescriptor<StoredDistractionEvent>()
        try modelContext.fetch(descriptor).forEach(modelContext.delete)
        try modelContext.save()
    }
}
