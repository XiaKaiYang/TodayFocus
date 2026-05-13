import CloudKit
import Foundation

struct ViolationEvidenceRecord: Equatable, Sendable {
    static let recordType = "ViolationEvidence"

    var evidenceID: String
    var eventID: String
    var sessionID: String
    var userID: String
    var capturedAt: Date
    var imageDataBase64: String?
    var clientModelVersion: Int

    init(
        evidenceID: String = UUID().uuidString,
        eventID: String,
        sessionID: String,
        userID: String,
        capturedAt: Date = Date(),
        imageDataBase64: String? = nil,
        clientModelVersion: Int = 1
    ) {
        self.evidenceID = evidenceID
        self.eventID = eventID
        self.sessionID = sessionID
        self.userID = userID
        self.capturedAt = capturedAt
        self.imageDataBase64 = imageDataBase64
        self.clientModelVersion = clientModelVersion
    }

    init?(ckRecord: CKRecord) {
        guard
            let evidenceID = ckRecord["evidenceID"] as? String,
            let eventID = ckRecord["eventID"] as? String,
            let sessionID = ckRecord["sessionID"] as? String,
            let userID = ckRecord["userID"] as? String,
            let capturedAt = ckRecord["capturedAt"] as? Date
        else { return nil }

        self.evidenceID = evidenceID
        self.eventID = eventID
        self.sessionID = sessionID
        self.userID = userID
        self.capturedAt = capturedAt
        self.imageDataBase64 = ckRecord["imageDataBase64"] as? String
        self.clientModelVersion = ckRecord["clientModelVersion"] as? Int ?? 1
    }

    func toCKRecord() -> CKRecord {
        let recordID = CKRecord.ID(recordName: evidenceID)
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)
        record["evidenceID"] = evidenceID as CKRecordValue
        record["eventID"] = eventID as CKRecordValue
        record["sessionID"] = sessionID as CKRecordValue
        record["userID"] = userID as CKRecordValue
        record["capturedAt"] = capturedAt as CKRecordValue
        record["clientModelVersion"] = clientModelVersion as CKRecordValue
        if let imageDataBase64 { record["imageDataBase64"] = imageDataBase64 as CKRecordValue }
        return record
    }
}
