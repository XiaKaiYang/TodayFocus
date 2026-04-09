import XCTest
@testable import FocusSession

final class AppLaunchConfigurationTests: XCTestCase {
    func testDefaultLaunchDoesNotEnableDemoMode() {
        let configuration = AppLaunchConfiguration(environment: [:])

        XCTAssertNil(configuration.initialSection)
        XCTAssertFalse(configuration.usesBlockerDemo)
    }

    func testBlockerDemoModeSelectsBlockerAndEnablesDemoContent() {
        let configuration = AppLaunchConfiguration(
            environment: ["FOCUSSESSION_DEMO_MODE": "blocker"]
        )

        XCTAssertEqual(configuration.initialSection, .blocker)
        XCTAssertTrue(configuration.usesBlockerDemo)
    }

    func testInitialSectionSupportsCamelCaseSectionNames() {
        let currentSessionConfiguration = AppLaunchConfiguration(
            environment: ["FOCUSSESSION_INITIAL_SECTION": "currentSession"]
        )
        let whiteNoiseConfiguration = AppLaunchConfiguration(
            environment: ["FOCUSSESSION_INITIAL_SECTION": "whiteNoise"]
        )

        XCTAssertEqual(currentSessionConfiguration.initialSection, .currentSession)
        XCTAssertEqual(whiteNoiseConfiguration.initialSection, .whiteNoise)
        XCTAssertFalse(currentSessionConfiguration.usesBlockerDemo)
        XCTAssertFalse(whiteNoiseConfiguration.usesBlockerDemo)
    }
}
