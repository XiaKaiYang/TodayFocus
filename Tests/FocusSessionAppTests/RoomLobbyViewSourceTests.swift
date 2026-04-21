import XCTest
@testable import FocusSession

@MainActor
final class RoomLobbyViewSourceTests: XCTestCase {
    func testNoRoomShowsCreateAndJoinOptions() {
        let vm = makeViewModel()
        XCTAssertNil(vm.currentRoom)
        XCTAssertFalse(vm.isLoading)
    }

    func testInviteCodeIsNilWhenNoRoom() {
        let vm = makeViewModel()
        XCTAssertNil(vm.inviteCode)
    }

    private func makeViewModel() -> RoomLobbyViewModel {
        let accountService = StubAccountService()
        let accountVM = AccountViewModel(accountService: accountService, profileRepository: StubUserPublicProfileRepository())
        return RoomLobbyViewModel(roomRepository: StubRoomRepository(), pkSessionRepository: StubPKSessionRepository(), accountViewModel: accountVM)
    }
}
