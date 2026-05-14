import CloudKit
import Foundation

struct PKSessionRecord: Equatable, Sendable {
    static let recordType = "PKSession"

    var sessionID: String
    var roomID: String
    var startAt: Date
    var plannedMinutes: Int
    var endAt: Date?
    var status: PKSessionStatus
    var winnerUserID: String?
    var scoreVersion: Int

    init(
        sessionID: String = UUID().uuidString,
        roomID: String,
        plannedMinutes: Int,
        startAt: Date = Date(),
        status: PKSessionStatus = .running,
        scoreVersion: Int = 1
    ) {
        self.sessionID = sessionID
        self.roomID = roomID
        self.startAt = startAt
        self.plannedMinutes = plannedMinutes
        self.endAt = nil
        self.status = status
        self.winnerUserID = nil
        self.scoreVersion = scoreVersion
    }

    init?(ckRecord: CKRecord) {
        guard
            let sessionID = ckRecord["sessionID"] as? String,
            let roomID = ckRecord["roomID"] as? String,
            let startAt = ckRecord["startAt"] as? Date,
            let plannedMinutes = ckRecord["plannedMinutes"] as? Int,
            let statusRaw = ckRecord["status"] as? String,
            let status = PKSessionStatus(rawValue: statusRaw)
        else { return nil }

        self.sessionID = sessionID
        self.roomID = roomID
        self.startAt = startAt
        self.plannedMinutes = plannedMinutes
        self.status = status
        self.endAt = ckRecord["endAt"] as? Date
        self.winnerUserID = ckRecord["winnerUserID"] as? String
        self.scoreVersion = ckRecord["scoreVersion"] as? Int ?? 1
    }

    func toCKRecord() -> CKRecord {
        let recordID = CKRecord.ID(recordName: sessionID)
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)
        record["sessionID"] = sessionID as CKRecordValue
        record["roomID"] = roomID as CKRecordValue
        record["startAt"] = startAt as CKRecordValue
        record["plannedMinutes"] = plannedMinutes as CKRecordValue
        record["status"] = status.rawValue as CKRecordValue
        record["scoreVersion"] = scoreVersion as CKRecordValue
        if let endAt { record["endAt"] = endAt as CKRecordValue }
        if let winnerUserID { record["winnerUserID"] = winnerUserID as CKRecordValue }
        return record
    }
}
