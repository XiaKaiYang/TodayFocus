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
        let profile = UserPublicProfileRecord(userID: "u1", displayName: "Alice")
        try await repo.upsert(profile)
        let fetched = try await repo.fetch(userID: "u1")
        XCTAssertEqual(fetched?.displayName, "Alice")
    }

    func testUpsertOverwritesExistingProfile() async throws {
        let repo = StubUserPublicProfileRepository()
        var profile = UserPublicProfileRecord(userID: "u1", displayName: "Alice")
        try await repo.upsert(profile)
        profile.totalWins = 5
        try await repo.upsert(profile)
        let fetched = try await repo.fetch(userID: "u1")
        XCTAssertEqual(fetched?.totalWins, 5)
    }
}
