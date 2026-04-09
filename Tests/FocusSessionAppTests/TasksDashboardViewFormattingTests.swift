import XCTest
@testable import FocusSession

final class TasksDashboardViewFormattingTests: XCTestCase {
    func testTasksDashboardSourceShowsRecurringAndLinkedBadgeMetadataForAnnotatedTasks() throws {
        let source = try String(
            contentsOfFile: "/Users/xiakaiyang/Documents/New project/Apps/FocusSessionApp/UI/Tasks/TasksDashboardView.swift",
            encoding: .utf8
        )

        XCTAssertTrue(source.contains("taskRecurrenceBadge(for: task)"))
        XCTAssertTrue(source.contains("linkedTaskBadge(for: task)"))
        XCTAssertTrue(source.contains("\"∞\""))
        XCTAssertTrue(source.contains("\"repeat\""))
        XCTAssertTrue(source.contains("\"link\""))
        XCTAssertTrue(source.contains("recurrenceProgressText"))
        XCTAssertTrue(source.contains("task.isLinkedToSubtask"))
    }

    func testTasksDashboardSourceAddsBottomTodayTomorrowSwitcherAndTomorrowPreviewRules() throws {
        let source = try String(
            contentsOfFile: "/Users/xiakaiyang/Documents/New project/Apps/FocusSessionApp/UI/Tasks/TasksDashboardView.swift",
            encoding: .utf8
        )

        XCTAssertTrue(source.contains("overlay(alignment: .bottom)"))
        XCTAssertTrue(source.contains(".frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)"))
        XCTAssertTrue(source.contains("TasksDashboardScope.allCases"))
        XCTAssertTrue(source.contains("\"sun.max\""))
        XCTAssertTrue(source.contains("\"calendar\""))
        XCTAssertTrue(source.contains("AppGlassCapsuleSurface"))
        XCTAssertTrue(source.contains("AppSurfaceTheme.taskSelectorWarmGlyph"))
        XCTAssertTrue(source.contains("AppSurfaceTheme.primaryText"))
        XCTAssertTrue(source.contains("AppSurfaceTheme.secondaryText"))
        XCTAssertFalse(source.contains("Circle()"))
        XCTAssertTrue(source.contains("HStack(spacing: 14)"))
        XCTAssertTrue(source.contains(".frame(width: 20, height: 20)"))
        XCTAssertTrue(source.contains(".frame(width: 34, height: 30)"))
        XCTAssertTrue(source.contains(".padding(.horizontal, 14)"))
        XCTAssertTrue(source.contains(".padding(.vertical, 8)"))
        XCTAssertTrue(source.contains("selectedScope = .today"))
        XCTAssertTrue(source.contains("if selectedScope == .today"))
        XCTAssertTrue(source.contains("scope == .today && !task.isCompleted"))
        XCTAssertTrue(source.contains("Today"))
        XCTAssertTrue(source.contains("Tomorrow"))
    }

    func testTasksDashboardSourceAddsParentSubtaskRenderingAndDragState() throws {
        let source = try String(
            contentsOfFile: "/Users/xiakaiyang/Documents/New project/Apps/FocusSessionApp/UI/Tasks/TasksDashboardView.swift",
            encoding: .utf8
        )

        XCTAssertTrue(source.contains("expandedParentTaskIDs"))
        XCTAssertTrue(source.contains("draggedTaskID"))
        XCTAssertTrue(source.contains("draggedTaskTranslation"))
        XCTAssertTrue(source.contains("taskRowFrames"))
        XCTAssertTrue(source.contains("taskSubtaskRow("))
        XCTAssertTrue(source.contains("\"list.bullet.indent\""))
        XCTAssertTrue(source.contains("task.hasSubtasks"))
        XCTAssertTrue(source.contains("viewModel.toggleTaskSubtaskCompletion("))
        XCTAssertTrue(source.contains("viewModel.moveTask("))
        XCTAssertTrue(source.contains(".scrollDisabled(draggedTaskID != nil)"))
        XCTAssertTrue(source.contains("DragGesture(minimumDistance: 4"))
    }

    func testTasksDashboardSourceAddsSubtaskSelectFlowForParentTasks() throws {
        let source = try String(
            contentsOfFile: "/Users/xiakaiyang/Documents/New project/Apps/FocusSessionApp/UI/Tasks/TasksDashboardView.swift",
            encoding: .utf8
        )

        XCTAssertTrue(source.contains("task.subtasks.filter { !$0.isCompleted }"))
        XCTAssertTrue(source.contains("remainingSubtasks.count == 1"))
        XCTAssertTrue(source.contains("viewModel.startFocus(for: task, subtask:"))
        XCTAssertTrue(source.contains(".popover("))
    }

    func testTasksDashboardSourceUsesFullCreateCopy() throws {
        let source = try String(
            contentsOfFile: "/Users/xiakaiyang/Documents/New project/Apps/FocusSessionApp/UI/Tasks/TasksDashboardView.swift",
            encoding: .utf8
        )

        XCTAssertTrue(source.contains("Button(\"Create\")"))
        XCTAssertTrue(source.contains("Text(viewModel.isEditingTask ? \"Edit\" : \"Create\")"))
        XCTAssertTrue(source.contains("Button(viewModel.isEditingTask ? \"Save\" : \"Create\")"))
        XCTAssertFalse(source.contains("\"Creat\""))
    }

    func testScheduleTextUsesTodayForReferenceDayRanges() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let referenceDate = date(
            year: 2026,
            month: 3,
            day: 10,
            hour: 8,
            minute: 0,
            calendar: calendar
        )
        let startAt = date(
            year: 2026,
            month: 3,
            day: 10,
            hour: 9,
            minute: 30,
            calendar: calendar
        )
        let endAt = date(
            year: 2026,
            month: 3,
            day: 10,
            hour: 10,
            minute: 15,
            calendar: calendar
        )

        XCTAssertEqual(
            TasksDashboardView.scheduleText(
                startAt: startAt,
                endAt: endAt,
                calendar: calendar,
                referenceDate: referenceDate
            ),
            "今日 09:30 - 10:15"
        )
    }

    func testScheduleTextKeepsDateForNonTodayRanges() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let referenceDate = date(
            year: 2026,
            month: 3,
            day: 10,
            hour: 8,
            minute: 0,
            calendar: calendar
        )
        let startAt = date(
            year: 2026,
            month: 3,
            day: 11,
            hour: 9,
            minute: 30,
            calendar: calendar
        )
        let endAt = date(
            year: 2026,
            month: 3,
            day: 11,
            hour: 10,
            minute: 15,
            calendar: calendar
        )

        XCTAssertEqual(
            TasksDashboardView.scheduleText(
                startAt: startAt,
                endAt: endAt,
                calendar: calendar,
                referenceDate: referenceDate
            ),
            "3月11日 09:30 - 10:15"
        )
    }

    private func date(
        year: Int,
        month: Int,
        day: Int,
        hour: Int,
        minute: Int,
        calendar: Calendar
    ) -> Date {
        calendar.date(
            from: DateComponents(
                timeZone: calendar.timeZone,
                year: year,
                month: month,
                day: day,
                hour: hour,
                minute: minute
            )
        )!
    }
}
