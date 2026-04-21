import XCTest
@testable import FocusSessionCore

final class FocusSessionDeepLinkTests: XCTestCase {
    func testPlanURLResolvesToPlanDestination() throws {
        XCTAssertEqual(
            FocusSessionDeepLink.destination(for: FocusSessionDeepLink.planURL),
            .plan
        )
    }

    func testUnsupportedURLsDoNotResolve() throws {
        XCTAssertNil(FocusSessionDeepLink.destination(for: URL(string: "todayfocus://notes")!))
        XCTAssertNil(FocusSessionDeepLink.destination(for: URL(string: "https://example.com/plan")!))
    }
}
