import XCTest
import FocusSessionCore
@testable import FocusSession

final class CurrentSessionSceneConfigurationTests: XCTestCase {
    func testSetupPhaseStaysMinimal() {
        let configuration = CurrentSessionSceneConfiguration.make(phase: .idle)

        XCTAssertTrue(configuration.showsFocusClockStage)
        XCTAssertFalse(configuration.showsNotesWorkspace)
        XCTAssertFalse(configuration.showsNotesWorkspaceChrome)
        XCTAssertFalse(configuration.showsHistoryNotes)
        XCTAssertTrue(configuration.showsDurationControls)
        XCTAssertFalse(configuration.showsRunningStatusBar)
    }

    func testRunningPhaseShowsNotesWorkspaceAfterTransition() {
        let configuration = CurrentSessionSceneConfiguration.make(phase: .focusing)

        XCTAssertFalse(configuration.showsFocusClockStage)
        XCTAssertTrue(configuration.showsNotesWorkspace)
        XCTAssertFalse(configuration.showsNotesWorkspaceChrome)
        XCTAssertFalse(configuration.showsEmbeddedWorkspaceBackground)
        XCTAssertFalse(configuration.showsHistoryNotes)
        XCTAssertFalse(configuration.showsDurationControls)
        XCTAssertTrue(configuration.showsRunningStatusBar)
    }

    func testCompletedPhaseReturnsToClockStage() {
        let configuration = CurrentSessionSceneConfiguration.make(phase: .completed)

        XCTAssertTrue(configuration.showsFocusClockStage)
        XCTAssertFalse(configuration.showsNotesWorkspace)
        XCTAssertFalse(configuration.showsNotesWorkspaceChrome)
        XCTAssertFalse(configuration.showsHistoryNotes)
        XCTAssertTrue(configuration.showsDurationControls)
        XCTAssertFalse(configuration.showsRunningStatusBar)
    }

    func testWindowChromeDisablesWindowBackgroundDragging() {
        let settings = WindowChromeSettings.default

        XCTAssertFalse(settings.isMovableByWindowBackground)
        XCTAssertTrue(settings.titlebarAppearsTransparent)
        XCTAssertTrue(settings.isOpaque)
        XCTAssertEqual(settings.backgroundColor.alphaComponent, 1.0, accuracy: 0.001)
    }

    func testRuntimeNoteComposerOnlyRevealsDuringActiveSessionHoverOrEditing() {
        XCTAssertFalse(
            CurrentSessionSceneConfiguration.shouldRevealRuntimeNoteComposer(
                phase: .focusing,
                isHoveringCenteredTimer: false,
                isEditingNotes: false
            )
        )
        XCTAssertTrue(
            CurrentSessionSceneConfiguration.shouldRevealRuntimeNoteComposer(
                phase: .focusing,
                isHoveringCenteredTimer: true,
                isEditingNotes: false
            )
        )
        XCTAssertTrue(
            CurrentSessionSceneConfiguration.shouldRevealRuntimeNoteComposer(
                phase: .focusPaused,
                isHoveringCenteredTimer: false,
                isEditingNotes: true
            )
        )
        XCTAssertFalse(
            CurrentSessionSceneConfiguration.shouldRevealRuntimeNoteComposer(
                phase: .completed,
                isHoveringCenteredTimer: true,
                isEditingNotes: false
            )
        )
    }

    func testRunningPhaseShowsNotesWorkspaceImmediately() {
        let configuration = CurrentSessionSceneConfiguration.make(phase: .focusPaused)

        XCTAssertTrue(configuration.showsNotesWorkspace)
        XCTAssertTrue(configuration.showsRunningStatusBar)
        XCTAssertFalse(configuration.showsFocusClockStage)
    }
}
