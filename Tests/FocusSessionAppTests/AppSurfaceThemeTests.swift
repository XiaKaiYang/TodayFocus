import XCTest
@testable import FocusSession

final class AppSurfaceThemeTests: XCTestCase {
    func testLightCanvasThemeKeepsSharedSurfaceMetricsAligned() {
        XCTAssertEqual(AppSurfaceTheme.primaryTextOpacity, 0.82, accuracy: 0.001)
        XCTAssertEqual(AppSurfaceTheme.secondaryTextOpacity, 0.58, accuracy: 0.001)
        XCTAssertEqual(AppSurfaceTheme.tertiaryTextOpacity, 0.50, accuracy: 0.001)
        XCTAssertEqual(AppSurfaceTheme.accentTextOpacity, 0.88, accuracy: 0.001)
        XCTAssertEqual(AppSurfaceTheme.cardBorderOpacity, 0.06, accuracy: 0.001)
        XCTAssertEqual(AppSurfaceTheme.standardCardFillOpacity, 0.56, accuracy: 0.001)
        XCTAssertEqual(AppSurfaceTheme.elevatedCardFillOpacity, 0.72, accuracy: 0.001)
        XCTAssertEqual(AppSurfaceTheme.softCardFillOpacity, 0.74, accuracy: 0.001)
    }

    func testLowChromeNavigationAndSelectorMetricsStayReadable() {
        XCTAssertEqual(AppSurfaceTheme.sidebarFillOpacity, 0, accuracy: 0.001)
        XCTAssertEqual(AppSurfaceTheme.sidebarSelectedFillOpacity, 0, accuracy: 0.001)
        XCTAssertEqual(AppSurfaceTheme.sidebarSelectionAccentOpacity, 0.18, accuracy: 0.001)
        XCTAssertEqual(AppSurfaceTheme.taskSelectorGlyphOpacity, 0.74, accuracy: 0.001)
        XCTAssertGreaterThan(AppSurfaceTheme.taskSelectorGlyphOpacity, AppSurfaceTheme.secondaryTextOpacity)
        XCTAssertLessThan(AppSurfaceTheme.taskSelectorGlyphOpacity, AppSurfaceTheme.primaryTextOpacity)
    }

    func testCurrentSessionTaskSelectorUsesWarmCustomInkTokens() {
        XCTAssertEqual(AppSurfaceTheme.taskSelectorWarmGlyphRed, 0.40, accuracy: 0.001)
        XCTAssertEqual(AppSurfaceTheme.taskSelectorWarmGlyphGreen, 0.35, accuracy: 0.001)
        XCTAssertEqual(AppSurfaceTheme.taskSelectorWarmGlyphBlue, 0.31, accuracy: 0.001)
        XCTAssertEqual(AppSurfaceTheme.taskSelectorWarmBorderRed, 0.63, accuracy: 0.001)
        XCTAssertEqual(AppSurfaceTheme.taskSelectorWarmBorderGreen, 0.56, accuracy: 0.001)
        XCTAssertEqual(AppSurfaceTheme.taskSelectorWarmBorderBlue, 0.49, accuracy: 0.001)
    }

    func testTransparentInputsAndGlassChromeMetricsStayAligned() {
        XCTAssertEqual(AppSurfaceTheme.inputFillOpacity, 0, accuracy: 0.001)
        XCTAssertEqual(AppSurfaceTheme.inputStrokeOpacity, 0.12, accuracy: 0.001)
        XCTAssertEqual(AppSurfaceTheme.glassFillTopOpacity, 0.24, accuracy: 0.001)
        XCTAssertEqual(AppSurfaceTheme.glassFillBottomOpacity, 0.12, accuracy: 0.001)
        XCTAssertEqual(AppSurfaceTheme.glassStrokeOpacity, 0.10, accuracy: 0.001)
        XCTAssertEqual(AppSurfaceTheme.glassShadowOpacity, 0.12, accuracy: 0.001)
        XCTAssertLessThan(AppSurfaceTheme.glassFillBottomOpacity, AppSurfaceTheme.softCardFillOpacity)
    }

    func testAccentButtonsUseDarkInkInsteadOfWhiteText() {
        XCTAssertGreaterThan(AppSurfaceTheme.accentTextOpacity, AppSurfaceTheme.secondaryTextOpacity)
        XCTAssertGreaterThan(AppSurfaceTheme.accentTextOpacity, AppSurfaceTheme.tertiaryTextOpacity)
        XCTAssertLessThanOrEqual(AppSurfaceTheme.accentTextOpacity, 1)
    }

    func testDashboardTimeNavigatorUsesCompactMetricsAndKeepsRailsClipped() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let fileURL = root.appendingPathComponent("Apps/FocusSessionApp/UI/AppSurfaceTheme.swift")
        let contents = try String(contentsOf: fileURL, encoding: .utf8)

        XCTAssertEqual(DashboardTimeNavigatorMetrics.outerPadding, 14, accuracy: 0.001)
        XCTAssertEqual(DashboardTimeNavigatorMetrics.navigatorButtonSize, 38, accuracy: 0.001)
        XCTAssertEqual(DashboardTimeNavigatorMetrics.scopeCardMinimumWidth, 120, accuracy: 0.001)
        XCTAssertEqual(DashboardTimeNavigatorMetrics.railHeight, 76, accuracy: 0.001)
        XCTAssertFalse(
            contents.contains("scrollClipDisabled()"),
            "The week/month strip should stay clipped inside the navigator card instead of drawing beyond the rounded container."
        )
    }

    func testDashboardTimeNavigatorUsesTitleStyleNavigationInsteadOfBoxedChrome() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let fileURL = root.appendingPathComponent("Apps/FocusSessionApp/UI/AppSurfaceTheme.swift")
        let contents = try String(contentsOf: fileURL, encoding: .utf8)

        guard
            let start = contents.range(of: "struct DashboardTimeNavigator: View {"),
            let end = contents.range(of: "struct AppPromptedTextField: View {")
        else {
            return XCTFail("The dashboard time navigator source should be present in AppSurfaceTheme.swift.")
        }

        let navigatorSource = String(contents[start.lowerBound..<end.lowerBound])

        XCTAssertTrue(
            navigatorSource.contains("scopeHeaderTabs"),
            "The dashboard navigator should render day/week/month as lightweight title tabs instead of reusing the boxed segmented control."
        )
        XCTAssertFalse(
            navigatorSource.contains("AppSegmentedControl("),
            "The dashboard navigator should not render the boxed segmented control for the scope switcher."
        )
        XCTAssertFalse(
            navigatorSource.contains(".background(AppGlassRoundedSurface(cornerRadius: DashboardTimeNavigatorMetrics.titleCornerRadius))"),
            "The centered reference title should read like a heading, not a glassy input field."
        )
        XCTAssertFalse(
            navigatorSource.contains(".background(AppCardSurface(style: .standard, cornerRadius: DashboardTimeNavigatorMetrics.outerCornerRadius))"),
            "The entire dashboard navigator should sit directly on the page instead of inside another rounded card."
        )
    }
}
