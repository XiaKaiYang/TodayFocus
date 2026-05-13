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

    func testRestoreSessionFallsBackToLocalProfileWhenCloudSyncUnavailable() async {
        let stub = StubAccountService()
        stub.stubbedIdentity = AccountIdentity(userID: "u-local", displayName: "Local User", email: nil)
        let profileRepo = SpyUserPublicProfileRepository()
        let vm = makeViewModel(
            accountService: stub,
            profileRepository: profileRepo,
            cloudProfileSyncAvailabilityProvider: { false }
        )

        await vm.restoreSession()

        XCTAssertEqual(vm.displayName, "Local User")
        XCTAssertTrue(vm.isSignedIn)
        XCTAssertEqual(vm.currentProfile?.userID, "u-local")
        let fetchCallCount = await profileRepo.fetchCallCount
        let upsertCallCount = await profileRepo.upsertCallCount
        XCTAssertEqual(fetchCallCount, 0)
        XCTAssertEqual(upsertCallCount, 0)
    }

    func testSignOutReturnsToSignedOutState() async {
        let stub = StubAccountService()
        stub.stubbedIdentity = AccountIdentity(userID: "u3", displayName: "Carol", email: nil)
        let vm = makeViewModel(accountService: stub)
        await vm.restoreSession()
        vm.signOut()
        XCTAssertEqual(vm.state, .signedOut)
    }

    func testUpdateBioPersistsIntoCurrentProfile() async throws {
        let stub = StubAccountService()
        stub.stubbedIdentity = AccountIdentity(userID: "u4", displayName: "Dana", email: nil)
        let profileRepo = StubUserPublicProfileRepository()
        let vm = makeViewModel(accountService: stub, profileRepository: profileRepo)

        await vm.restoreSession()
        try await vm.updateBio("专注对战产品设计者")

        XCTAssertEqual(vm.currentProfile?.bio, "专注对战产品设计者")
        let saved = await profileRepo.profiles["u4"]
        XCTAssertEqual(saved?.bio, "专注对战产品设计者")
    }

    private func makeViewModel(
        accountService: any AccountServicing = StubAccountService(),
        profileRepository: any UserPublicProfileRepositoryProtocol = StubUserPublicProfileRepository(),
        cloudProfileSyncAvailabilityProvider: @escaping @Sendable () -> Bool = { true }
    ) -> AccountViewModel {
        AccountViewModel(
            accountService: accountService,
            profileRepository: profileRepository,
            cloudProfileSyncAvailabilityProvider: cloudProfileSyncAvailabilityProvider
        )
    }
}

private actor SpyUserPublicProfileRepository: UserPublicProfileRepositoryProtocol {
    private(set) var fetchCallCount = 0
    private(set) var upsertCallCount = 0

    func fetch(userID: String) async throws -> UserPublicProfileRecord? {
        fetchCallCount += 1
        return nil
    }

    func upsert(_ record: UserPublicProfileRecord) async throws {
        upsertCallCount += 1
    }
}
