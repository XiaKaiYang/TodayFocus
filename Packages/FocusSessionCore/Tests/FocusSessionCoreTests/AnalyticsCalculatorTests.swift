import XCTest
@testable import FocusSessionCore

final class AnalyticsCalculatorTests: XCTestCase {
    func testOverviewAggregatesCompletedSessionsAcrossTodayWeekAndAllTime() {
        let calendar = makeCalendar()
        let now = makeDate(year: 2026, month: 3, day: 8, hour: 12, minute: 0)
        let records = [
            FocusSessionRecord(
                intention: "Write launch notes",
                startedAt: makeDate(year: 2026, month: 3, day: 8, hour: 9, minute: 0),
                endedAt: makeDate(year: 2026, month: 3, day: 8, hour: 10, minute: 0)
            ),
            FocusSessionRecord(
                intention: "Polish onboarding",
                startedAt: makeDate(year: 2026, month: 3, day: 6, hour: 14, minute: 0),
                endedAt: makeDate(year: 2026, month: 3, day: 6, hour: 14, minute: 30)
            ),
            FocusSessionRecord(
                intention: "Backlog cleanup",
                startedAt: makeDate(year: 2026, month: 2, day: 25, hour: 11, minute: 0),
                endedAt: makeDate(year: 2026, month: 2, day: 25, hour: 11, minute: 45)
            ),
            FocusSessionRecord(
                intention: "Interrupted block",
                startedAt: makeDate(year: 2026, month: 3, day: 8, hour: 11, minute: 0),
                endedAt: makeDate(year: 2026, month: 3, day: 8, hour: 11, minute: 20),
                wasCompleted: false
            )
        ]

        let overview = AnalyticsCalculator.overview(
            records: records,
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(overview.todayTotalSeconds, 3600)
        XCTAssertEqual(overview.weekTotalSeconds, 5400)
        XCTAssertEqual(overview.allTimeTotalSeconds, 8100)
        XCTAssertEqual(overview.completedSessionsCount, 3)
        XCTAssertEqual(overview.averageCompletedSessionSeconds, 2700)
    }

    func testDailyFocusPointsFillMissingDaysInChronologicalOrder() {
        let calendar = makeCalendar()
        let now = makeDate(year: 2026, month: 3, day: 8, hour: 12, minute: 0)
        let records = [
            FocusSessionRecord(
                intention: "Deep work",
                startedAt: makeDate(year: 2026, month: 3, day: 8, hour: 9, minute: 0),
                endedAt: makeDate(year: 2026, month: 3, day: 8, hour: 10, minute: 0)
            ),
            FocusSessionRecord(
                intention: "Refactor",
                startedAt: makeDate(year: 2026, month: 3, day: 5, hour: 16, minute: 0),
                endedAt: makeDate(year: 2026, month: 3, day: 5, hour: 16, minute: 30)
            )
        ]

        let points = AnalyticsCalculator.dailyFocusPoints(
            records: records,
            days: 7,
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(points.count, 7)
        XCTAssertEqual(
            points.map(\.totalSeconds),
            [0, 0, 0, 1800, 0, 0, 3600]
        )
        XCTAssertEqual(
            points.map(\.sessionCount),
            [0, 0, 0, 1, 0, 0, 1]
        )
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
