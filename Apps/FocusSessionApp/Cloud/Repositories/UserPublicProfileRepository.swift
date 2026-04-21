import CloudKit
import Foundation

protocol UserPublicProfileRepositoryProtocol: Sendable {
    func fetch(userID: String) async throws -> UserPublicProfileRecord?
    func upsert(_ record: UserPublicProfileRecord) async throws
}

final class UserPublicProfileRepository: UserPublicProfileRepositoryProtocol, @unchecked Sendable {
    let databaseScope: CKDatabase.Scope
    private let databaseProvider: @Sendable (CKDatabase.Scope) throws -> CKDatabase

    init(
        databaseScope: CKDatabase.Scope = .public,
        databaseProvider: @escaping @Sendable (CKDatabase.Scope) throws -> CKDatabase = CloudKitDatabaseProvider.makeDatabase
    ) {
        self.databaseScope = databaseScope
        self.databaseProvider = databaseProvider
    }

    func fetch(userID: String) async throws -> UserPublicProfileRecord? {
        let database = try databaseProvider(databaseScope)
        let recordID = CKRecord.ID(recordName: userID)
        do {
            let ckRecord = try await database.record(for: recordID)
            return UserPublicProfileRecord(ckRecord: ckRecord)
        } catch let error as CKError where error.code == .unknownItem {
            return nil
        }
    }

    func upsert(_ record: UserPublicProfileRecord) async throws {
        let database = try databaseProvider(databaseScope)
        let ckRecord = record.toCKRecord()
        try await database.save(ckRecord)
    }
}

final class StubUserPublicProfileRepository: UserPublicProfileRepositoryProtocol, @unchecked Sendable {
    var profiles: [String: UserPublicProfileRecord] = [:]

    func fetch(userID: String) async throws -> UserPublicProfileRecord? {
        profiles[userID]
    }

    func upsert(_ record: UserPublicProfileRecord) async throws {
        profiles[record.userID] = record
    }
}
