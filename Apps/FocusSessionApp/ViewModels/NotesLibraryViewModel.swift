import Foundation
import SwiftData
import FocusSessionCore

struct NotesLibraryEntry: Identifiable, Equatable {
    let id: UUID
    let title: String
    let body: String
    let preview: String
    let endedAtText: String
    let moodEmoji: String?
    let relativeEndedText: String
    let durationText: String
    let endedAt: Date

    init(
        record: FocusSessionRecord,
        referenceDate: Date,
        calendar: Calendar
    ) {
        let trimmedTitle = record.intention.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedBody = (record.notes ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let relativeFormatter = RelativeDateTimeFormatter()
        relativeFormatter.unitsStyle = .full
        let roundedMinutes = max(1, Int(ceil(Double(record.durationSeconds) / 60)))

        id = record.id
        title = trimmedTitle.isEmpty ? "Untitled Session" : trimmedTitle
        body = trimmedBody
        preview = String(trimmedBody.prefix(140))
        endedAtText = Self.formatEndedAt(record.endedAt, calendar: calendar)
        moodEmoji = Self.moodEmoji(for: record.mood)
        relativeEndedText = relativeFormatter.localizedString(for: record.endedAt, relativeTo: referenceDate)
        durationText = "\(roundedMinutes) min"
        endedAt = record.endedAt
    }

    private static func formatEndedAt(_ date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents(in: calendar.timeZone, from: date)
        return String(
            format: "%02d-%02d %02d:%02d",
            components.month ?? 0,
            components.day ?? 0,
            components.hour ?? 0,
            components.minute ?? 0
        )
    }

    private static func moodEmoji(for mood: SessionReflectionMood?) -> String? {
        switch mood {
        case .focused:
            return "🤩"
        case .neutral:
            return "😐"
        case .distracted:
            return "😞"
        case nil:
            return nil
        }
    }
}

@MainActor
final class NotesLibraryViewModel: ObservableObject {
    @Published private(set) var entries: [NotesLibraryEntry] = []
    @Published var selectedEntryID: UUID?
    @Published private(set) var selectedScope: DashboardTimeScope
    @Published private(set) var referenceDate: Date
    @Published private(set) var timeStrip: DashboardTimeStrip
    @Published private(set) var referenceTitle: String
    @Published private(set) var errorMessage: String?

    private let focusSessionRepository: FocusSessionRepository
    private let now: () -> Date
    private let calendar: Calendar
    private var allEntries: [NotesLibraryEntry] = []

    init(
        focusSessionRepository: FocusSessionRepository? = nil,
        now: @escaping () -> Date = Date.init,
        calendar: Calendar = .autoupdatingCurrent
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

    var selectedEntry: NotesLibraryEntry? {
        guard let selectedEntryID else {
            return entries.first
        }
        return entries.first(where: { $0.id == selectedEntryID }) ?? entries.first
    }

    func load() {
        do {
            allEntries = try focusSessionRepository.fetchAll()
                .filter { record in
                    !(record.notes ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                }
                .sorted { lhs, rhs in
                    lhs.endedAt > rhs.endedAt
                }
                .map { NotesLibraryEntry(record: $0, referenceDate: now(), calendar: calendar) }
            applyTimeWindow()
            errorMessage = nil
        } catch {
            allEntries = []
            entries = []
            selectedEntryID = nil
            timeStrip = selectedScope.timeStrip(
                for: referenceDate,
                now: now(),
                calendar: calendar
            )
            errorMessage = "Unable to load notes."
        }
    }

    func selectEntry(_ entry: NotesLibraryEntry) {
        selectedEntryID = entry.id
    }

    func deleteSelectedEntry() {
        guard let selectedEntryID else {
            return
        }

        do {
            try focusSessionRepository.delete(id: selectedEntryID)
            load()
            errorMessage = nil
        } catch {
            errorMessage = "Unable to delete note."
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

    var emptyListTitle: String {
        selectedScope.noteListEmptyTitle
    }

    var emptyListMessage: String {
        selectedScope.noteListEmptyMessage
    }

    var emptyDetailTitle: String {
        selectedScope.noteDetailEmptyTitle
    }

    var emptyDetailMessage: String {
        selectedScope.noteDetailEmptyMessage
    }

    private func applyTimeWindow() {
        let window = selectedScope.timeWindow(containing: referenceDate, calendar: calendar)
        let currentNow = now()

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
        entries = allEntries.filter { entry in
            window.contains(entry.endedAt)
        }

        if let selectedEntryID,
           entries.contains(where: { $0.id == selectedEntryID }) {
            return
        }

        self.selectedEntryID = entries.first?.id
    }
}
