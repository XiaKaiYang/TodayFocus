import CloudKit
import Foundation

struct RoomMemberRecord: Equatable, Sendable {
    static let recordType = "RoomMember"

    var roomID: String
    var userID: String
    var role: MemberRole
    var joinState: MemberJoinState
    var readyState: MemberReadyState
    var lastHeartbeatAt: Date?
    var currentSeatState: SeatState
    var currentActivityState: ActivityState
    var sessionScore: Double

    init(
        roomID: String,
        userID: String,
        role: MemberRole,
        joinState: MemberJoinState = .joined,
        readyState: MemberReadyState = .notReady,
        currentSeatState: SeatState = .unknown,
        currentActivityState: ActivityState = .unknown,
        sessionScore: Double = 0
    ) {
        self.roomID = roomID
        self.userID = userID
        self.role = role
        self.joinState = joinState
        self.readyState = readyState
        self.lastHeartbeatAt = nil
        self.currentSeatState = currentSeatState
        self.currentActivityState = currentActivityState
        self.sessionScore = sessionScore
    }

    init?(ckRecord: CKRecord) {
        guard
            let roomID = ckRecord["roomID"] as? String,
            let userID = ckRecord["userID"] as? String,
            let roleRaw = ckRecord["role"] as? String,
            let role = MemberRole(rawValue: roleRaw),
            let joinStateRaw = ckRecord["joinState"] as? String,
            let joinState = MemberJoinState(rawValue: joinStateRaw),
            let readyStateRaw = ckRecord["readyState"] as? String,
            let readyState = MemberReadyState(rawValue: readyStateRaw)
        else { return nil }

        self.roomID = roomID
        self.userID = userID
        self.role = role
        self.joinState = joinState
        self.readyState = readyState
        self.lastHeartbeatAt = ckRecord["lastHeartbeatAt"] as? Date
        self.currentSeatState = SeatState(rawValue: ckRecord["currentSeatState"] as? String ?? "") ?? .unknown
        self.currentActivityState = ActivityState(rawValue: ckRecord["currentActivityState"] as? String ?? "") ?? .unknown
        self.sessionScore = ckRecord["sessionScore"] as? Double ?? 0
    }

    func toCKRecord() -> CKRecord {
        let recordName = "\(roomID)_\(userID)"
        let recordID = CKRecord.ID(recordName: recordName)
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)

        let roomRecordID = CKRecord.ID(recordName: roomID)
        record["room"] = CKRecord.Reference(recordID: roomRecordID, action: .deleteSelf)
        record["roomID"] = roomID as CKRecordValue
        record["userID"] = userID as CKRecordValue
        record["role"] = role.rawValue as CKRecordValue
        record["joinState"] = joinState.rawValue as CKRecordValue
        record["readyState"] = readyState.rawValue as CKRecordValue
        record["currentSeatState"] = currentSeatState.rawValue as CKRecordValue
        record["currentActivityState"] = currentActivityState.rawValue as CKRecordValue
        record["sessionScore"] = sessionScore as CKRecordValue
        if let lastHeartbeatAt { record["lastHeartbeatAt"] = lastHeartbeatAt as CKRecordValue }
        return record
    }
}
