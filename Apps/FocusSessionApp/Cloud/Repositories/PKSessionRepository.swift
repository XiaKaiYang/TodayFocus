import CloudKit
import Foundation

protocol PKSessionRepositoryProtocol: Sendable {
    func createSession(_ session: PKSessionRecord) async throws
    func fetchCurrentSession(roomID: String) async throws -> PKSessionRecord?
    func updateSession(_ session: PKSessionRecord) async throws
}

final class PKSessionRepository: PKSessionRepositoryProtocol, @unchecked Sendable {
    let databaseScope: CKDatabase.Scope
    private let databaseProvider: @Sendable (CKDatabase.Scope) throws -> CKDatabase

    init(
        databaseScope: CKDatabase.Scope = .private,
        databaseProvider: @escaping @Sendable (CKDatabase.Scope) throws -> CKDatabase = CloudKitDatabaseProvider.makeDatabase
    ) {
        self.databaseScope = databaseScope
        self.databaseProvider = databaseProvider
    }

    func createSession(_ session: PKSessionRecord) async throws {
        let database = try databaseProvider(databaseScope)
        let ckRecord = session.toCKRecord()
        try await database.save(ckRecord)
    }

    func fetchCurrentSession(roomID: String) async throws -> PKSessionRecord? {
        let database = try databaseProvider(databaseScope)
        let predicate = NSPredicate(format: "roomID == %@ AND status == %@", roomID, PKSessionStatus.running.rawValue)
        let query = CKQuery(recordType: PKSessionRecord.recordType, predicate: predicate)
        let (results, _) = try await database.records(matching: query, desiredKeys: nil)
        return results.compactMap { _, result in
            try? result.get()
        }.compactMap(PKSessionRecord.init(ckRecord:)).first
    }

    func updateSession(_ session: PKSessionRecord) async throws {
        let database = try databaseProvider(databaseScope)
        let ckRecord = session.toCKRecord()
        try await database.save(ckRecord)
    }
}

final class StubPKSessionRepository: PKSessionRepositoryProtocol, @unchecked Sendable {
    var sessions: [String: PKSessionRecord] = [:]

    func createSession(_ session: PKSessionRecord) async throws {
        sessions[session.sessionID] = session
    }

    func fetchCurrentSession(roomID: String) async throws -> PKSessionRecord? {
        sessions.values
            .filter { $0.roomID == roomID }
            .sorted { $0.startAt > $1.startAt }
            .first
    }

    func updateSession(_ session: PKSessionRecord) async throws {
        sessions[session.sessionID] = session
    }
}
