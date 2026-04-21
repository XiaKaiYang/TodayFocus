import CloudKit
import Foundation

struct UserPublicProfileRecord: Equatable, Sendable {
    static let recordType = "UserPublicProfile"

    var userID: String
    var displayName: String
    var totalVerifiedMinutes: Int
    var totalWins: Int
    var totalPenaltyCount: Int
    var lastLeaderboardScore: Double
    let createdAt: Date

    init(userID: String, displayName: String, createdAt: Date = Date()) {
        self.userID = userID
        self.displayName = displayName
        self.totalVerifiedMinutes = 0
        self.totalWins = 0
        self.totalPenaltyCount = 0
        self.lastLeaderboardScore = 0
        self.createdAt = createdAt
    }

    init?(ckRecord: CKRecord) {
        guard
            let userID = ckRecord["userID"] as? String,
            let displayName = ckRecord["displayName"] as? String
        else { return nil }

        self.userID = userID
        self.displayName = displayName
        self.totalVerifiedMinutes = ckRecord["totalVerifiedMinutes"] as? Int ?? 0
        self.totalWins = ckRecord["totalWins"] as? Int ?? 0
        self.totalPenaltyCount = ckRecord["totalPenaltyCount"] as? Int ?? 0
        self.lastLeaderboardScore = ckRecord["lastLeaderboardScore"] as? Double ?? 0
        self.createdAt = ckRecord.creationDate ?? Date()
    }

    func toCKRecord() -> CKRecord {
        let recordID = CKRecord.ID(recordName: userID)
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)
        record["userID"] = userID as CKRecordValue
        record["displayName"] = displayName as CKRecordValue
        record["totalVerifiedMinutes"] = totalVerifiedMinutes as CKRecordValue
        record["totalWins"] = totalWins as CKRecordValue
        record["totalPenaltyCount"] = totalPenaltyCount as CKRecordValue
        record["lastLeaderboardScore"] = lastLeaderboardScore as CKRecordValue
        return record
    }
}
