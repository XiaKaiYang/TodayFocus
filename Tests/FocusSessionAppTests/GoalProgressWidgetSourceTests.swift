import XCTest

final class GoalProgressWidgetSourceTests: XCTestCase {
    func testProjectNoLongerDeclaresWidgetAndIntentsTargets() throws {
        let projectSource = try String(
            contentsOfFile: "/Users/xiakaiyang/Documents/New project/project.yml",
            encoding: .utf8
        )

        XCTAssertFalse(projectSource.contains("FocusSessionWidget:"))
        XCTAssertFalse(projectSource.contains("FocusSessionIntents:"))
    }

    func testWidgetAndIntentSourceFilesAreRemoved() {
        let fileManager = FileManager.default

        XCTAssertFalse(
            fileManager.fileExists(atPath: "/Users/xiakaiyang/Documents/New project/Extensions/FocusSessionWidget/FocusSessionWidgetBundle.swift")
        )
        XCTAssertFalse(
            fileManager.fileExists(atPath: "/Users/xiakaiyang/Documents/New project/Extensions/FocusSessionIntents/FocusSessionIntents.swift")
        )
        XCTAssertFalse(
            fileManager.fileExists(atPath: "/Users/xiakaiyang/Documents/New project/Apps/FocusSessionApp/Widgets/GoalProgressWidgetSyncer.swift")
        )
        XCTAssertFalse(
            fileManager.fileExists(atPath: "/Users/xiakaiyang/Documents/New project/Packages/FocusSessionCore/Sources/FocusSessionCore/Widgets/GoalProgressWidgetStore.swift")
        )
    }
}
