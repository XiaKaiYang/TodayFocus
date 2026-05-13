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
        XCTAssertTrue(source.contains("提交"))
        XCTAssertTrue(source.contains("提交并继续"))
    }

    func testCurrentSessionViewUsesTodayTaskOnlySelectorCopy() throws {
        let source = try String(
            contentsOfFile: "/Users/xiakaiyang/Documents/New project/Apps/FocusSessionApp/UI/CurrentSession/CurrentSessionView.swift",
            encoding: .utf8
        )

        XCTAssertTrue(source.contains("请先在“今日”里创建任务"))
        XCTAssertTrue(source.contains("请选择一个“今日”任务"))
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
