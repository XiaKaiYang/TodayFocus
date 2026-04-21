import CloudKit
import Foundation

protocol LeaderboardRepositoryProtocol: Sendable {
    func fetchBuckets(roomID: String, period: LeaderboardPeriod, periodKey: String) async throws -> [LeaderboardBucketRecord]
    func upsertBucket(_ bucket: LeaderboardBucketRecord) async throws
}

final class LeaderboardRepository: LeaderboardRepositoryProtocol, @unchecked Sendable {
    private let databaseProvider: @Sendable () -> CKDatabase
    private var database: CKDatabase { databaseProvider() }

    init(databaseProvider: @escaping @Sendable () -> CKDatabase = {
        CKContainer(identifier: "iCloud.com.example.FocusSession").publicCloudDatabase
    }) {
        self.databaseProvider = databaseProvider
    }

    func fetchBuckets(roomID: String, period: LeaderboardPeriod, periodKey: String) async throws -> [LeaderboardBucketRecord] {
        let predicate = NSPredicate(
            format: "roomID == %@ AND period == %@ AND periodKey == %@",
            roomID, period.rawValue, periodKey
        )
        let query = CKQuery(recordType: LeaderboardBucketRecord.recordType, predicate: predicate)
        let (results, _) = try await database.records(matching: query, desiredKeys: nil)
        return results.compactMap { _, result in
            try? result.get()
        }.compactMap(LeaderboardBucketRecord.init(ckRecord:))
    }

    func upsertBucket(_ bucket: LeaderboardBucketRecord) async throws {
        let ckRecord = bucket.toCKRecord()
        try await database.save(ckRecord)
    }
}

final class StubLeaderboardRepository: LeaderboardRepositoryProtocol, @unchecked Sendable {
    var buckets: [LeaderboardBucketRecord] = []

    func fetchBuckets(roomID: String, period: LeaderboardPeriod, periodKey: String) async throws -> [LeaderboardBucketRecord] {
        buckets.filter { $0.roomID == roomID && $0.period == period && $0.periodKey == periodKey }
    }

    func upsertBucket(_ bucket: LeaderboardBucketRecord) async throws {
        if let idx = buckets.firstIndex(where: { $0.bucketID == bucket.bucketID }) {
            buckets[idx] = bucket
        } else {
            buckets.append(bucket)
        }
    }
}

extension LeaderboardRepository {
    static func dayKey(for date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    static func weekKey(for date: Date = Date()) -> String {
        let calendar = Calendar(identifier: .iso8601)
        let week = calendar.component(.weekOfYear, from: date)
        let year = calendar.component(.yearForWeekOfYear, from: date)
        return String(format: "%04d-W%02d", year, week)
    }
}
