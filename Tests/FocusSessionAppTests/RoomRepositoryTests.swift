import XCTest
@testable import FocusSession

@MainActor
final class RoomRepositoryTests: XCTestCase {
    func testRoomRepositoryDefaultsToPrivateCloudDatabaseScope() {
        let repo = RoomRepository()

        XCTAssertEqual(repo.databaseScope, .private)
    }

    func testCreateRoomStoresRecord() async throws {
        let repo = StubRoomRepository()
        let room = RoomRecord(roomID: "r1", ownerUserID: "u1", title: "Deep Work", plannedMinutes: 25)
        try await repo.createRoom(room)
        let fetched = try await repo.fetchRoom(roomID: "r1")
        XCTAssertEqual(fetched?.title, "Deep Work")
    }

    func testFetchByInviteCodeReturnsCorrectRoom() async throws {
        let repo = StubRoomRepository()
        let room = RoomRecord(roomID: "r1", ownerUserID: "u1", title: "Room A", plannedMinutes: 25, inviteCode: "ABC123")
        try await repo.createRoom(room)
        let fetched = try await repo.fetchRoom(byInviteCode: "ABC123")
        XCTAssertEqual(fetched?.roomID, "r1")
    }

    func testUpsertMemberAndFetch() async throws {
        let repo = StubRoomRepository()
        let member = RoomMemberRecord(roomID: "r1", userID: "u1", role: .owner)
        try await repo.upsertMember(member)
        let members = try await repo.fetchMembers(roomID: "r1")
        XCTAssertEqual(members.count, 1)
        XCTAssertEqual(members.first?.userID, "u1")
    }

    func testSetMemberReadyState() async throws {
        let repo = StubRoomRepository()
        var member = RoomMemberRecord(roomID: "r1", userID: "u1", role: .member)
        try await repo.upsertMember(member)
        member.readyState = .ready
        try await repo.upsertMember(member)
        let members = try await repo.fetchMembers(roomID: "r1")
        XCTAssertEqual(members.first?.readyState, .ready)
    }

    func testCreateRoomSurfacesErrorWhenCloudKitUnavailable() async {
        let pkRepo = StubPKSessionRepository()
        let accountService = StubAccountService()
        accountService.stubbedIdentity = AccountIdentity(userID: "u1", displayName: "Alice", email: nil)
        let accountVM = AccountViewModel(accountService: accountService, profileRepository: StubUserPublicProfileRepository())
        await accountVM.restoreSession()
        let vm = RoomLobbyViewModel(
            roomRepository: FailingRoomRepository(),
            pkSessionRepository: pkRepo,
            accountViewModel: accountVM
        )

        await vm.createRoom(title: "Cloud Down", plannedMinutes: 25)

        XCTAssertNil(vm.currentRoom)
        XCTAssertEqual(vm.errorMessage, "CloudKit is unavailable in this build.")
    }
}

private final class FailingRoomRepository: RoomRepositoryProtocol, @unchecked Sendable {
    func createRoom(_ room: RoomRecord) async throws { throw CloudKitDatabaseProviderError.unavailable }
    func fetchRoom(byInviteCode code: String) async throws -> RoomRecord? { throw CloudKitDatabaseProviderError.unavailable }
    func fetchRoom(roomID: String) async throws -> RoomRecord? { throw CloudKitDatabaseProviderError.unavailable }
    func updateRoom(_ room: RoomRecord) async throws { throw CloudKitDatabaseProviderError.unavailable }
    func upsertMember(_ member: RoomMemberRecord) async throws { throw CloudKitDatabaseProviderError.unavailable }
    func fetchMembers(roomID: String) async throws -> [RoomMemberRecord] { throw CloudKitDatabaseProviderError.unavailable }
}
