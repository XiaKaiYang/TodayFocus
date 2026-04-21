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

    func testPKRoomEmptyStateIncludesAppleSignInEntryPoint() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let roomLobbyFileURL = root.appendingPathComponent("Apps/FocusSessionApp/UI/PK/RoomLobbyView.swift")
        let contents = try String(contentsOf: roomLobbyFileURL, encoding: .utf8)

        XCTAssertTrue(contents.contains("SignInWithAppleButton"))
        XCTAssertTrue(contents.contains("Sign in to create or join a PK room"))
    }

    private func makeViewModel() -> RoomLobbyViewModel {
        let accountService = StubAccountService()
        let accountVM = AccountViewModel(accountService: accountService, profileRepository: StubUserPublicProfileRepository())
        return RoomLobbyViewModel(roomRepository: StubRoomRepository(), pkSessionRepository: StubPKSessionRepository(), accountViewModel: accountVM)
    }
}
