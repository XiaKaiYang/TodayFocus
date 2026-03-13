import Foundation
import SwiftData
import FocusSessionCore

enum DashboardTimeScope: String, CaseIterable, Identifiable {
    case day
    case week
    case month

    var id: String { rawValue }

    var title: String {
        switch self {
        case .day:
            "Day"
        case .week:
            "Week"
        case .month:
            "Month"
        }
    }

    var noteListEmptyTitle: String {
        switch self {
        case .day:
            "Nothing saved today"
        case .week:
            "Nothing saved this week"
        case .month:
            "Nothing saved this month"
        }
    }

    var noteListEmptyMessage: String {
        switch self {
        case .day:
            "Notes from sessions that end today will appear here."
        case .week:
            "Notes from sessions that end this week will appear here."
        case .month:
            "Notes from sessions that end this month will appear here."
        }
    }

    var noteDetailEmptyTitle: String {
        switch self {
        case .day:
            "No Notes Today"
        case .week:
            "No Notes This Week"
        case .month:
            "No Notes This Month"
        }
    }

    var noteDetailEmptyMessage: String {
        switch self {
        case .day:
            "Finish a session today and capture a note. It will show up here right away."
        case .week:
            "Finish a session this week and capture a note. It will show up here right away."
        case .month:
            "Finish a session this month and capture a note. It will show up here right away."
        }
    }

    var analyticsTrendTitle: String {
        switch self {
        case .day:
            "Today's Sessions"
        case .week:
            "This Week"
        case .month:
            "This Month by Week"
        }
    }

    var analyticsTopTasksTitle: String {
        switch self {
        case .day:
            "Top Tasks Today"
        case .week:
            "Top Tasks This Week"
        case .month:
            "Top Tasks This Month"
        }
    }

    var analyticsRecentTitle: String {
        switch self {
        case .day:
            "Completed Sessions Today"
        case .week:
            "Completed Sessions This Week"
        case .month:
            "Completed Sessions This Month"
        }
    }

    func timeWindow(containing date: Date, calendar: Calendar) -> DashboardTimeWindow {
        let anchorDate = calendar.startOfDay(for: date)
        let interval: DateInterval

        switch self {
        case .day:
            let start = anchorDate
            let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start
            interval = DateInterval(start: start, end: end)
        case .week:
            interval = calendar.dateInterval(of: .weekOfYear, for: anchorDate)
                ?? DateInterval(start: anchorDate, duration: 7 * 24 * 60 * 60)
        case .month:
            interval = calendar.dateInterval(of: .month, for: anchorDate)
                ?? DateInterval(start: anchorDate, duration: 31 * 24 * 60 * 60)
        }

        return DashboardTimeWindow(scope: self, start: interval.start, end: interval.end)
    }

    func shiftedReferenceDate(from date: Date, direction: Int, calendar: Calendar) -> Date {
        switch self {
        case .day:
            calendar.date(byAdding: .day, value: direction, to: date) ?? date
        case .week:
            calendar.date(byAdding: .weekOfYear, value: direction, to: date) ?? date
        case .month:
            calendar.date(byAdding: .month, value: direction, to: date) ?? date
        }
    }

    func timeStrip(for referenceDate: Date, now: Date, calendar: Calendar) -> DashboardTimeStrip {
        switch self {
        case .day:
            return .days(
                DashboardWeekdayItem.week(
                    containing: referenceDate,
                    selectedDate: referenceDate,
                    now: now,
                    calendar: calendar
                )
            )
        case .week:
            let selectedWeek = timeWindow(containing: referenceDate, calendar: calendar)
            let selectedWeekStart = calendar.startOfDay(for: selectedWeek.start)

            return .weeks(
                (-2...2).compactMap { offset in
                    guard let date = calendar.date(byAdding: .weekOfYear, value: offset, to: selectedWeekStart) else {
                        return nil
                    }
                    let window = timeWindow(containing: date, calendar: calendar)
                    let inclusiveEnd = calendar.date(byAdding: .day, value: -1, to: window.end) ?? window.start
                    return DashboardWeekItem(
                        startDate: window.start,
                        endDate: window.end,
                        topText: "\(window.start.formatted(.dateTime.month(.abbreviated).day())) ->",
                        bottomText: inclusiveEnd.formatted(.dateTime.month(.abbreviated).day()),
                        isSelected: calendar.isDate(window.start, inSameDayAs: selectedWeekStart)
                    )
                }
            )
        case .month:
            let selectedMonth = timeWindow(containing: referenceDate, calendar: calendar)
            let selectedMonthStart = calendar.startOfDay(for: selectedMonth.start)

            return .months(
                (-2...2).compactMap { offset in
                    guard let date = calendar.date(byAdding: .month, value: offset, to: selectedMonthStart) else {
                        return nil
                    }
                    let window = timeWindow(containing: date, calendar: calendar)
                    return DashboardMonthItem(
                        date: window.start,
                        yearText: window.start.formatted(.dateTime.year()),
                        monthText: window.start.formatted(.dateTime.month(.wide)),
                        isSelected: calendar.isDate(window.start, equalTo: selectedMonthStart, toGranularity: .month)
                    )
                }
            )
        }
    }

    func title(for referenceDate: Date, now: Date, calendar: Calendar) -> String {
        switch self {
        case .day:
            let normalizedReference = calendar.startOfDay(for: referenceDate)
            let normalizedNow = calendar.startOfDay(for: now)
            if calendar.isDate(normalizedReference, inSameDayAs: normalizedNow) {
                return "Today"
            }
            return normalizedReference.formatted(.dateTime.month(.wide).day())
        case .week:
            let window = timeWindow(containing: referenceDate, calendar: calendar)
            let currentWindow = timeWindow(containing: now, calendar: calendar)
            if window == currentWindow {
                return "This week"
            }
            let inclusiveEnd = calendar.date(byAdding: .day, value: -1, to: window.end) ?? window.start
            return "\(window.start.formatted(.dateTime.month(.abbreviated).day())) - \(inclusiveEnd.formatted(.dateTime.month(.abbreviated).day()))"
        case .month:
            let window = timeWindow(containing: referenceDate, calendar: calendar)
            let currentWindow = timeWindow(containing: now, calendar: calendar)
            if window == currentWindow {
                return "This month"
            }
            return "\(window.start.formatted(.dateTime.year())) \(window.start.formatted(.dateTime.month(.wide)))"
        }
    }
}

struct DashboardTimeWindow: Equatable {
    let scope: DashboardTimeScope
    let start: Date
    let end: Date

    func contains(_ date: Date) -> Bool {
        date >= start && date < end
    }
}

enum DashboardTimeStrip: Equatable {
    case days([DashboardWeekdayItem])
    case weeks([DashboardWeekItem])
    case months([DashboardMonthItem])
}

struct DashboardWeekItem: Identifiable, Equatable {
    let startDate: Date
    let endDate: Date
    let topText: String
    let bottomText: String
    let isSelected: Bool

    var id: Date { startDate }
}

struct DashboardMonthItem: Identifiable, Equatable {
    let date: Date
    let yearText: String
    let monthText: String
    let isSelected: Bool

    var id: Date { date }
}

struct DashboardWeekdayItem: Identifiable, Equatable {
    let date: Date
    let weekdayText: String
    let dayText: String
    let isSelected: Bool
    let isToday: Bool

    var id: Date { date }

    static func week(
        containing referenceDate: Date,
        selectedDate: Date,
        now: Date,
        calendar: Calendar
    ) -> [DashboardWeekdayItem] {
        let weekInterval = calendar.dateInterval(of: .weekOfYear, for: referenceDate)
            ?? DateInterval(
                start: calendar.startOfDay(for: referenceDate),
                duration: 7 * 24 * 60 * 60
            )
        let selectedDay = calendar.startOfDay(for: selectedDate)
        let today = calendar.startOfDay(for: now)

        return (0..<7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: weekInterval.start) else {
                return nil
            }

            return DashboardWeekdayItem(
                date: calendar.startOfDay(for: date),
                weekdayText: date.formatted(.dateTime.weekday(.abbreviated)).uppercased(),
                dayText: date.formatted(.dateTime.day()),
                isSelected: calendar.isDate(date, inSameDayAs: selectedDay),
                isToday: calendar.isDate(date, inSameDayAs: today)
            )
        }
    }
}

struct AnalyticsSummary: Equatable {
    let focusTimeSeconds: Int
    let completedSessionsCount: Int
    let averageCompletedSessionSeconds: Int
    let notesCapturedCount: Int

    init(
        focusTimeSeconds: Int = 0,
        completedSessionsCount: Int = 0,
        averageCompletedSessionSeconds: Int = 0,
        notesCapturedCount: Int = 0
    ) {
        self.focusTimeSeconds = focusTimeSeconds
        self.completedSessionsCount = completedSessionsCount
        self.averageCompletedSessionSeconds = averageCompletedSessionSeconds
        self.notesCapturedCount = notesCapturedCount
    }
}

struct AnalyticsTrendBucket: Equatable, Identifiable {
    let id: String
    let title: String
    let totalSeconds: Int
    let sessionCount: Int
    let supportingText: String
}

struct AnalyticsFocusRow: Equatable, Identifiable {
    let id: String
    let title: String
    let totalSeconds: Int
    let sessionCount: Int
}

struct AnalyticsRecentSessionRow: Equatable, Identifiable {
    let id: UUID
    let intention: String
    let durationSeconds: Int
    let endedAt: Date
}

struct AnalyticsMoodRow: Equatable, Identifiable {
    let mood: SessionReflectionMood
    let sessionCount: Int
    let share: Double

    var id: String { mood.rawValue }

    var title: String {
        switch mood {
        case .focused:
            "Focused"
        case .neutral:
            "Neutral"
        case .distracted:
            "Distracted"
        }
    }

    var emoji: String {
        switch mood {
        case .focused:
            "🤩"
        case .neutral:
            "😐"
        case .distracted:
            "😞"
        }
    }
}

@MainActor
final class AnalyticsViewModel: ObservableObject {
    @Published private(set) var summary = AnalyticsSummary()
    @Published private(set) var trendBuckets: [AnalyticsTrendBucket] = []
    @Published private(set) var focusRows: [AnalyticsFocusRow] = []
    @Published private(set) var recentSessions: [AnalyticsRecentSessionRow] = []
    @Published private(set) var moodRows: [AnalyticsMoodRow] = []
    @Published private(set) var selectedScope: DashboardTimeScope
    @Published private(set) var referenceDate: Date
    @Published private(set) var timeStrip: DashboardTimeStrip
    @Published private(set) var referenceTitle: String
    @Published private(set) var errorMessage: String?

    private let focusSessionRepository: FocusSessionRepository
    private let now: () -> Date
    private let calendar: Calendar
    private var allRecords: [FocusSessionRecord] = []

    init(
        focusSessionRepository: FocusSessionRepository? = nil,
        now: @escaping () -> Date = Date.init,
        calendar: Calendar = .current
    ) {
        if let focusSessionRepository {
            self.focusSessionRepository = focusSessionRepository
        } else {
            self.focusSessionRepository = FocusSessionRepository(
                modelContext: ModelContext(FocusSessionModelContainer.shared)
            )
        }

        self.now = now
        self.calendar = calendar
        let initialDate = calendar.startOfDay(for: now())
        selectedScope = .day
        referenceDate = initialDate
        timeStrip = DashboardTimeScope.day.timeStrip(
            for: initialDate,
            now: initialDate,
            calendar: calendar
        )
        referenceTitle = DashboardTimeScope.day.title(
            for: initialDate,
            now: initialDate,
            calendar: calendar
        )

        load()
    }

    func load() {
        do {
            allRecords = try focusSessionRepository.fetchAll()
            applyTimeWindow()
            errorMessage = nil
        } catch {
            errorMessage = "Unable to load analytics."
            allRecords = []
            summary = AnalyticsSummary()
            trendBuckets = []
            focusRows = []
            recentSessions = []
            moodRows = []
            timeStrip = selectedScope.timeStrip(
                for: referenceDate,
                now: now(),
                calendar: calendar
            )
        }
    }

    func setScope(_ scope: DashboardTimeScope) {
        guard selectedScope != scope else {
            return
        }
        selectedScope = scope
        applyTimeWindow()
    }

    func selectDate(_ date: Date) {
        referenceDate = calendar.startOfDay(for: date)
        applyTimeWindow()
    }

    func moveBackward() {
        referenceDate = calendar.startOfDay(
            for: selectedScope.shiftedReferenceDate(
                from: referenceDate,
                direction: -1,
                calendar: calendar
            )
        )
        applyTimeWindow()
    }

    func moveForward() {
        referenceDate = calendar.startOfDay(
            for: selectedScope.shiftedReferenceDate(
                from: referenceDate,
                direction: 1,
                calendar: calendar
            )
        )
        applyTimeWindow()
    }

    var trendTitle: String {
        selectedScope.analyticsTrendTitle
    }

    var topTasksTitle: String {
        selectedScope.analyticsTopTasksTitle
    }

    var recentSessionsTitle: String {
        selectedScope.analyticsRecentTitle
    }

    private func applyTimeWindow() {
        let currentNow = now()
        let window = selectedScope.timeWindow(containing: referenceDate, calendar: calendar)
        let completedRecords = allRecords
            .filter(\.wasCompleted)
            .filter { window.contains($0.endedAt) }
            .sorted { lhs, rhs in
                lhs.endedAt > rhs.endedAt
            }

        referenceTitle = selectedScope.title(
            for: referenceDate,
            now: currentNow,
            calendar: calendar
        )
        timeStrip = selectedScope.timeStrip(
            for: referenceDate,
            now: currentNow,
            calendar: calendar
        )
        summary = buildSummary(from: completedRecords)
        trendBuckets = buildTrendBuckets(from: completedRecords, window: window)
        focusRows = intentionBreakdowns(from: completedRecords)
        moodRows = moodBreakdowns(from: completedRecords)
        recentSessions = completedRecords.prefix(5).map { record in
            AnalyticsRecentSessionRow(
                id: record.id,
                intention: record.intention,
                durationSeconds: record.durationSeconds,
                endedAt: record.endedAt
            )
        }
    }

    private func intentionBreakdowns(from records: [FocusSessionRecord]) -> [AnalyticsFocusRow] {
        Dictionary(grouping: records) { record in
            let trimmedIntention = record.intention.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmedIntention.isEmpty ? "Untitled Focus" : trimmedIntention
        }
        .map { title, groupedRecords in
            AnalyticsFocusRow(
                id: title,
                title: title,
                totalSeconds: groupedRecords.reduce(0) { $0 + $1.durationSeconds },
                sessionCount: groupedRecords.count
            )
        }
        .sorted { lhs, rhs in
            if lhs.totalSeconds != rhs.totalSeconds {
                return lhs.totalSeconds > rhs.totalSeconds
            }
            if lhs.sessionCount != rhs.sessionCount {
                return lhs.sessionCount > rhs.sessionCount
            }
            return lhs.title < rhs.title
        }
        .prefix(5)
        .map { $0 }
    }

    private func moodBreakdowns(from records: [FocusSessionRecord]) -> [AnalyticsMoodRow] {
        let counts = Dictionary(grouping: records.compactMap(\.mood), by: { $0 })
            .mapValues(\.count)
        let totalCount = counts.values.reduce(0, +)

        return SessionReflectionMood.allCases.map { mood in
            let sessionCount = counts[mood, default: 0]
            let share = totalCount == 0 ? 0 : Double(sessionCount) / Double(totalCount)
            return AnalyticsMoodRow(
                mood: mood,
                sessionCount: sessionCount,
                share: share
            )
        }
    }

    private func buildSummary(from records: [FocusSessionRecord]) -> AnalyticsSummary {
        let totalSeconds = records.reduce(0) { $0 + $1.durationSeconds }
        let completedSessionsCount = records.count
        let averageSessionSeconds = completedSessionsCount == 0
            ? 0
            : totalSeconds / completedSessionsCount
        let notesCapturedCount = records.reduce(into: 0) { count, record in
            if !(record.notes ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                count += 1
            }
        }

        return AnalyticsSummary(
            focusTimeSeconds: totalSeconds,
            completedSessionsCount: completedSessionsCount,
            averageCompletedSessionSeconds: averageSessionSeconds,
            notesCapturedCount: notesCapturedCount
        )
    }

    private func buildTrendBuckets(
        from records: [FocusSessionRecord],
        window: DashboardTimeWindow
    ) -> [AnalyticsTrendBucket] {
        switch selectedScope {
        case .day:
            return records.map { record in
                AnalyticsTrendBucket(
                    id: record.id.uuidString,
                    title: record.endedAt.formatted(.dateTime.hour().minute()),
                    totalSeconds: record.durationSeconds,
                    sessionCount: 1,
                    supportingText: record.intention.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ? "Untitled focus block"
                        : record.intention
                )
            }
        case .week:
            return (0..<7).compactMap { offset in
                guard let day = calendar.date(byAdding: .day, value: offset, to: window.start) else {
                    return nil
                }
                let nextDay = calendar.date(byAdding: .day, value: 1, to: day) ?? day
                let dayRecords = records.filter { $0.endedAt >= day && $0.endedAt < nextDay }
                return AnalyticsTrendBucket(
                    id: day.formatted(.iso8601),
                    title: day.formatted(.dateTime.weekday(.wide)),
                    totalSeconds: dayRecords.reduce(0) { $0 + $1.durationSeconds },
                    sessionCount: dayRecords.count,
                    supportingText: "\(day.formatted(.dateTime.month(.abbreviated).day())) · \(dayRecords.count) sessions"
                )
            }
        case .month:
            var buckets: [AnalyticsTrendBucket] = []
            var cursor = window.start

            while cursor < window.end {
                let weekInterval = calendar.dateInterval(of: .weekOfYear, for: cursor)
                    ?? DateInterval(start: cursor, duration: 7 * 24 * 60 * 60)
                let bucketStart = max(weekInterval.start, window.start)
                let bucketEnd = min(weekInterval.end, window.end)
                let bucketRecords = records.filter { $0.endedAt >= bucketStart && $0.endedAt < bucketEnd }
                let inclusiveEnd = calendar.date(byAdding: .day, value: -1, to: bucketEnd) ?? bucketStart
                let title: String
                if calendar.isDate(bucketStart, equalTo: inclusiveEnd, toGranularity: .day) {
                    title = bucketStart.formatted(.dateTime.month(.abbreviated).day())
                } else {
                    title = "\(bucketStart.formatted(.dateTime.month(.abbreviated).day())) - \(inclusiveEnd.formatted(.dateTime.month(.abbreviated).day()))"
                }

                buckets.append(
                    AnalyticsTrendBucket(
                        id: bucketStart.formatted(.iso8601),
                        title: title,
                        totalSeconds: bucketRecords.reduce(0) { $0 + $1.durationSeconds },
                        sessionCount: bucketRecords.count,
                        supportingText: "\(bucketRecords.count) sessions"
                    )
                )

                cursor = weekInterval.end
            }

            return buckets
        }
    }
}
