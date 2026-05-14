import CloudKit
import Foundation

enum ViolationType: String, Equatable, Sendable, CaseIterable {
    case seatAbsence
    case inactivity
    case tabSwitching
    case appSwitch
}

struct ViolationEventRecord: Equatable, Sendable {
    static let recordType = "ViolationEvent"

    var eventID: String
    var sessionID: String
    var roomID: String
    var userID: String
    var violationType: ViolationType
    var occurredAt: Date
    var evidenceURL: String?

    init(
        eventID: String = UUID().uuidString,
        sessionID: String,
        roomID: String,
        userID: String,
        violationType: ViolationType,
        occurredAt: Date = Date(),
        evidenceURL: String? = nil
    ) {
        self.eventID = eventID
        self.sessionID = sessionID
        self.roomID = roomID
        self.userID = userID
        self.violationType = violationType
        self.occurredAt = occurredAt
        self.evidenceURL = evidenceURL
    }

    init?(ckRecord: CKRecord) {
        guard
            let eventID = ckRecord["eventID"] as? String,
            let sessionID = ckRecord["sessionID"] as? String,
            let roomID = ckRecord["roomID"] as? String,
            let userID = ckRecord["userID"] as? String,
            let typeRaw = ckRecord["violationType"] as? String,
            let violationType = ViolationType(rawValue: typeRaw),
            let occurredAt = ckRecord["occurredAt"] as? Date
        else { return nil }

        self.eventID = eventID
        self.sessionID = sessionID
        self.roomID = roomID
        self.userID = userID
        self.violationType = violationType
        self.occurredAt = occurredAt
        self.evidenceURL = ckRecord["evidenceURL"] as? String
    }

    func toCKRecord() -> CKRecord {
        let recordID = CKRecord.ID(recordName: eventID)
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)
        record["eventID"] = eventID as CKRecordValue
        record["sessionID"] = sessionID as CKRecordValue
        record["roomID"] = roomID as CKRecordValue
        record["userID"] = userID as CKRecordValue
        record["violationType"] = violationType.rawValue as CKRecordValue
        record["occurredAt"] = occurredAt as CKRecordValue
        if let evidenceURL { record["evidenceURL"] = evidenceURL as CKRecordValue }
        return record
    }
}
