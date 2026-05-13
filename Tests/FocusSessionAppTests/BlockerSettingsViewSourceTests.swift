import XCTest

final class BlockerSettingsViewSourceTests: XCTestCase {
    func testBlockerDashboardShowsAggregateAppAndWebsiteCounts() throws {
        let source = try String(
            contentsOfFile: "/Users/xiakaiyang/Documents/New project/Apps/FocusSessionApp/UI/Blocker/BlockerSettingsView.swift",
            encoding: .utf8
        )
        let viewModelSource = try String(
            contentsOfFile: "/Users/xiakaiyang/Documents/New project/Apps/FocusSessionApp/ViewModels/BlockerViewModel.swift",
            encoding: .utf8
        )

        XCTAssertTrue(source.contains("软件已屏蔽"))
        XCTAssertTrue(source.contains("网站已屏蔽"))
        XCTAssertFalse(source.contains("Recent Blocked Attempts"))
        XCTAssertFalse(source.contains("ForEach(viewModel.recentEvents)"))
        XCTAssertTrue(viewModelSource.contains("blockedAppCount"))
        XCTAssertTrue(viewModelSource.contains("blockedWebsiteCount"))
    }
}
