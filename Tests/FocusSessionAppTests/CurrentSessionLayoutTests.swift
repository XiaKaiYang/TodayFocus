import XCTest
import FocusSessionCore
@testable import FocusSession

final class CurrentSessionLayoutTests: XCTestCase {
    func testCompactWidthLayoutNarrowsHeroAndTaskSelector() {
        let compactLayout = CurrentSessionLayoutMetrics.make(
            widthTier: .compact,
            isCompactHeight: false,
            phase: .idle
        )
        let regularLayout = CurrentSessionLayoutMetrics.make(
            widthTier: .regular,
            isCompactHeight: false,
            phase: .idle
        )

        XCTAssertLessThan(compactLayout.setupHeroMaxWidth, regularLayout.setupHeroMaxWidth)
        XCTAssertLessThan(compactLayout.taskSelectorMaxWidth, regularLayout.taskSelectorMaxWidth)
        XCTAssertLessThan(compactLayout.timeReadoutFontSize, regularLayout.timeReadoutFontSize)
    }

    func testRunningLayoutRemovesTopAccessoriesAndTightensVerticalRhythm() {
        let idleLayout = CurrentSessionLayoutMetrics.make(
            widthTier: .regular,
            isCompactHeight: false,
            phase: .idle
        )
        let focusingLayout = CurrentSessionLayoutMetrics.make(
            widthTier: .regular,
            isCompactHeight: false,
            phase: .focusing
        )

        XCTAssertFalse(idleLayout.showsTopAccessories)
        XCTAssertFalse(focusingLayout.showsTopAccessories)
        XCTAssertLessThan(focusingLayout.leftColumnSpacing, idleLayout.leftColumnSpacing)
        XCTAssertLessThan(focusingLayout.dialSize, idleLayout.dialSize)
        XCTAssertLessThan(focusingLayout.footerButtonSize, idleLayout.footerButtonSize)
    }

    func testCurrentSessionTypographyIsScaledCloserToTheRestOfTheApp() {
        let layout = CurrentSessionLayoutMetrics.make(
            widthTier: .regular,
            isCompactHeight: false,
            phase: .idle
        )

        XCTAssertEqual(layout.notesTitleFontSize, 20)
        XCTAssertEqual(layout.intentionInputFontSize, 18)
        XCTAssertEqual(layout.recentSessionTitleFontSize, 16)
        XCTAssertEqual(layout.supportingCopyFontSize, 14)
        XCTAssertEqual(layout.notesBodyFontSize, 15)
        XCTAssertEqual(layout.intentionInputHeight, 54)
        XCTAssertEqual(layout.taskSelectorMaxWidth, 392)
        XCTAssertEqual(layout.noteEditorHorizontalInset, 22)
        XCTAssertEqual(layout.noteEditorVerticalInset, 20)
    }

    func testIdleLayoutUsesMinimalSingleColumnSetupStage() {
        let layout = CurrentSessionLayoutMetrics.make(
            widthTier: .regular,
            isCompactHeight: false,
            phase: .idle
        )

        XCTAssertFalse(layout.usesTwoByTwoSupportingCards)
        XCTAssertFalse(layout.showsSetupSupportingCopy)
        XCTAssertFalse(layout.showsSetupFooterCopy)
        XCTAssertLessThanOrEqual(layout.setupStageContentMaxWidth, 680)
        XCTAssertEqual(layout.setupStageSidePanelWidth, 0)
        XCTAssertGreaterThanOrEqual(layout.dialSize, 320)
    }

    func testIdleLayoutUsesTransparentStageAndHubBasedDialComposition() {
        let layout = CurrentSessionLayoutMetrics.make(
            widthTier: .regular,
            isCompactHeight: false,
            phase: .idle
        )

        XCTAssertTrue(layout.usesTransparentSetupContainer)
        XCTAssertFalse(layout.dialShowsCenterReadout)
        XCTAssertTrue(layout.dialUsesSoftPlatter)
        XCTAssertGreaterThanOrEqual(layout.dialHubDiameter, 20)
        XCTAssertGreaterThan(layout.dialHandShadowRadius, 8)
    }

    func testCustomPromptedTextEditorUsesFixedDarkInkInsteadOfSemanticLabelColor() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let fileURL = root.appendingPathComponent("Apps/FocusSessionApp/UI/AppSurfaceTheme.swift")
        let contents = try String(contentsOf: fileURL, encoding: .utf8)

        XCTAssertTrue(
            contents.contains("AppFixedInkTextView"),
            "The custom prompted text editor should use a dedicated NSTextView subclass that keeps runtime note text on a fixed dark ink path."
        )
        XCTAssertFalse(
            contents.contains("NSColor.labelColor"),
            "The note editor should avoid semantic AppKit label colors because they can resolve to white in the current appearance stack."
        )
    }

    func testReflectionOverlayUsesMoreOpaqueBackdropAndCardSurface() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let fileURL = root.appendingPathComponent("Apps/FocusSessionApp/UI/CurrentSession/CurrentSessionView.swift")
        let contents = try String(contentsOf: fileURL, encoding: .utf8)

        XCTAssertTrue(
            contents.contains("Color.black.opacity(0.22)"),
            "The reflection overlay should use a stronger backdrop so the submit step reads as a modal state instead of blending into the page."
        )
        XCTAssertTrue(
            contents.contains("Color(red: 0.98, green: 0.97, blue: 0.95)"),
            "The reflection card should add a near-solid warm fill so the modal feels grounded instead of overly transparent."
        )
    }

    func testSetupStagePinsIdleHeroToTopLikeOtherDashboardPages() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let fileURL = root.appendingPathComponent("Apps/FocusSessionApp/UI/CurrentSession/CurrentSessionView.swift")
        let contents = try String(contentsOf: fileURL, encoding: .utf8)

        XCTAssertTrue(
            contents.contains("Spacer(minLength: 0)"),
            "The idle setup stage should include a trailing spacer so the hero stays pinned to the top instead of floating in the middle of the canvas."
        )
        XCTAssertTrue(
            contents.contains(".frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)"),
            "The setup stage should align its content to the top to match the other dashboard pages."
        )
    }
}
