import XCTest
@testable import FocusSession

@MainActor
final class SupervisionCoordinatorTests: XCTestCase {
    func testEligibleWhenSignedInAndPermissionsGranted() {
        let snapshot = SupervisionPermissionSnapshot(
            isSignedIn: true,
            cameraPermission: .authorized,
            screenRecordingPermission: .authorized
        )
        XCTAssertEqual(snapshot.eligibility, .eligible)
    }

    func testIneligibleWhenNotSignedIn() {
        let snapshot = SupervisionPermissionSnapshot(
            isSignedIn: false,
            cameraPermission: .authorized,
            screenRecordingPermission: .authorized
        )
        if case .ineligible(let reasons) = snapshot.eligibility {
            XCTAssertTrue(reasons.contains(.notSignedIn))
        } else {
            XCTFail("Expected ineligible")
        }
    }

    func testIneligibleWhenCameraPermissionDenied() {
        let snapshot = SupervisionPermissionSnapshot(
            isSignedIn: true,
            cameraPermission: .denied,
            screenRecordingPermission: .authorized
        )
        if case .ineligible(let reasons) = snapshot.eligibility {
            XCTAssertTrue(reasons.contains(.cameraPermissionDenied))
        } else {
            XCTFail("Expected ineligible")
        }
    }

    func testIneligibleWhenScreenRecordingDenied() {
        let snapshot = SupervisionPermissionSnapshot(
            isSignedIn: true,
            cameraPermission: .authorized,
            screenRecordingPermission: .denied
        )
        if case .ineligible(let reasons) = snapshot.eligibility {
            XCTAssertTrue(reasons.contains(.screenRecordingPermissionDenied))
        } else {
            XCTFail("Expected ineligible")
        }
    }

    func testMissingPermissionDowngradesRoomMode() {
        let snapshot = SupervisionPermissionSnapshot(
            isSignedIn: true,
            cameraPermission: .denied,
            screenRecordingPermission: .denied
        )
        XCTAssertNotEqual(snapshot.eligibility, .eligible)
    }

    func testStartSupervisionCreatesStateSnapshot() {
        let accountVM = AccountViewModel(
            accountService: makeSignedInStub(),
            profileRepository: StubUserPublicProfileRepository()
        )
        let coordinator = SupervisionCoordinator(accountViewModel: accountVM)
        coordinator.startSupervision(sessionID: "s1", roomID: "r1", userID: "u1")
        XCTAssertNotNil(coordinator.currentStateSnapshot)
        XCTAssertEqual(coordinator.currentStateSnapshot?.sessionID, "s1")
    }

    func testStopSupervisionClearsSnapshot() {
        let accountVM = AccountViewModel(
            accountService: makeSignedInStub(),
            profileRepository: StubUserPublicProfileRepository()
        )
        let coordinator = SupervisionCoordinator(accountViewModel: accountVM)
        coordinator.startSupervision(sessionID: "s1", roomID: "r1", userID: "u1")
        coordinator.stopSupervision()
        XCTAssertNil(coordinator.currentStateSnapshot)
    }

    private func makeSignedInStub() -> StubAccountService {
        let stub = StubAccountService()
        stub.stubbedIdentity = AccountIdentity(userID: "u1", displayName: "Alice", email: nil)
        return stub
    }
}
