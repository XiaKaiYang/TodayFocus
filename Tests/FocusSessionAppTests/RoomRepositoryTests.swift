import XCTest
@testable import FocusSession

@MainActor
final class RoomRepositoryTests: XCTestCase {
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
}
