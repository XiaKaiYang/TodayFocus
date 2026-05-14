import CloudKit
import Foundation

enum LeaderboardPeriod: String, Equatable, Sendable {
    case daily
    case weekly
}

struct LeaderboardBucketRecord: Equatable, Sendable {
    static let recordType = "LeaderboardBucket"

    var bucketID: String
    var roomID: String
    var userID: String
    var period: LeaderboardPeriod
    var periodKey: String       // e.g. "2024-01-15" or "2024-W03"
    var focusMinutes: Int
    var violationCount: Int
    var sessionCount: Int
    var updatedAt: Date

    init(
        bucketID: String = UUID().uuidString,
        roomID: String,
        userID: String,
        period: LeaderboardPeriod,
        periodKey: String,
        focusMinutes: Int = 0,
        violationCount: Int = 0,
        sessionCount: Int = 0,
        updatedAt: Date = Date()
    ) {
        self.bucketID = bucketID
        self.roomID = roomID
        self.userID = userID
        self.period = period
        self.periodKey = periodKey
        self.focusMinutes = focusMinutes
        self.violationCount = violationCount
        self.sessionCount = sessionCount
        self.updatedAt = updatedAt
    }

    init?(ckRecord: CKRecord) {
        guard
            let bucketID = ckRecord["bucketID"] as? String,
            let roomID = ckRecord["roomID"] as? String,
            let userID = ckRecord["userID"] as? String,
            let periodRaw = ckRecord["period"] as? String,
            let period = LeaderboardPeriod(rawValue: periodRaw),
            let periodKey = ckRecord["periodKey"] as? String,
            let focusMinutes = ckRecord["focusMinutes"] as? Int,
            let updatedAt = ckRecord["updatedAt"] as? Date
        else { return nil }

        self.bucketID = bucketID
        self.roomID = roomID
        self.userID = userID
        self.period = period
        self.periodKey = periodKey
        self.focusMinutes = focusMinutes
        self.violationCount = ckRecord["violationCount"] as? Int ?? 0
        self.sessionCount = ckRecord["sessionCount"] as? Int ?? 0
        self.updatedAt = updatedAt
    }

    func toCKRecord() -> CKRecord {
        let recordID = CKRecord.ID(recordName: bucketID)
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)
        record["bucketID"] = bucketID as CKRecordValue
        record["roomID"] = roomID as CKRecordValue
        record["userID"] = userID as CKRecordValue
        record["period"] = period.rawValue as CKRecordValue
        record["periodKey"] = periodKey as CKRecordValue
        record["focusMinutes"] = focusMinutes as CKRecordValue
        record["violationCount"] = violationCount as CKRecordValue
        record["sessionCount"] = sessionCount as CKRecordValue
        record["updatedAt"] = updatedAt as CKRecordValue
        return record
    }
}
