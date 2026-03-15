import XCTest
@testable import FocusSession

final class MobileShellRoutingTests: XCTestCase {
    func testIOSAvailabilityHidesBlockerButKeepsPrimarySections() {
        XCTAssertFalse(AppSection.blocker.isAvailable(on: .iOS))
        XCTAssertTrue(AppSection.tasks.isAvailable(on: .iOS))
        XCTAssertTrue(AppSection.currentSession.isAvailable(on: .iOS))
        XCTAssertTrue(AppSection.plan.isAvailable(on: .iOS))
        XCTAssertTrue(AppSection.notes.isAvailable(on: .iOS))
    }

    func testMobilePrimaryTabsExposeExpectedRootAndMoreSections() {
        XCTAssertEqual(MobilePrimaryTab.tasks.rootSection, .tasks)
        XCTAssertEqual(MobilePrimaryTab.currentSession.rootSection, .currentSession)
        XCTAssertEqual(MobilePrimaryTab.plan.rootSection, .plan)
        XCTAssertEqual(MobilePrimaryTab.notes.rootSection, .notes)
        XCTAssertNil(MobilePrimaryTab.more.rootSection)
        XCTAssertEqual(
            MobilePrimaryTab.moreSections,
            [.whiteNoise, .analytics, .trash, .settings]
        )
    }

    func testPhoneLaunchRoutingMapsSecondarySectionsIntoMoreTab() {
        let state = MobileShellRouting.phoneLaunchState(preferredSection: .analytics)

        XCTAssertEqual(state.selectedTab, .more)
        XCTAssertEqual(state.selectedMoreSection, .analytics)
    }

    func testPhoneLaunchRoutingFallsBackWhenSectionIsUnsupportedOnIOS() {
        let state = MobileShellRouting.phoneLaunchState(preferredSection: .blocker)

        XCTAssertEqual(state.selectedTab, .tasks)
        XCTAssertNil(state.selectedMoreSection)
    }

    func testPadLaunchRoutingPreservesSupportedSectionsAndFallsBackForUnsupportedOnes() {
        XCTAssertEqual(
            MobileShellRouting.padLaunchSection(preferredSection: .notes),
            .notes
        )
        XCTAssertEqual(
            MobileShellRouting.padLaunchSection(preferredSection: .blocker),
            .tasks
        )
    }
}
