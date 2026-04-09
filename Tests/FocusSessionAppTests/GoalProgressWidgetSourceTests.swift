import XCTest

final class GoalProgressWidgetSourceTests: XCTestCase {
    func testWidgetUsesMediumFamilyPlanDeepLinkAndProgressGridLayout() throws {
        let widgetSource = try String(
            contentsOfFile: "/Users/xiakaiyang/Documents/New project/Extensions/FocusSessionWidget/FocusSessionWidgetBundle.swift",
            encoding: .utf8
        )
        let projectSource = try String(
            contentsOfFile: "/Users/xiakaiyang/Documents/New project/project.yml",
            encoding: .utf8
        )

        XCTAssertTrue(widgetSource.contains(".supportedFamilies([.systemMedium])"))
        XCTAssertTrue(widgetSource.contains("widgetURL(FocusSessionDeepLink.planURL)"))
        XCTAssertTrue(widgetSource.contains("Text(\"No active goals\")"))
        XCTAssertTrue(widgetSource.contains("Text(\"Open Plan\")"))
        XCTAssertTrue(widgetSource.contains("LazyVGrid(columns: gridColumns"))
        XCTAssertTrue(widgetSource.contains("progressPill(for: item)"))
        XCTAssertTrue(widgetSource.contains("GeometryReader { geometry in"))
        XCTAssertTrue(widgetSource.contains("RoundedRectangle(cornerRadius: 18, style: .continuous)"))
        XCTAssertTrue(projectSource.contains("target: FocusSessionWidget"))
        XCTAssertTrue(projectSource.contains("embed: true"))
    }
}
