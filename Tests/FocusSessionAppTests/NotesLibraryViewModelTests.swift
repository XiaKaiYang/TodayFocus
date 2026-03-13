import XCTest
import SwiftData
import FocusSessionCore
@testable import FocusSession

@MainActor
final class NotesLibraryViewModelTests: XCTestCase {
    func testLoadShowsMostRecentNonEmptyNotesFirst() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = FocusSessionRepository(modelContext: ModelContext(container))
        try repository.save(
            FocusSessionRecord(
                intention: "Newest note",
                startedAt: Date(timeIntervalSince1970: 300),
                endedAt: Date(timeIntervalSince1970: 360),
                notes: "Newest body",
                wasCompleted: true
            )
        )
        try repository.save(
            FocusSessionRecord(
                intention: "No note",
                startedAt: Date(timeIntervalSince1970: 200),
                endedAt: Date(timeIntervalSince1970: 240),
                notes: nil,
                wasCompleted: true
            )
        )
        try repository.save(
            FocusSessionRecord(
                intention: "Older note",
                startedAt: Date(timeIntervalSince1970: 100),
                endedAt: Date(timeIntervalSince1970: 160),
                notes: "Older body",
                wasCompleted: true
            )
        )

        let viewModel = NotesLibraryViewModel(
            focusSessionRepository: repository,
            now: { Date(timeIntervalSince1970: 400) }
        )

        XCTAssertEqual(viewModel.entries.map(\.title), ["Newest note", "Older note"])
        XCTAssertEqual(viewModel.selectedEntry?.title, "Newest note")
        XCTAssertEqual(viewModel.selectedEntry?.body, "Newest body")
    }

    func testDeleteSelectedEntryRemovesItAndSelectsTheNextOne() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = FocusSessionRepository(modelContext: ModelContext(container))
        let newestRecord = FocusSessionRecord(
            intention: "Newest note",
            startedAt: Date(timeIntervalSince1970: 300),
            endedAt: Date(timeIntervalSince1970: 360),
            notes: "Newest body",
            wasCompleted: true
        )
        let olderRecord = FocusSessionRecord(
            intention: "Older note",
            startedAt: Date(timeIntervalSince1970: 100),
            endedAt: Date(timeIntervalSince1970: 160),
            notes: "Older body",
            wasCompleted: true
        )
        try repository.save(newestRecord)
        try repository.save(olderRecord)

        let viewModel = NotesLibraryViewModel(
            focusSessionRepository: repository,
            now: { Date(timeIntervalSince1970: 400) }
        )

        viewModel.deleteSelectedEntry()

        XCTAssertEqual(viewModel.entries.map(\.title), ["Older note"])
        XCTAssertEqual(viewModel.selectedEntry?.title, "Older note")
        XCTAssertNil(viewModel.errorMessage)
    }

    func testLoadExposesEndedTimeAndMoodEmojiMetadata() throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = FocusSessionRepository(modelContext: ModelContext(container))
        try repository.save(
            FocusSessionRecord(
                intention: "Mood note",
                startedAt: Date(timeIntervalSince1970: 300),
                endedAt: Date(timeIntervalSince1970: 390),
                notes: "Captured after a strong block.",
                mood: .focused,
                wasCompleted: true
            )
        )
        try repository.save(
            FocusSessionRecord(
                intention: "No mood note",
                startedAt: Date(timeIntervalSince1970: 100),
                endedAt: Date(timeIntervalSince1970: 160),
                notes: "Still worth keeping.",
                mood: nil,
                wasCompleted: true
            )
        )
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt

        let viewModel = NotesLibraryViewModel(
            focusSessionRepository: repository,
            now: { Date(timeIntervalSince1970: 500) },
            calendar: calendar
        )
        let firstEntry = try XCTUnwrap(viewModel.entries.first)
        let firstMetadata: [String: String] = Dictionary(
            uniqueKeysWithValues: Mirror(reflecting: firstEntry).children.compactMap { child in
                guard let label = child.label else {
                    return nil
                }
                return (label, String(describing: child.value))
            }
        )
        let lastEntry = try XCTUnwrap(viewModel.entries.last)
        let lastMetadata: [String: String] = Dictionary(
            uniqueKeysWithValues: Mirror(reflecting: lastEntry).children.compactMap { child in
                guard let label = child.label else {
                    return nil
                }
                return (label, String(describing: child.value))
            }
        )

        XCTAssertEqual(viewModel.entries.first?.title, "Mood note")
        XCTAssertEqual(firstMetadata["moodEmoji"], "Optional(\"🤩\")")
        XCTAssertEqual(lastMetadata["moodEmoji"], "nil")
        XCTAssertEqual(firstMetadata["endedAtText"], "01-01 00:06")
    }

    func testScopeFilteringUsesEndedAtForDayWeekAndMonth() throws {
        let calendar = makeCalendar()
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = FocusSessionRepository(modelContext: ModelContext(container))
        try repository.save(
            FocusSessionRecord(
                intention: "Cross midnight",
                startedAt: makeDate(year: 2026, month: 3, day: 11, hour: 23, minute: 50, calendar: calendar),
                endedAt: makeDate(year: 2026, month: 3, day: 12, hour: 0, minute: 10, calendar: calendar),
                notes: "Finished after midnight.",
                wasCompleted: true
            )
        )
        try repository.save(
            FocusSessionRecord(
                intention: "Today note",
                startedAt: makeDate(year: 2026, month: 3, day: 12, hour: 9, minute: 0, calendar: calendar),
                endedAt: makeDate(year: 2026, month: 3, day: 12, hour: 9, minute: 30, calendar: calendar),
                notes: "Today body.",
                wasCompleted: true
            )
        )
        try repository.save(
            FocusSessionRecord(
                intention: "This week note",
                startedAt: makeDate(year: 2026, month: 3, day: 10, hour: 15, minute: 0, calendar: calendar),
                endedAt: makeDate(year: 2026, month: 3, day: 10, hour: 15, minute: 20, calendar: calendar),
                notes: "Still this week.",
                wasCompleted: true
            )
        )
        try repository.save(
            FocusSessionRecord(
                intention: "This month note",
                startedAt: makeDate(year: 2026, month: 3, day: 2, hour: 8, minute: 0, calendar: calendar),
                endedAt: makeDate(year: 2026, month: 3, day: 2, hour: 8, minute: 25, calendar: calendar),
                notes: "Earlier this month.",
                wasCompleted: true
            )
        )
        try repository.save(
            FocusSessionRecord(
                intention: "Last month note",
                startedAt: makeDate(year: 2026, month: 2, day: 27, hour: 8, minute: 0, calendar: calendar),
                endedAt: makeDate(year: 2026, month: 2, day: 27, hour: 8, minute: 20, calendar: calendar),
                notes: "Previous month.",
                wasCompleted: true
            )
        )

        let viewModel = NotesLibraryViewModel(
            focusSessionRepository: repository,
            now: { self.makeDate(year: 2026, month: 3, day: 12, hour: 12, minute: 0, calendar: calendar) },
            calendar: calendar
        )

        XCTAssertEqual(viewModel.selectedScope, .day)
        XCTAssertEqual(viewModel.entries.map(\.title), ["Today note", "Cross midnight"])

        viewModel.setScope(.week)

        XCTAssertEqual(viewModel.entries.map(\.title), ["Today note", "Cross midnight", "This week note"])

        viewModel.setScope(.month)

        XCTAssertEqual(
            viewModel.entries.map(\.title),
            ["Today note", "Cross midnight", "This week note", "This month note"]
        )
    }

    func testChangingVisibleWindowFallsBackToFirstVisibleEntry() throws {
        let calendar = makeCalendar()
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = FocusSessionRepository(modelContext: ModelContext(container))
        try repository.save(
            FocusSessionRecord(
                intention: "March 12 note",
                startedAt: makeDate(year: 2026, month: 3, day: 12, hour: 9, minute: 0, calendar: calendar),
                endedAt: makeDate(year: 2026, month: 3, day: 12, hour: 9, minute: 30, calendar: calendar),
                notes: "Current day.",
                wasCompleted: true
            )
        )
        try repository.save(
            FocusSessionRecord(
                intention: "March 11 note",
                startedAt: makeDate(year: 2026, month: 3, day: 11, hour: 9, minute: 0, calendar: calendar),
                endedAt: makeDate(year: 2026, month: 3, day: 11, hour: 9, minute: 25, calendar: calendar),
                notes: "Previous day.",
                wasCompleted: true
            )
        )

        let viewModel = NotesLibraryViewModel(
            focusSessionRepository: repository,
            now: { self.makeDate(year: 2026, month: 3, day: 12, hour: 12, minute: 0, calendar: calendar) },
            calendar: calendar
        )

        viewModel.setScope(.week)
        let previousDay = try XCTUnwrap(viewModel.entries.last)
        viewModel.selectEntry(previousDay)

        XCTAssertEqual(viewModel.selectedEntry?.title, "March 11 note")

        viewModel.setScope(.day)

        XCTAssertEqual(viewModel.entries.map(\.title), ["March 12 note"])
        XCTAssertEqual(viewModel.selectedEntry?.title, "March 12 note")
        guard case let .days(days) = viewModel.timeStrip else {
            return XCTFail("Day scope should expose a seven-day strip.")
        }
        XCTAssertEqual(days.count, 7)
        XCTAssertEqual(
            days.first(where: \.isSelected)?.date,
            makeDate(year: 2026, month: 3, day: 12, hour: 0, minute: 0, calendar: calendar)
        )
    }

    func testWeekAndMonthScopesExposeFiveCardNavigationStrips() throws {
        let calendar = makeCalendar()
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = FocusSessionRepository(modelContext: ModelContext(container))
        try repository.save(
            FocusSessionRecord(
                intention: "Current week note",
                startedAt: makeDate(year: 2026, month: 3, day: 12, hour: 9, minute: 0, calendar: calendar),
                endedAt: makeDate(year: 2026, month: 3, day: 12, hour: 9, minute: 30, calendar: calendar),
                notes: "Current week body.",
                wasCompleted: true
            )
        )

        let now = makeDate(year: 2026, month: 3, day: 12, hour: 12, minute: 0, calendar: calendar)
        let viewModel = NotesLibraryViewModel(
            focusSessionRepository: repository,
            now: { now },
            calendar: calendar
        )

        XCTAssertEqual(viewModel.referenceTitle, "Today")

        viewModel.setScope(.week)

        XCTAssertEqual(viewModel.referenceTitle, "This week")
        guard case let .weeks(weeks) = viewModel.timeStrip else {
            return XCTFail("Week scope should expose a five-card week strip.")
        }
        XCTAssertEqual(weeks.count, 5)
        XCTAssertEqual(weeks.map(\.startDate), [
            makeDate(year: 2026, month: 2, day: 23, hour: 0, minute: 0, calendar: calendar),
            makeDate(year: 2026, month: 3, day: 2, hour: 0, minute: 0, calendar: calendar),
            makeDate(year: 2026, month: 3, day: 9, hour: 0, minute: 0, calendar: calendar),
            makeDate(year: 2026, month: 3, day: 16, hour: 0, minute: 0, calendar: calendar),
            makeDate(year: 2026, month: 3, day: 23, hour: 0, minute: 0, calendar: calendar)
        ])
        XCTAssertEqual(weeks.firstIndex(where: \.isSelected), 2)

        viewModel.setScope(.month)

        XCTAssertEqual(viewModel.referenceTitle, "This month")
        guard case let .months(months) = viewModel.timeStrip else {
            return XCTFail("Month scope should expose a five-card month strip.")
        }
        XCTAssertEqual(months.count, 5)
        XCTAssertEqual(months.map(\.date), [
            makeDate(year: 2026, month: 1, day: 1, hour: 0, minute: 0, calendar: calendar),
            makeDate(year: 2026, month: 2, day: 1, hour: 0, minute: 0, calendar: calendar),
            makeDate(year: 2026, month: 3, day: 1, hour: 0, minute: 0, calendar: calendar),
            makeDate(year: 2026, month: 4, day: 1, hour: 0, minute: 0, calendar: calendar),
            makeDate(year: 2026, month: 5, day: 1, hour: 0, minute: 0, calendar: calendar)
        ])
        XCTAssertEqual(months.firstIndex(where: \.isSelected), 2)
    }

    private func makeCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        calendar.firstWeekday = 2
        return calendar
    }

    private func makeDate(
        year: Int,
        month: Int,
        day: Int,
        hour: Int,
        minute: Int,
        calendar: Calendar
    ) -> Date {
        let components = DateComponents(
            calendar: calendar,
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
