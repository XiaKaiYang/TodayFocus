import Foundation

enum TaskPriority: String, CaseIterable, Equatable, Hashable {
    case high
    case medium
    case low
    case none

    var sectionTitle: String {
        switch self {
        case .high:
            "高优先级"
        case .medium:
            "中优先级"
        case .low:
            "低优先级"
        case .none:
            "无优先级"
        }
    }

    var composerTitle: String {
        switch self {
        case .high:
            "高"
        case .medium:
            "中"
        case .low:
            "低"
        case .none:
            "无"
        }
    }

    var sortOrder: Int {
        switch self {
        case .high:
            0
        case .medium:
            1
        case .low:
            2
        case .none:
            3
        }
    }
}

enum TaskRepeatRule: String, CaseIterable, Equatable, Hashable, Codable {
    case none
    case daily
    case weekly

    var title: String {
        switch self {
        case .none:
            "None"
        case .daily:
            "Daily"
        case .weekly:
            "Weekly"
        }
    }
}

enum TaskRepeatWeekday: Int, CaseIterable, Equatable, Hashable, Codable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7

    var title: String {
        switch self {
        case .sunday:
            "Sunday"
        case .monday:
            "Monday"
        case .tuesday:
            "Tuesday"
        case .wednesday:
            "Wednesday"
        case .thursday:
            "Thursday"
        case .friday:
            "Friday"
        case .saturday:
            "Saturday"
        }
    }

    var calendarWeekday: Int { rawValue }
}

struct TaskSubtask: Equatable, Identifiable, Codable {
    let id: UUID
    var title: String
    var isCompleted: Bool

    init(
        id: UUID = UUID(),
        title: String,
        isCompleted: Bool = false
    ) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
    }
}

struct FocusTask: Equatable, Identifiable {
    let id: UUID
    var title: String
    var details: String?
    var estimatedMinutes: Int
    var priority: TaskPriority
    var subtasks: [TaskSubtask]
    var startAt: Date?
    var endAt: Date?
    var isCompleted: Bool
    var createdAt: Date
    var completedAt: Date?
    var linkedSubtaskID: UUID?
    var contributionValue: Double?
    var settledLinkedSubtaskID: UUID?
    var settledContributionValue: Double?
    var repeatRule: TaskRepeatRule
    var repeatWeekday: TaskRepeatWeekday?
    var repeatTotalCount: Int?
    var repeatRemainingCount: Int?
    var visibleFrom: Date?
    var recurrenceSeriesID: UUID?
    var displayOrder: Int

    init(
        id: UUID = UUID(),
        title: String,
        details: String? = nil,
        estimatedMinutes: Int = 25,
        priority: TaskPriority = .none,
        subtasks: [TaskSubtask] = [],
        startAt: Date? = nil,
        endAt: Date? = nil,
        isCompleted: Bool = false,
        createdAt: Date = Date(),
        completedAt: Date? = nil,
        linkedSubtaskID: UUID? = nil,
        contributionValue: Double? = nil,
        settledLinkedSubtaskID: UUID? = nil,
        settledContributionValue: Double? = nil,
        repeatRule: TaskRepeatRule = .none,
        repeatWeekday: TaskRepeatWeekday? = nil,
        repeatTotalCount: Int? = nil,
        repeatRemainingCount: Int? = nil,
        visibleFrom: Date? = nil,
        recurrenceSeriesID: UUID? = nil,
        displayOrder: Int = -1
    ) {
        self.id = id
        self.title = title
        self.details = details
        self.estimatedMinutes = estimatedMinutes
        self.priority = priority
        self.subtasks = subtasks
        self.startAt = startAt
        self.endAt = endAt
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.linkedSubtaskID = linkedSubtaskID
        self.contributionValue = contributionValue
        self.settledLinkedSubtaskID = settledLinkedSubtaskID
        self.settledContributionValue = settledContributionValue
        self.repeatRule = repeatRule
        self.repeatWeekday = repeatWeekday
        self.repeatTotalCount = repeatTotalCount
        self.repeatRemainingCount = repeatRemainingCount
        self.visibleFrom = visibleFrom
        self.recurrenceSeriesID = recurrenceSeriesID
        self.displayOrder = displayOrder
    }

    var isRepeating: Bool {
        repeatRule != .none
    }

    var hasSubtasks: Bool {
        subtasks.isEmpty == false
    }

    var areAllSubtasksCompleted: Bool {
        hasSubtasks && subtasks.allSatisfy(\.isCompleted)
    }

    var isLinkedToSubtask: Bool {
        linkedSubtaskID != nil
    }

    var recurrenceProgressText: String? {
        guard isRepeating else {
            return nil
        }

        guard let repeatTotalCount else {
            return "∞"
        }

        let remainingCount = max(0, repeatRemainingCount ?? repeatTotalCount)
        let currentIndex = max(1, repeatTotalCount - remainingCount + 1)
        return "\(currentIndex)/\(repeatTotalCount)"
    }

    func isVisibleInToday(at date: Date) -> Bool {
        guard !isCompleted else {
            return false
        }

        guard let visibleFrom else {
            return true
        }

        return visibleFrom <= date
    }

    func isVisibleInTomorrow(
        relativeTo referenceDate: Date,
        calendar: Calendar = .autoupdatingCurrent
    ) -> Bool {
        guard !isCompleted else {
            return false
        }

        let tomorrow = calendar.date(byAdding: .day, value: 1, to: referenceDate) ?? referenceDate
        let startOfTomorrow = calendar.startOfDay(for: tomorrow)
        let endOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfTomorrow) ?? tomorrow

        if isRepeating {
            guard let visibleFrom else {
                return true
            }
            return visibleFrom < endOfTomorrow
        }

        guard let visibleFrom else {
            return false
        }

        return calendar.isDate(visibleFrom, inSameDayAs: tomorrow)
    }

    func resettingSubtasks() -> [TaskSubtask] {
        subtasks.map { subtask in
            TaskSubtask(id: subtask.id, title: subtask.title, isCompleted: false)
        }
    }
}
