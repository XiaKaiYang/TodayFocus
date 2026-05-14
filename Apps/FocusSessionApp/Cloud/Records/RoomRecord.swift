import CloudKit
import Foundation

struct RoomRecord: Equatable, Sendable {
    static let recordType = "Room"

    var roomID: String
    var ownerUserID: String
    var title: String
    var inviteCode: String
    var status: RoomStatus
    var plannedMinutes: Int
    let createdAt: Date
    var startedAt: Date?
    var endedAt: Date?
    var currentSessionID: String?

    init(
        roomID: String = UUID().uuidString,
        ownerUserID: String,
        title: String,
        plannedMinutes: Int,
        inviteCode: String? = nil,
        status: RoomStatus = .lobby,
        createdAt: Date = Date()
    ) {
        self.roomID = roomID
        self.ownerUserID = ownerUserID
        self.title = title
        self.plannedMinutes = plannedMinutes
        self.inviteCode = inviteCode ?? Self.generateInviteCode()
        self.status = status
        self.createdAt = createdAt
        self.startedAt = nil
        self.endedAt = nil
        self.currentSessionID = nil
    }

    init?(ckRecord: CKRecord) {
        guard
            let roomID = ckRecord["roomID"] as? String,
            let ownerUserID = ckRecord["ownerUserID"] as? String,
            let title = ckRecord["title"] as? String,
            let inviteCode = ckRecord["inviteCode"] as? String,
            let statusRaw = ckRecord["status"] as? String,
            let status = RoomStatus(rawValue: statusRaw),
            let plannedMinutes = ckRecord["plannedMinutes"] as? Int
        else { return nil }

        self.roomID = roomID
        self.ownerUserID = ownerUserID
        self.title = title
        self.inviteCode = inviteCode
        self.status = status
        self.plannedMinutes = plannedMinutes
        self.createdAt = ckRecord.creationDate ?? Date()
        self.startedAt = ckRecord["startedAt"] as? Date
        self.endedAt = ckRecord["endedAt"] as? Date
        self.currentSessionID = ckRecord["currentSessionID"] as? String
    }

    func toCKRecord() -> CKRecord {
        let recordID = CKRecord.ID(recordName: roomID)
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)
        record["roomID"] = roomID as CKRecordValue
        record["ownerUserID"] = ownerUserID as CKRecordValue
        record["title"] = title as CKRecordValue
        record["inviteCode"] = inviteCode as CKRecordValue
        record["status"] = status.rawValue as CKRecordValue
        record["plannedMinutes"] = plannedMinutes as CKRecordValue
        if let startedAt { record["startedAt"] = startedAt as CKRecordValue }
        if let endedAt { record["endedAt"] = endedAt as CKRecordValue }
        if let currentSessionID { record["currentSessionID"] = currentSessionID as CKRecordValue }
        return record
    }

    private static func generateInviteCode() -> String {
        let chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<6).map { _ in chars.randomElement()! })
    }
}
