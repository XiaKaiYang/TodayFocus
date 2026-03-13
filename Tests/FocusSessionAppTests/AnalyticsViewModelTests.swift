import XCTest
import SwiftData
import FocusSessionCore
@testable import FocusSession

@MainActor
final class AnalyticsViewModelTests: XCTestCase {
    func testLoadBuildsDayScopedSummaryTrendTasksAndRecentSessions() throws {
        let calendar = makeCalendar()
        let now = makeDate(year: 2026, month: 3, day: 12, hour: 12, minute: 0)
        let container = try FocusSessionModelContainer.makeInMemory()
        let context = ModelContext(container)
        let sessionRepository = FocusSessionRepository(modelContext: context)
        try sessionRepository.save(
            FocusSessionRecord(
                intention: "Launch review",
                startedAt: makeDate(year: 2026, month: 3, day: 12, hour: 10, minute: 0),
                endedAt: makeDate(year: 2026, month: 3, day: 12, hour: 10, minute: 45),
                notes: "Strong finish.",
                mood: .focused
            )
        )
        try sessionRepository.save(
            FocusSessionRecord(
                intention: "Refine onboarding",
                startedAt: makeDate(year: 2026, month: 3, day: 10, hour: 15, minute: 0),
                endedAt: makeDate(year: 2026, month: 3, day: 10, hour: 15, minute: 30),
                notes: "Week bucket note.",
                mood: .neutral
            )
        )
        try sessionRepository.save(
            FocusSessionRecord(
                intention: "Inbox zero",
                startedAt: makeDate(year: 2026, month: 3, day: 12, hour: 8, minute: 0),
                endedAt: makeDate(year: 2026, month: 3, day: 12, hour: 8, minute: 20),
                notes: nil,
                mood: .distracted
            )
        )
        try sessionRepository.save(
            FocusSessionRecord(
                intention: "Earlier this month",
                startedAt: makeDate(year: 2026, month: 3, day: 2, hour: 9, minute: 0),
                endedAt: makeDate(year: 2026, month: 3, day: 2, hour: 9, minute: 25),
                notes: "Month bucket note.",
                mood: .focused
            )
        )
        try sessionRepository.save(
            FocusSessionRecord(
                intention: "Interrupted block",
                startedAt: makeDate(year: 2026, month: 3, day: 12, hour: 11, minute: 0),
                endedAt: makeDate(year: 2026, month: 3, day: 12, hour: 11, minute: 25),
                wasCompleted: false
            )
        )

        let viewModel = AnalyticsViewModel(
            focusSessionRepository: sessionRepository,
            now: { now },
            calendar: calendar
        )

        XCTAssertEqual(viewModel.selectedScope, .day)
        XCTAssertEqual(viewModel.summary.focusTimeSeconds, 3900)
        XCTAssertEqual(viewModel.summary.completedSessionsCount, 2)
        XCTAssertEqual(viewModel.summary.averageCompletedSessionSeconds, 1950)
        XCTAssertEqual(viewModel.summary.notesCapturedCount, 1)
        XCTAssertEqual(viewModel.trendBuckets.map(\.totalSeconds), [2700, 1200])
        XCTAssertEqual(viewModel.focusRows.map(\.title), ["Launch review", "Inbox zero"])
        XCTAssertEqual(viewModel.focusRows.map(\.totalSeconds), [2700, 1200])
        XCTAssertEqual(viewModel.recentSessions.map(\.intention), ["Launch review", "Inbox zero"])
        XCTAssertEqual(viewModel.moodRows.map(\.sessionCount), [1, 0, 1])
        XCTAssertNil(viewModel.errorMessage)
    }

    func testChangingScopeRecomputesWeekAndMonthBuckets() throws {
        let calendar = makeCalendar()
        let now = makeDate(year: 2026, month: 3, day: 12, hour: 12, minute: 0)
        let container = try FocusSessionModelContainer.makeInMemory()
        let context = ModelContext(container)
        let sessionRepository = FocusSessionRepository(modelContext: context)
        try sessionRepository.save(
            FocusSessionRecord(
                intention: "Focused block",
                startedAt: makeDate(year: 2026, month: 3, day: 12, hour: 9, minute: 0),
                endedAt: makeDate(year: 2026, month: 3, day: 12, hour: 9, minute: 30),
                mood: .focused
            )
        )
        try sessionRepository.save(
            FocusSessionRecord(
                intention: "Neutral block",
                startedAt: makeDate(year: 2026, month: 3, day: 10, hour: 10, minute: 0),
                endedAt: makeDate(year: 2026, month: 3, day: 10, hour: 10, minute: 20),
                mood: .neutral
            )
        )
        try sessionRepository.save(
            FocusSessionRecord(
                intention: "Distracted block",
                startedAt: makeDate(year: 2026, month: 3, day: 2, hour: 11, minute: 0),
                endedAt: makeDate(year: 2026, month: 3, day: 2, hour: 11, minute: 15),
                mood: .distracted
            )
        )
        try sessionRepository.save(
            FocusSessionRecord(
                intention: "Unsubmitted reflection",
                startedAt: makeDate(year: 2026, month: 3, day: 12, hour: 11, minute: 20),
                endedAt: makeDate(year: 2026, month: 3, day: 12, hour: 11, minute: 35),
                mood: .focused,
                wasCompleted: false
            )
        )

        let viewModel = AnalyticsViewModel(
            focusSessionRepository: sessionRepository,
            now: { now },
            calendar: calendar
        )

        viewModel.setScope(.week)

        XCTAssertEqual(viewModel.summary.focusTimeSeconds, 3000)
        XCTAssertEqual(viewModel.summary.completedSessionsCount, 2)
        XCTAssertEqual(viewModel.trendBuckets.count, 7)
        XCTAssertEqual(viewModel.trendBuckets.map(\.totalSeconds), [0, 1200, 0, 1800, 0, 0, 0])
        XCTAssertEqual(viewModel.moodRows.map(\.sessionCount), [1, 1, 0])

        viewModel.setScope(.month)

        XCTAssertEqual(viewModel.summary.focusTimeSeconds, 3900)
        XCTAssertEqual(viewModel.summary.completedSessionsCount, 3)
        XCTAssertEqual(viewModel.summary.averageCompletedSessionSeconds, 1300)
        XCTAssertEqual(viewModel.trendBuckets.count, 6)
        XCTAssertEqual(viewModel.trendBuckets.map(\.totalSeconds), [0, 900, 3000, 0, 0, 0])
        XCTAssertEqual(viewModel.moodRows.map(\.sessionCount), [1, 1, 1])
    }

    func testAnalyticsDashboardUsesPieChartsWithHoverDetails() throws {
        let dashboardSource = try String(
            contentsOfFile: "/Users/xiakaiyang/Documents/New project/Apps/FocusSessionApp/UI/Analytics/AnalyticsDashboardView.swift",
            encoding: .utf8
        )
        let chartsSource = try String(
            contentsOfFile: "/Users/xiakaiyang/Documents/New project/Apps/FocusSessionApp/UI/Analytics/AnalyticsCharts.swift",
            encoding: .utf8
        )

        XCTAssertTrue(dashboardSource.contains("DashboardTimeNavigator"))
        XCTAssertTrue(dashboardSource.contains("AnalyticsTrendPieChartView"))
        XCTAssertTrue(dashboardSource.contains("TaskBreakdownPieChartView"))
        XCTAssertTrue(dashboardSource.contains("Focus Time"))
        XCTAssertTrue(dashboardSource.contains("Completed Sessions"))
        XCTAssertTrue(dashboardSource.contains("Notes Captured"))
        XCTAssertTrue(dashboardSource.contains("Session Mood"))
        XCTAssertTrue(dashboardSource.contains("viewModel.moodRows"))
        XCTAssertTrue(chartsSource.contains("onHover"))
        XCTAssertTrue(chartsSource.contains("AnalyticsPieSliceShape"))
    }

    func testDashboardTimeScopeUsesNaturalMonthsAcrossBoundaries() {
        let calendar = makeCalendar()
        let januaryDate = makeDate(year: 2026, month: 1, day: 31, hour: 12, minute: 0)

        let januaryWindow = DashboardTimeScope.month.timeWindow(containing: januaryDate, calendar: calendar)
        let shiftedReference = DashboardTimeScope.month.shiftedReferenceDate(
            from: januaryDate,
            direction: 1,
            calendar: calendar
        )
        let februaryWindow = DashboardTimeScope.month.timeWindow(containing: shiftedReference, calendar: calendar)

        XCTAssertEqual(januaryWindow.start, makeDate(year: 2026, month: 1, day: 1, hour: 0, minute: 0))
        XCTAssertEqual(januaryWindow.end, makeDate(year: 2026, month: 2, day: 1, hour: 0, minute: 0))
        XCTAssertEqual(februaryWindow.start, makeDate(year: 2026, month: 2, day: 1, hour: 0, minute: 0))
        XCTAssertEqual(februaryWindow.end, makeDate(year: 2026, month: 3, day: 1, hour: 0, minute: 0))
    }

    func testDashboardTimeScopeBuildsCurrentWeekAndMonthTitlesAndStrips() {
        let calendar = makeCalendar()
        let now = makeDate(year: 2026, month: 3, day: 12, hour: 12, minute: 0)

        XCTAssertEqual(
            DashboardTimeScope.week.title(for: now, now: now, calendar: calendar),
            "This week"
        )
        XCTAssertEqual(
            DashboardTimeScope.month.title(for: now, now: now, calendar: calendar),
            "This month"
        )

        guard case let .weeks(weeks) = DashboardTimeScope.week.timeStrip(
            for: now,
            now: now,
            calendar: calendar
        ) else {
            return XCTFail("Week scope should produce week cards.")
        }
        XCTAssertEqual(weeks.count, 5)
        XCTAssertEqual(weeks.map(\.startDate), [
            makeDate(year: 2026, month: 2, day: 23, hour: 0, minute: 0),
            makeDate(year: 2026, month: 3, day: 2, hour: 0, minute: 0),
            makeDate(year: 2026, month: 3, day: 9, hour: 0, minute: 0),
            makeDate(year: 2026, month: 3, day: 16, hour: 0, minute: 0),
            makeDate(year: 2026, month: 3, day: 23, hour: 0, minute: 0)
        ])
        XCTAssertEqual(weeks.firstIndex(where: \.isSelected), 2)

        guard case let .months(months) = DashboardTimeScope.month.timeStrip(
            for: now,
            now: now,
            calendar: calendar
        ) else {
            return XCTFail("Month scope should produce month cards.")
        }
        XCTAssertEqual(months.count, 5)
        XCTAssertEqual(months.map(\.date), [
            makeDate(year: 2026, month: 1, day: 1, hour: 0, minute: 0),
            makeDate(year: 2026, month: 2, day: 1, hour: 0, minute: 0),
            makeDate(year: 2026, month: 3, day: 1, hour: 0, minute: 0),
            makeDate(year: 2026, month: 4, day: 1, hour: 0, minute: 0),
            makeDate(year: 2026, month: 5, day: 1, hour: 0, minute: 0)
        ])
        XCTAssertEqual(months.firstIndex(where: \.isSelected), 2)
    }

    func testDashboardWeekdayItemsFollowCalendarWeekContainingSelectedDate() {
        let calendar = makeCalendar()
        let now = makeDate(year: 2026, month: 3, day: 12, hour: 12, minute: 0)

        let items = DashboardWeekdayItem.week(
            containing: now,
            selectedDate: now,
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(items.count, 7)
        XCTAssertEqual(items.first?.date, makeDate(year: 2026, month: 3, day: 9, hour: 0, minute: 0))
        XCTAssertEqual(items.last?.date, makeDate(year: 2026, month: 3, day: 15, hour: 0, minute: 0))
        XCTAssertEqual(items.first(where: \.isSelected)?.date, makeDate(year: 2026, month: 3, day: 12, hour: 0, minute: 0))
        XCTAssertEqual(items.first(where: \.isToday)?.date, makeDate(year: 2026, month: 3, day: 12, hour: 0, minute: 0))
    }

    func testAnalyticsViewModelPublishesScopeAwareTimeStrip() throws {
        let calendar = makeCalendar()
        let now = makeDate(year: 2026, month: 3, day: 12, hour: 12, minute: 0)
        let container = try FocusSessionModelContainer.makeInMemory()
        let context = ModelContext(container)
        let repository = FocusSessionRepository(modelContext: context)
        try repository.save(
            FocusSessionRecord(
                intention: "Current session",
                startedAt: makeDate(year: 2026, month: 3, day: 12, hour: 9, minute: 0),
                endedAt: makeDate(year: 2026, month: 3, day: 12, hour: 9, minute: 25)
            )
        )

        let viewModel = AnalyticsViewModel(
            focusSessionRepository: repository,
            now: { now },
            calendar: calendar
        )

        guard case let .days(days) = viewModel.timeStrip else {
            return XCTFail("Day scope should keep the weekday strip.")
        }
        XCTAssertEqual(days.count, 7)

        viewModel.setScope(.week)

        XCTAssertEqual(viewModel.referenceTitle, "This week")
        guard case let .weeks(weeks) = viewModel.timeStrip else {
            return XCTFail("Week scope should expose week cards.")
        }
        XCTAssertEqual(weeks.count, 5)
        XCTAssertEqual(weeks.firstIndex(where: \.isSelected), 2)

        viewModel.setScope(.month)

        XCTAssertEqual(viewModel.referenceTitle, "This month")
        guard case let .months(months) = viewModel.timeStrip else {
            return XCTFail("Month scope should expose month cards.")
        }
        XCTAssertEqual(months.count, 5)
        XCTAssertEqual(months.firstIndex(where: \.isSelected), 2)
    }

    private func makeCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        calendar.firstWeekday = 2
        return calendar
    }

    private func makeDate(year: Int, month: Int, day: Int, hour: Int, minute: Int) -> Date {
        let components = DateComponents(
            calendar: makeCalendar(),
            timeZone: TimeZone(secondsFromGMT: 0),
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute
        )
        return components.date ?? Date(timeIntervalSince1970: 0)
    }
}
