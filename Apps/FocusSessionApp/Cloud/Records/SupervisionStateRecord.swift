import CloudKit
import Foundation

struct SupervisionStateRecord: Equatable, Sendable {
    static let recordType = "SupervisionState"

    var recordID: String
    var sessionID: String
    var roomID: String
    var userID: String
    var seatStateRaw: String
    var activityStateRaw: String
    var lastSeatChangeAt: Date
    var lastActiveAt: Date
    var uploadedAt: Date
    var clientModelVersion: Int

    init(
        recordID: String = UUID().uuidString,
        sessionID: String,
        roomID: String,
        userID: String,
        seatStateRaw: String,
        activityStateRaw: String,
        lastSeatChangeAt: Date,
        lastActiveAt: Date,
        uploadedAt: Date = Date(),
        clientModelVersion: Int = 1
    ) {
        self.recordID = recordID
        self.sessionID = sessionID
        self.roomID = roomID
        self.userID = userID
        self.seatStateRaw = seatStateRaw
        self.activityStateRaw = activityStateRaw
        self.lastSeatChangeAt = lastSeatChangeAt
        self.lastActiveAt = lastActiveAt
        self.uploadedAt = uploadedAt
        self.clientModelVersion = clientModelVersion
    }

    init?(ckRecord: CKRecord) {
        guard
            let recordID = ckRecord["recordID"] as? String,
            let sessionID = ckRecord["sessionID"] as? String,
            let roomID = ckRecord["roomID"] as? String,
            let userID = ckRecord["userID"] as? String,
            let seatStateRaw = ckRecord["seatStateRaw"] as? String,
            let activityStateRaw = ckRecord["activityStateRaw"] as? String,
            let lastSeatChangeAt = ckRecord["lastSeatChangeAt"] as? Date,
            let lastActiveAt = ckRecord["lastActiveAt"] as? Date,
            let uploadedAt = ckRecord["uploadedAt"] as? Date
        else { return nil }

        self.recordID = recordID
        self.sessionID = sessionID
        self.roomID = roomID
        self.userID = userID
        self.seatStateRaw = seatStateRaw
        self.activityStateRaw = activityStateRaw
        self.lastSeatChangeAt = lastSeatChangeAt
        self.lastActiveAt = lastActiveAt
        self.uploadedAt = uploadedAt
        self.clientModelVersion = ckRecord["clientModelVersion"] as? Int ?? 1
    }

    func toCKRecord() -> CKRecord {
        let recordCKID = CKRecord.ID(recordName: recordID)
        let record = CKRecord(recordType: Self.recordType, recordID: recordCKID)
        record["recordID"] = recordID as CKRecordValue
        record["sessionID"] = sessionID as CKRecordValue
        record["roomID"] = roomID as CKRecordValue
        record["userID"] = userID as CKRecordValue
        record["seatStateRaw"] = seatStateRaw as CKRecordValue
        record["activityStateRaw"] = activityStateRaw as CKRecordValue
        record["lastSeatChangeAt"] = lastSeatChangeAt as CKRecordValue
        record["lastActiveAt"] = lastActiveAt as CKRecordValue
        record["uploadedAt"] = uploadedAt as CKRecordValue
        record["clientModelVersion"] = clientModelVersion as CKRecordValue
        return record
    }
}
