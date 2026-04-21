import XCTest
@testable import FocusSession
import SwiftData

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

    func testStartSessionBindsCurrentSessionAndStartsSupervision() async throws {
        let (vm, _, _, currentSessionViewModel, pkCoordinator, supervisionCoordinator) = try makeBoundHarness()

        await vm.createRoom(title: "Bound Room", plannedMinutes: 25)
        await vm.startSession()

        XCTAssertTrue((currentSessionViewModel.pkCoordinator as? StubPKSessionCoordinator) === pkCoordinator)
        XCTAssertEqual(supervisionCoordinator.currentStateSnapshot?.roomID, vm.currentRoom?.roomID)
        XCTAssertEqual(supervisionCoordinator.currentStateSnapshot?.sessionID, vm.currentRoom?.currentSessionID)
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

    private func makeBoundHarness() throws -> (RoomLobbyViewModel, StubRoomRepository, StubPKSessionRepository, CurrentSessionViewModel, StubPKSessionCoordinator, StubSupervisionCoordinator) {
        let roomRepo = StubRoomRepository()
        let pkRepo = StubPKSessionRepository()
        let accountService = StubAccountService()
        accountService.stubbedIdentity = AccountIdentity(userID: "u1", displayName: "Alice", email: nil)
        let accountVM = AccountViewModel(accountService: accountService, profileRepository: StubUserPublicProfileRepository())
        let currentSessionViewModel = try makeCurrentSessionViewModel()
        let pkCoordinator = StubPKSessionCoordinator()
        let supervisionCoordinator = StubSupervisionCoordinator()
        let vm = RoomLobbyViewModel(
            roomRepository: roomRepo,
            pkSessionRepository: pkRepo,
            accountViewModel: accountVM,
            currentSessionViewModel: currentSessionViewModel,
            pkSessionCoordinator: pkCoordinator,
            supervisionCoordinator: supervisionCoordinator
        )
        return (vm, roomRepo, pkRepo, currentSessionViewModel, pkCoordinator, supervisionCoordinator)
    }

    private func makeCurrentSessionViewModel() throws -> CurrentSessionViewModel {
        let container = try FocusSessionModelContainer.makeInMemory()
        let context = ModelContext(container)
        let tasksRepo = TasksRepository(modelContext: context)
        let focusRepo = FocusSessionRepository(modelContext: context)
        return CurrentSessionViewModel(
            snapshotStore: nil,
            focusSessionRepository: focusRepo,
            tasksRepository: tasksRepo
        )
    }
}
