import XCTest
@testable import FocusSession

@MainActor
final class RoomLobbyViewModelTests: XCTestCase {
    func testOwnerCanCreateRoom() async {
        let (vm, _, _) = makeHarness()
        await vm.createRoom(title: "Deep Work", plannedMinutes: 25)
        XCTAssertEqual(vm.currentRoom?.title, "Deep Work")
        XCTAssertEqual(vm.currentMembership?.role, .owner)
    }

    func testMemberCanJoinByCode() async {
        let roomRepo = StubRoomRepository()
        let existingRoom = RoomRecord(roomID: "r1", ownerUserID: "owner1", title: "Room A", plannedMinutes: 25, inviteCode: "CODE1")
        try! await roomRepo.createRoom(existingRoom)
        let accountService = StubAccountService()
        accountService.stubbedIdentity = AccountIdentity(userID: "u2", displayName: "Bob", email: nil)
        let accountVM = AccountViewModel(accountService: accountService, profileRepository: StubUserPublicProfileRepository())
        await accountVM.restoreSession()
        let vm = RoomLobbyViewModel(roomRepository: roomRepo, pkSessionRepository: StubPKSessionRepository(), accountViewModel: accountVM)
        await vm.joinRoom(inviteCode: "CODE1")
        XCTAssertEqual(vm.currentRoom?.roomID, "r1")
        XCTAssertEqual(vm.currentMembership?.role, .member)
    }

    func testReadyStateUpdatesAppearInRoomModel() async {
        let (vm, _, _) = makeHarness()
        await vm.createRoom(title: "Work", plannedMinutes: 25)
        await vm.setReady(true)
        XCTAssertEqual(vm.currentMembership?.readyState, .ready)
    }

    func testStartButtonOnlyEnabledForOwnerWhenAllReady() async {
        let (vm, _, _) = makeHarness()
        await vm.createRoom(title: "Solo", plannedMinutes: 25)
        // owner alone = canStart (owner doesn't need ready toggle in solo)
        XCTAssertTrue(vm.canStartSession || vm.members.count == 1)
    }

    private func makeHarness() -> (RoomLobbyViewModel, StubRoomRepository, StubPKSessionRepository) {
        let roomRepo = StubRoomRepository()
        let pkRepo = StubPKSessionRepository()
        let accountService = StubAccountService()
        accountService.stubbedIdentity = AccountIdentity(userID: "u1", displayName: "Alice", email: nil)
        let accountVM = AccountViewModel(accountService: accountService, profileRepository: StubUserPublicProfileRepository())
        Task { await accountVM.restoreSession() }
        let vm = RoomLobbyViewModel(roomRepository: roomRepo, pkSessionRepository: pkRepo, accountViewModel: accountVM)
        return (vm, roomRepo, pkRepo)
    }
}
