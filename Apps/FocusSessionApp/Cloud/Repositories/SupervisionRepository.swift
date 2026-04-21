import CloudKit
import Foundation

protocol SupervisionRepositoryProtocol: Sendable {
    func recordViolation(_ event: ViolationEventRecord) async throws
    func uploadEvidence(_ evidence: ViolationEvidenceRecord) async throws
    func uploadState(_ state: SupervisionStateRecord) async throws
    func fetchViolations(sessionID: String) async throws -> [ViolationEventRecord]
}

final class SupervisionRepository: SupervisionRepositoryProtocol, @unchecked Sendable {
    private let databaseProvider: @Sendable () -> CKDatabase
    private var database: CKDatabase { databaseProvider() }

    init(databaseProvider: @escaping @Sendable () -> CKDatabase = {
        CKContainer(identifier: "iCloud.com.example.FocusSession").publicCloudDatabase
    }) {
        self.databaseProvider = databaseProvider
    }

    func recordViolation(_ event: ViolationEventRecord) async throws {
        let ckRecord = event.toCKRecord()
        try await database.save(ckRecord)
    }

    func uploadEvidence(_ evidence: ViolationEvidenceRecord) async throws {
        let ckRecord = evidence.toCKRecord()
        try await database.save(ckRecord)
    }

    func uploadState(_ state: SupervisionStateRecord) async throws {
        let ckRecord = state.toCKRecord()
        try await database.save(ckRecord)
    }

    func fetchViolations(sessionID: String) async throws -> [ViolationEventRecord] {
        let predicate = NSPredicate(format: "sessionID == %@", sessionID)
        let query = CKQuery(recordType: ViolationEventRecord.recordType, predicate: predicate)
        let (results, _) = try await database.records(matching: query, desiredKeys: nil)
        return results.compactMap { _, result in
            try? result.get()
        }.compactMap(ViolationEventRecord.init(ckRecord:))
    }
}

final class StubSupervisionRepository: SupervisionRepositoryProtocol, @unchecked Sendable {
    var violations: [ViolationEventRecord] = []
    var evidences: [ViolationEvidenceRecord] = []
    var states: [SupervisionStateRecord] = []

    func recordViolation(_ event: ViolationEventRecord) async throws {
        violations.append(event)
    }

    func uploadEvidence(_ evidence: ViolationEvidenceRecord) async throws {
        evidences.append(evidence)
    }

    func uploadState(_ state: SupervisionStateRecord) async throws {
        states.append(state)
    }

    func fetchViolations(sessionID: String) async throws -> [ViolationEventRecord] {
        violations.filter { $0.sessionID == sessionID }
    }
}
