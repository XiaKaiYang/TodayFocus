import XCTest

final class CurrentSessionViewSourceTests: XCTestCase {
    func testCurrentSessionViewIncludesReflectionComposerOverlay() throws {
        let source = try String(
            contentsOfFile: "/Users/xiakaiyang/Documents/New project/Apps/FocusSessionApp/UI/CurrentSession/CurrentSessionView.swift",
            encoding: .utf8
        )

        XCTAssertTrue(source.contains("showReflectionComposer"))
        XCTAssertTrue(source.contains("🥳"))
        XCTAssertTrue(source.contains("🤩"))
        XCTAssertTrue(source.contains("😐"))
        XCTAssertTrue(source.contains("😞"))
        XCTAssertTrue(source.contains("Submit"))
        XCTAssertTrue(source.contains("Submit & Continue"))
    }

    func testCurrentSessionViewUsesTodayTaskOnlySelectorCopy() throws {
        let source = try String(
            contentsOfFile: "/Users/xiakaiyang/Documents/New project/Apps/FocusSessionApp/UI/CurrentSession/CurrentSessionView.swift",
            encoding: .utf8
        )

        XCTAssertTrue(source.contains("Create a task in Today first"))
        XCTAssertTrue(source.contains("Select a Today task"))
        XCTAssertFalse(source.contains("Create a task in Tasks first"))
        XCTAssertFalse(source.contains("Select a task"))
    }

    func testCurrentSessionViewRendersFlattenedSubtaskSelectorTitles() throws {
        let source = try String(
            contentsOfFile: "/Users/xiakaiyang/Documents/New project/Apps/FocusSessionApp/UI/CurrentSession/CurrentSessionView.swift",
            encoding: .utf8
        )

        XCTAssertTrue(source.contains("availableTaskSelections"))
        XCTAssertTrue(source.contains("selection.selectorTitle"))
        XCTAssertTrue(source.contains("viewModel.selectedTaskSelection"))
    }
}
