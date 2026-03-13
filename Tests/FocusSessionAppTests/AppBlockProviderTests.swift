import XCTest
import FocusSessionCore
@testable import FocusSession

final class AppBlockProviderTests: XCTestCase {
    func testBlockedApplicationNameReturnsBlockDecision() {
        let provider = AppBlockProvider(
            rules: [
                BlockingRule(
                    mode: .deny,
                    target: .app(name: "Safari")
                )
            ]
        )

        let decision = provider.decision(
            forFrontmostAppName: "Safari",
            isOnBreak: false
        )

        XCTAssertEqual(decision, .block(reason: .denyList))
    }

    func testAllowListBlocksUnknownApplicationDuringFocus() {
        let provider = AppBlockProvider(
            rules: [
                BlockingRule(
                    mode: .allow,
                    target: .app(name: "Xcode")
                )
            ]
        )

        let decision = provider.decision(
            forFrontmostAppName: "Safari",
            isOnBreak: false
        )

        XCTAssertEqual(decision, .block(reason: .allowList))
    }
}
