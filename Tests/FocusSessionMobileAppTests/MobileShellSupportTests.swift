import XCTest
@testable import FocusSessionMobile

final class MobileShellSupportTests: XCTestCase {
    func testSecondarySectionsOpenInsideMoreTab() {
        let state = MobileShellRouting.phoneLaunchState(preferredSection: .analytics)

        XCTAssertEqual(state.selectedTab, .more)
        XCTAssertEqual(state.selectedMoreSection, .analytics)
    }

    func testUnsupportedLaunchSectionFallsBackToTodayOnIOS() {
        let state = MobileShellRouting.phoneLaunchState(preferredSection: .blocker)

        XCTAssertEqual(state.selectedTab, .tasks)
        XCTAssertNil(state.selectedMoreSection)
    }

    func testPadSelectionFiltersOutBlocker() {
        XCTAssertEqual(
            MobileShellRouting.padLaunchSection(preferredSection: .blocker),
            .tasks
        )
    }
}
