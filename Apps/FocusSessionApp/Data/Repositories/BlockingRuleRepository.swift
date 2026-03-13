import Foundation
import SwiftData
import FocusSessionCore

@MainActor
final class BlockingRuleRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func save(_ rule: BlockingRule) throws {
        modelContext.insert(StoredBlockingRule(rule: rule))
        try modelContext.save()
    }

    func delete(id: UUID) throws {
        let descriptor = FetchDescriptor<StoredBlockingRule>(
            predicate: #Predicate { $0.id == id }
        )
        if let storedRule = try modelContext.fetch(descriptor).first {
            modelContext.delete(storedRule)
            try modelContext.save()
        }
    }

    func fetchAll() throws -> [BlockingRule] {
        let descriptor = FetchDescriptor<StoredBlockingRule>(
            sortBy: [SortDescriptor(\.targetValue)]
        )
        return try modelContext.fetch(descriptor).map(\.domainModel)
    }

    func deleteAll() throws {
        let descriptor = FetchDescriptor<StoredBlockingRule>()
        try modelContext.fetch(descriptor).forEach(modelContext.delete)
        try modelContext.save()
    }
}
