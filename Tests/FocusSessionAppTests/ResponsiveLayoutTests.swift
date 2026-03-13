import XCTest
@testable import FocusSession

final class ResponsiveLayoutTests: XCTestCase {
    func testResponsiveWidthTierClassifiesShellAndDetailWidths() {
        XCTAssertEqual(AppResponsiveWidthTier.shell(for: 920), .compact)
        XCTAssertEqual(AppResponsiveWidthTier.shell(for: 1240), .regular)
        XCTAssertEqual(AppResponsiveWidthTier.shell(for: 1520), .expanded)

        XCTAssertEqual(AppResponsiveWidthTier.detail(for: 680), .compact)
        XCTAssertEqual(AppResponsiveWidthTier.detail(for: 980), .regular)
        XCTAssertEqual(AppResponsiveWidthTier.detail(for: 1460), .expanded)
    }

    func testWindowAndDashboardSourcesUseResponsiveSizing() throws {
        let appRoot = "/Users/xiakaiyang/Documents/New project/Apps/FocusSessionApp"
        let appSource = try String(
            contentsOfFile: "\(appRoot)/FocusSessionApp.swift",
            encoding: .utf8
        )
        let shellSource = try String(
            contentsOfFile: "\(appRoot)/UI/AppShell/AppShellView.swift",
            encoding: .utf8
        )
        let notesSource = try String(
            contentsOfFile: "\(appRoot)/UI/Notes/NotesLibraryView.swift",
            encoding: .utf8
        )
        let tasksSource = try String(
            contentsOfFile: "\(appRoot)/UI/Tasks/TasksDashboardView.swift",
            encoding: .utf8
        )
        let planSource = try String(
            contentsOfFile: "\(appRoot)/UI/Plan/PlanDashboardView.swift",
            encoding: .utf8
        )
        let analyticsSource = try String(
            contentsOfFile: "\(appRoot)/UI/Analytics/AnalyticsDashboardView.swift",
            encoding: .utf8
        )

        XCTAssertTrue(appSource.contains(".frame(minWidth: 900, minHeight: 620)"))

        XCTAssertTrue(shellSource.contains("GeometryReader { geometry in"))
        XCTAssertTrue(shellSource.contains("AppResponsiveWidthTier.shell"))
        XCTAssertTrue(shellSource.contains("shellSidebarWidth"))

        XCTAssertTrue(notesSource.contains("AppResponsiveWidthTier.detail"))
        XCTAssertTrue(notesSource.contains("notesListWidth"))
        XCTAssertTrue(notesSource.contains("if widthTier == .compact"))
        XCTAssertTrue(notesSource.contains("DetailDashboardLayoutMetrics.contentInsets(for: widthTier)"))
        XCTAssertTrue(notesSource.contains("DashboardTimeNavigator"))
        XCTAssertFalse(notesSource.contains("Text(\"Notes\")"))
        XCTAssertFalse(notesSource.contains("Browse the notes captured during previous focus blocks."))
        XCTAssertFalse(notesSource.contains(".frame(width: 340)"))

        XCTAssertTrue(analyticsSource.contains("AppResponsiveWidthTier.detail"))
        XCTAssertTrue(analyticsSource.contains("if widthTier == .compact"))
        XCTAssertTrue(analyticsSource.contains("DetailDashboardLayoutMetrics.contentInsets(for: widthTier)"))
        XCTAssertTrue(analyticsSource.contains("DashboardTimeNavigator"))
        XCTAssertFalse(analyticsSource.contains("Text(\"Analytics\")"))
        XCTAssertFalse(analyticsSource.contains("A quick read on how much deep work you are actually shipping this week."))
        XCTAssertFalse(analyticsSource.contains(".frame(width: 360, alignment: .leading)"))

        XCTAssertTrue(tasksSource.contains("ViewThatFits(in: .horizontal)"))
        XCTAssertFalse(tasksSource.contains(".fixedSize(horizontal: true, vertical: false)"))
        XCTAssertFalse(tasksSource.contains(".frame(width: 460, alignment: .leading)"))

        XCTAssertTrue(planSource.contains("ViewThatFits(in: .horizontal)"))
        XCTAssertFalse(planSource.contains(".frame(width: 560, alignment: .leading)"))
        XCTAssertFalse(planSource.contains(".frame(width: 480, alignment: .leading)"))
    }
}
