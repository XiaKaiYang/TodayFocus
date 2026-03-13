import Foundation

public struct AnalyticsOverview: Equatable, Sendable {
    public var todayTotalSeconds: Int
    public var weekTotalSeconds: Int
    public var allTimeTotalSeconds: Int
    public var completedSessionsCount: Int
    public var averageCompletedSessionSeconds: Int

    public init(
        todayTotalSeconds: Int = 0,
        weekTotalSeconds: Int = 0,
        allTimeTotalSeconds: Int = 0,
        completedSessionsCount: Int = 0,
        averageCompletedSessionSeconds: Int = 0
    ) {
        self.todayTotalSeconds = todayTotalSeconds
        self.weekTotalSeconds = weekTotalSeconds
        self.allTimeTotalSeconds = allTimeTotalSeconds
        self.completedSessionsCount = completedSessionsCount
        self.averageCompletedSessionSeconds = averageCompletedSessionSeconds
    }
}

public struct DailyFocusPoint: Equatable, Identifiable, Sendable {
    public var dayStart: Date
    public var totalSeconds: Int
    public var sessionCount: Int

    public var id: Date { dayStart }

    public init(dayStart: Date, totalSeconds: Int, sessionCount: Int) {
        self.dayStart = dayStart
        self.totalSeconds = totalSeconds
        self.sessionCount = sessionCount
    }
}

public enum AnalyticsCalculator {
    public static func overview(
        records: [FocusSessionRecord],
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> AnalyticsOverview {
        let completedRecords = completed(records)
        let allTimeTotalSeconds = completedRecords.reduce(0) { $0 + $1.durationSeconds }
        let completedSessionsCount = completedRecords.count
        let averageCompletedSessionSeconds = completedSessionsCount == 0
            ? 0
            : allTimeTotalSeconds / completedSessionsCount

        let todayInterval = dayInterval(for: now, calendar: calendar)
        let weekInterval = calendar.dateInterval(of: .weekOfYear, for: now)

        let todayTotalSeconds = completedRecords
            .filter { todayInterval.contains($0.startedAt) }
            .reduce(0) { $0 + $1.durationSeconds }
        let weekTotalSeconds = completedRecords
            .filter { weekInterval?.contains($0.startedAt) == true }
            .reduce(0) { $0 + $1.durationSeconds }

        return AnalyticsOverview(
            todayTotalSeconds: todayTotalSeconds,
            weekTotalSeconds: weekTotalSeconds,
            allTimeTotalSeconds: allTimeTotalSeconds,
            completedSessionsCount: completedSessionsCount,
            averageCompletedSessionSeconds: averageCompletedSessionSeconds
        )
    }

    public static func dailyFocusPoints(
        records: [FocusSessionRecord],
        days: Int = 7,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> [DailyFocusPoint] {
        guard days > 0 else {
            return []
        }

        let completedRecords = completed(records)
        let today = calendar.startOfDay(for: now)
        let firstDay = calendar.date(byAdding: .day, value: -(days - 1), to: today) ?? today

        let totalsByDay = Dictionary(grouping: completedRecords) {
            calendar.startOfDay(for: $0.startedAt)
        }

        return (0..<days).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: firstDay) else {
                return nil
            }
            let dayRecords = totalsByDay[day, default: []]
            return DailyFocusPoint(
                dayStart: day,
                totalSeconds: dayRecords.reduce(0) { $0 + $1.durationSeconds },
                sessionCount: dayRecords.count
            )
        }
    }

    private static func completed(_ records: [FocusSessionRecord]) -> [FocusSessionRecord] {
        records.filter(\.wasCompleted)
    }

    private static func dayInterval(for date: Date, calendar: Calendar) -> DateInterval {
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start
        return DateInterval(start: start, end: end)
    }
}
