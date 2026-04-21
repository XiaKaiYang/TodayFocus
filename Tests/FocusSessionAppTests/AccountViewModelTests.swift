import XCTest
@testable import FocusSession

@MainActor
final class AccountViewModelTests: XCTestCase {
    func testInitialStateIsSignedOut() {
        let vm = makeViewModel()
        XCTAssertEqual(vm.state, .signedOut)
    }

    func testSignedInStateExposesDisplayName() async {
        let stub = StubAccountService()
        stub.stubbedIdentity = AccountIdentity(userID: "u1", displayName: "Alice", email: nil)
        let vm = makeViewModel(accountService: stub)
        await vm.restoreSession()
        XCTAssertEqual(vm.displayName, "Alice")
        XCTAssertTrue(vm.isSignedIn)
    }

    func testMissingProfileTriggersBootstrapSave() async {
        let stub = StubAccountService()
        stub.stubbedIdentity = AccountIdentity(userID: "u2", displayName: "Bob", email: nil)
        let profileRepo = StubUserPublicProfileRepository()
        let vm = makeViewModel(accountService: stub, profileRepository: profileRepo)
        await vm.restoreSession()
        let saved = await profileRepo.profiles["u2"]
        XCTAssertNotNil(saved)
        XCTAssertEqual(saved?.displayName, "Bob")
    }

    func testSignOutReturnsToSignedOutState() async {
        let stub = StubAccountService()
        stub.stubbedIdentity = AccountIdentity(userID: "u3", displayName: "Carol", email: nil)
        let vm = makeViewModel(accountService: stub)
        await vm.restoreSession()
        vm.signOut()
        XCTAssertEqual(vm.state, .signedOut)
    }

    private func makeViewModel(
        accountService: any AccountServicing = StubAccountService(),
        profileRepository: any UserPublicProfileRepositoryProtocol = StubUserPublicProfileRepository()
    ) -> AccountViewModel {
        AccountViewModel(accountService: accountService, profileRepository: profileRepository)
    }
}
