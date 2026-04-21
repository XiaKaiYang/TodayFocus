import XCTest
@testable import FocusSession

@MainActor
final class LeaderboardViewModelTests: XCTestCase {
    func testLoadPopulatesDailyEntries() async {
        let repo = StubLeaderboardRepository()
        let dayKey = LeaderboardRepository.dayKey()
        try? await repo.upsertBucket(LeaderboardBucketRecord(
            roomID: "r1",
            userID: "u1",
            period: .daily,
            periodKey: dayKey,
            focusMinutes: 60
        ))
        let vm = LeaderboardViewModel(repository: repo)
        await vm.load(roomID: "r1")
        XCTAssertEqual(vm.dailyEntries.count, 1)
        XCTAssertEqual(vm.dailyEntries.first?.focusMinutes, 60)
    }

    func testLoadSortsByFocusMinutesDescending() async {
        let repo = StubLeaderboardRepository()
        let dayKey = LeaderboardRepository.dayKey()
        try? await repo.upsertBucket(LeaderboardBucketRecord(
            roomID: "r1", userID: "u1", period: .daily, periodKey: dayKey, focusMinutes: 30
        ))
        try? await repo.upsertBucket(LeaderboardBucketRecord(
            roomID: "r1", userID: "u2", period: .daily, periodKey: dayKey, focusMinutes: 90
        ))
        let vm = LeaderboardViewModel(repository: repo)
        await vm.load(roomID: "r1")
        XCTAssertEqual(vm.dailyEntries.first?.focusMinutes, 90)
        XCTAssertEqual(vm.dailyEntries.last?.focusMinutes, 30)
    }

    func testLoadSetsErrorOnFailure() async {
        let repo = FailingLeaderboardRepository()
        let vm = LeaderboardViewModel(repository: repo)
        await vm.load(roomID: "r1")
        XCTAssertNotNil(vm.errorMessage)
        XCTAssertTrue(vm.dailyEntries.isEmpty)
    }

    func testDayKeyFormat() {
        let key = LeaderboardRepository.dayKey(for: Date(timeIntervalSince1970: 0))
        XCTAssertEqual(key, "1970-01-01")
    }

    func testWeekKeyFormat() {
        // 1970-01-01 is week 1 of 1970
        let key = LeaderboardRepository.weekKey(for: Date(timeIntervalSince1970: 0))
        XCTAssertTrue(key.hasPrefix("1970-W"))
    }
}

private final class FailingLeaderboardRepository: LeaderboardRepositoryProtocol, @unchecked Sendable {
    func fetchBuckets(roomID: String, period: LeaderboardPeriod, periodKey: String) async throws -> [LeaderboardBucketRecord] {
        throw NSError(domain: "test", code: 1)
    }
    func upsertBucket(_ bucket: LeaderboardBucketRecord) async throws {
        throw NSError(domain: "test", code: 1)
    }
}
