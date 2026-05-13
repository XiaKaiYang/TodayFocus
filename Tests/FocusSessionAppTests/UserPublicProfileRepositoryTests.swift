import XCTest
@testable import FocusSession

@MainActor
final class UserPublicProfileRepositoryTests: XCTestCase {
    func testUserPublicProfileRepositoryDefaultsToPublicCloudDatabaseScope() {
        let repo = UserPublicProfileRepository()

        XCTAssertEqual(repo.databaseScope, .public)
    }

    func testFetchReturnsNilForMissingProfile() async throws {
        let repo = StubUserPublicProfileRepository()
        let result = try await repo.fetch(userID: "missing")
        XCTAssertNil(result)
    }

    func testUpsertAndFetchRoundTrips() async throws {
        let repo = StubUserPublicProfileRepository()
        let profile = UserPublicProfileRecord(userID: "u1", displayName: "Alice", bio: "想把专注系统搭成长期作品。")
        try await repo.upsert(profile)
        let fetched = try await repo.fetch(userID: "u1")
        XCTAssertEqual(fetched?.displayName, "Alice")
        XCTAssertEqual(fetched?.bio, "想把专注系统搭成长期作品。")
    }

    func testUpsertOverwritesExistingProfile() async throws {
        let repo = StubUserPublicProfileRepository()
        var profile = UserPublicProfileRecord(userID: "u1", displayName: "Alice")
        try await repo.upsert(profile)
        profile.totalWins = 5
        profile.bio = "持续打磨对战体验。"
        try await repo.upsert(profile)
        let fetched = try await repo.fetch(userID: "u1")
        XCTAssertEqual(fetched?.totalWins, 5)
        XCTAssertEqual(fetched?.bio, "持续打磨对战体验。")
    }
}
