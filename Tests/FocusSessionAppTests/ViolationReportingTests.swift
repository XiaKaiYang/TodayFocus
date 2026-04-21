import XCTest
@testable import FocusSession

@MainActor
final class ViolationReportingTests: XCTestCase {
    func testReportViolationRecordsEvent() async {
        let repository = StubSupervisionRepository()
        let coordinator = SupervisionCoordinator(
            accountViewModel: makeAccountVM(),
            supervisionRepository: repository,
            evidenceCaptureService: StubEvidenceCaptureService()
        )
        coordinator.startSupervision(sessionID: "s1", roomID: "r1", userID: "u1")
        await coordinator.reportViolation(type: .seatAbsence)
        XCTAssertEqual(repository.violations.count, 1)
        XCTAssertEqual(repository.violations.first?.violationType, .seatAbsence)
        XCTAssertEqual(repository.violations.first?.sessionID, "s1")
    }

    func testReportViolationNoOpWithoutActiveSession() async {
        let repository = StubSupervisionRepository()
        let coordinator = SupervisionCoordinator(
            accountViewModel: makeAccountVM(),
            supervisionRepository: repository,
            evidenceCaptureService: StubEvidenceCaptureService()
        )
        await coordinator.reportViolation(type: .inactivity)
        XCTAssertEqual(repository.violations.count, 0)
    }

    func testMultipleViolationTypesAreRecorded() async {
        let repository = StubSupervisionRepository()
        let coordinator = SupervisionCoordinator(
            accountViewModel: makeAccountVM(),
            supervisionRepository: repository,
            evidenceCaptureService: StubEvidenceCaptureService()
        )
        coordinator.startSupervision(sessionID: "s1", roomID: "r1", userID: "u1")
        await coordinator.reportViolation(type: .seatAbsence)
        await coordinator.reportViolation(type: .inactivity)
        await coordinator.reportViolation(type: .tabSwitching)
        XCTAssertEqual(repository.violations.count, 3)
    }

    private func makeAccountVM() -> AccountViewModel {
        let stub = StubAccountService()
        stub.stubbedIdentity = AccountIdentity(userID: "u1", displayName: "Alice", email: nil)
        return AccountViewModel(
            accountService: stub,
            profileRepository: StubUserPublicProfileRepository()
        )
    }
}
