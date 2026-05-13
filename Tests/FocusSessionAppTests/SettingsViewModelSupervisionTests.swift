import XCTest
@testable import FocusSession

@MainActor
final class SettingsViewModelSupervisionTests: XCTestCase {
    func testInitialSupervisionEligibilityIsIneligible() throws {
        let vm = makeViewModel()
        if case .ineligible = vm.supervisionEligibility {
            // pass
        } else {
            XCTFail("Expected ineligible by default")
        }
    }

    func testBindCoordinatorUpdatesEligibility() throws {
        let vm = makeViewModel()
        let coordinator = StubSupervisionCoordinator()
        vm.bindSupervisionCoordinator(coordinator)
        XCTAssertEqual(vm.supervisionEligibility, .eligible)
    }

    func testWithdrawSupervisionCallsStopAndResetsEligibility() throws {
        let vm = makeViewModel()
        let coordinator = StubSupervisionCoordinator()
        coordinator.startSupervision(sessionID: "s1", roomID: "r1", userID: "u1")
        vm.bindSupervisionCoordinator(coordinator)
        vm.withdrawSupervision()
        XCTAssertNil(coordinator.currentStateSnapshot)
        if case .ineligible = vm.supervisionEligibility {
            // pass
        } else {
            XCTFail("Expected ineligible after withdrawal")
        }
    }

    func testWithdrawWithoutCoordinatorIsNoOp() throws {
        let vm = makeViewModel()
        vm.withdrawSupervision() // should not crash
        if case .ineligible = vm.supervisionEligibility {
            // pass
        } else {
            XCTFail("Expected ineligible")
        }
    }

    func testRefreshSupervisionEligibilityPullsLatestCoordinatorState() async throws {
        let vm = makeViewModel()
        let coordinator = StubSupervisionCoordinator()
        coordinator.permissionSnapshot = SupervisionPermissionSnapshot(
            isSignedIn: true,
            cameraPermission: .authorized,
            screenRecordingPermission: .authorized
        )

        vm.bindSupervisionCoordinator(coordinator)
        await vm.refreshSupervisionEligibility()

        XCTAssertEqual(vm.supervisionEligibility, .eligible)
    }

    private func makeViewModel() -> SettingsViewModel {
        let suiteName = UUID().uuidString
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let preferencesStore = AppPreferencesStore(userDefaults: defaults)
        return SettingsViewModel(preferencesStore: preferencesStore)
    }
}
