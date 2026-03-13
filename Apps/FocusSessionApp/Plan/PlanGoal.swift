import CoreGraphics
import Foundation

enum PlanGoalStatus: String, CaseIterable, Equatable, Hashable {
    case notStarted
    case inProgress
    case completed
    case unfinished
    case onHold

    var title: String {
        switch self {
        case .notStarted:
            "Not Started"
        case .inProgress:
            "In Progress"
        case .completed:
            "Completed"
        case .unfinished:
            "Unfinished"
        case .onHold:
            "On Hold"
        }
    }

    var isTerminal: Bool {
        switch self {
        case .completed, .unfinished:
            true
        case .notStarted, .inProgress, .onHold:
            false
        }
    }
}

enum PlanGoalSubtaskTrackingMode: String, CaseIterable, Equatable, Hashable, Codable {
    case estimated
    case quantified

    var title: String {
        switch self {
        case .estimated:
            "Estimated"
        case .quantified:
            "Quantified"
        }
    }
}

struct PlanGoalSubtask: Equatable, Identifiable, Codable {
    let id: UUID
    var title: String
    var baselineValue: Double
    var targetValue: Double
    var unitLabel: String
    var trackingMode: PlanGoalSubtaskTrackingMode
    var goalSharePercent: Double

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case baselineValue
        case targetValue
        case unitLabel
        case trackingMode
        case goalSharePercent
        case progressPercent
    }

    init(
        id: UUID = UUID(),
        title: String,
        baselineValue: Double = 0,
        targetValue: Double = 100,
        unitLabel: String = "",
        trackingMode: PlanGoalSubtaskTrackingMode = .quantified,
        goalSharePercent: Double = 100
    ) {
        self.id = id
        self.title = title
        self.baselineValue = baselineValue
        self.targetValue = targetValue
        self.unitLabel = unitLabel
        self.trackingMode = trackingMode
        self.goalSharePercent = goalSharePercent
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try container.decode(String.self, forKey: .title)

        if let baselineValue = try container.decodeIfPresent(Double.self, forKey: .baselineValue) {
            self.baselineValue = baselineValue
        } else if let baselineValue = try container.decodeIfPresent(Int.self, forKey: .progressPercent) {
            self.baselineValue = Double(baselineValue)
        } else {
            self.baselineValue = 0
        }

        targetValue = try container.decodeIfPresent(Double.self, forKey: .targetValue) ?? 100
        unitLabel = try container.decodeIfPresent(String.self, forKey: .unitLabel) ?? ""
        trackingMode = try container.decodeIfPresent(PlanGoalSubtaskTrackingMode.self, forKey: .trackingMode) ?? .quantified
        if let share = try container.decodeIfPresent(Double.self, forKey: .goalSharePercent) {
            goalSharePercent = share
        } else if let share = try container.decodeIfPresent(Int.self, forKey: .goalSharePercent) {
            goalSharePercent = Double(share)
        } else {
            goalSharePercent = .nan
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(baselineValue, forKey: .baselineValue)
        try container.encode(targetValue, forKey: .targetValue)
        try container.encode(unitLabel, forKey: .unitLabel)
        try container.encode(trackingMode, forKey: .trackingMode)
        try container.encode(goalSharePercent, forKey: .goalSharePercent)
    }

    var progressPercent: Int {
        progressPercent(for: baselineValue)
    }

    var isCompleted: Bool {
        isCompleted(currentValue: baselineValue)
    }

    func progressPercent(for currentValue: Double) -> Int {
        switch trackingMode {
        case .estimated:
            return min(max(Int(currentValue.rounded()), 0), 100)
        case .quantified:
            guard targetValue > 0 else {
                return currentValue > 0 ? 100 : 0
            }

            let normalized = (currentValue / targetValue) * 100
            return min(max(Int(normalized.rounded()), 0), 100)
        }
    }

    func isCompleted(currentValue: Double) -> Bool {
        progressPercent(for: currentValue) >= 100
    }

    static func normalizedGoalSharePercents(in subtasks: [PlanGoalSubtask]) -> [PlanGoalSubtask] {
        guard !subtasks.isEmpty else {
            return []
        }

        let shares = subtasks.map(\.goalSharePercent)
        let hasInvalidShare = shares.contains { !$0.isFinite || $0 < 0 }
        guard !hasInvalidShare else {
            let equalShares = evenlyDistributedGoalSharePercents(count: subtasks.count)
            return zip(subtasks, equalShares).map { subtask, share in
                var normalizedSubtask = subtask
                normalizedSubtask.goalSharePercent = share
                return normalizedSubtask
            }
        }

        let roundedSubtasks = subtasks.map { subtask in
            var normalizedSubtask = subtask
            normalizedSubtask.goalSharePercent = roundedGoalSharePercent(subtask.goalSharePercent)
            return normalizedSubtask
        }
        let roundedTotal = roundedGoalSharePercent(roundedSubtasks.reduce(0) { $0 + $1.goalSharePercent })
        guard roundedTotal > 100.01 else {
            return roundedSubtasks
        }

        return scaledGoalSharePercents(in: roundedSubtasks, total: roundedTotal)
    }

    static func roundedGoalSharePercent(_ value: Double) -> Double {
        (value * 100).rounded() / 100
    }

    private static func evenlyDistributedGoalSharePercents(count: Int) -> [Double] {
        guard count > 0 else {
            return []
        }

        let basisPoints = 10_000
        let base = basisPoints / count
        let remainder = basisPoints % count

        return (0 ..< count).map { index in
            Double(base + (index < remainder ? 1 : 0)) / 100
        }
    }

    private static func scaledGoalSharePercents(in subtasks: [PlanGoalSubtask], total: Double) -> [PlanGoalSubtask] {
        let normalizedPercentages = subtasks.map { subtask in
            (subtask.goalSharePercent / total) * 100
        }
        let roundedPercentages = normalizedPercentages.map(roundedGoalSharePercent)
        let roundedTotal = roundedGoalSharePercent(roundedPercentages.reduce(0, +))
        let adjustment = roundedGoalSharePercent(100 - roundedTotal)

        return subtasks.enumerated().map { index, subtask in
            var scaledSubtask = subtask
            let roundedShare = roundedPercentages[index]
            if index == subtasks.indices.last {
                scaledSubtask.goalSharePercent = roundedGoalSharePercent(roundedShare + adjustment)
            } else {
                scaledSubtask.goalSharePercent = roundedShare
            }
            return scaledSubtask
        }
    }
}

struct PlanGoal: Equatable, Identifiable {
    let id: UUID
    var title: String
    var notes: String?
    var status: PlanGoalStatus
    var startAt: Date
    var endAt: Date
    var createdAt: Date
    var subtasks: [PlanGoalSubtask]
    var displayOrder: Int

    var progressPercent: Int? {
        guard !subtasks.isEmpty else {
            return nil
        }

        let normalizedSubtasks = PlanGoalSubtask.normalizedGoalSharePercents(in: subtasks)
        let totalProgress = normalizedSubtasks.reduce(0.0) { partialResult, subtask in
            partialResult + Double(subtask.progressPercent) * (subtask.goalSharePercent / 100)
        }
        return Int(totalProgress.rounded())
    }

    var completedSubtaskCount: Int {
        subtasks.filter(\.isCompleted).count
    }

    var hasSubtasks: Bool {
        !subtasks.isEmpty
    }

    var timelineRowID: String {
        id.uuidString
    }

    init(
        id: UUID = UUID(),
        title: String,
        notes: String? = nil,
        status: PlanGoalStatus = .notStarted,
        startAt: Date,
        endAt: Date,
        createdAt: Date = Date(),
        subtasks: [PlanGoalSubtask] = [],
        displayOrder: Int = -1
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.status = status
        self.startAt = startAt
        self.endAt = endAt
        self.createdAt = createdAt
        self.subtasks = subtasks
        self.displayOrder = displayOrder
    }
}

enum PlanGoalLabelPlacement: Equatable {
    case inside
    case leadingOutside
    case trailingOutside
}

enum PlanTimelineAxisDetailLevel: Equatable {
    case monthsOnly
    case monthsAndWeeks
    case monthsWeeksAndDays
}

enum PlanTimelinePresentation {
    static let monthAxisLabelTopPadding: CGFloat = 45
    static let timelineCardTopPadding: CGFloat = 18
    static let timelineCardBottomPadding: CGFloat = 2

    static func chartHeight(forGoalCount goalCount: Int) -> CGFloat {
        if goalCount <= 2 {
            return 208
        }

        return CGFloat(max(240, goalCount * 44 + 100))
    }

    static func chartContentWidthMultiplier(forVisibleMonthSpan visibleMonthSpan: Int) -> CGFloat {
        switch visibleMonthSpan {
        case 1:
            3.2
        case 2 ... 3:
            2.2
        case 4 ... 6:
            1.6
        default:
            1.0
        }
    }

    static func axisDetailLevel(forVisibleMonthSpan visibleMonthSpan: Int) -> PlanTimelineAxisDetailLevel {
        switch visibleMonthSpan {
        case 1:
            .monthsWeeksAndDays
        case 2 ... 6:
            .monthsAndWeeks
        default:
            .monthsOnly
        }
    }

    static func monthAxisLabel(for date: Date, calendar: Calendar = .autoupdatingCurrent) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "M月"
        return formatter.string(from: date)
    }

    static func labelPlacement(
        for goal: PlanGoal,
        within window: DateInterval
    ) -> PlanGoalLabelPlacement {
        let windowDuration = max(window.duration, 1)
        let clampedStart = max(goal.startAt.timeIntervalSince(window.start), 0)
        let clampedEnd = min(goal.endAt.timeIntervalSince(window.start), window.duration)
        let barDuration = max(clampedEnd - clampedStart, 0)

        let durationFraction = barDuration / windowDuration
        let estimatedLabelFraction = min(
            0.42,
            max(0.08, Double(goal.title.count) * 0.011 + 0.035)
        )

        if durationFraction >= estimatedLabelFraction {
            return .inside
        }

        let leftFraction = clampedStart / windowDuration
        let rightFraction = max(window.duration - clampedEnd, 0) / windowDuration

        return rightFraction >= leftFraction ? .trailingOutside : .leadingOutside
    }
}

enum PlanTimelineScale: String, CaseIterable, Hashable {
    case day
    case week
    case month

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

    func window(containing referenceDate: Date, calendar: Calendar) -> DateInterval {
        switch self {
        case .day:
            return calendar.dateInterval(of: .day, for: referenceDate)
                ?? DateInterval(start: referenceDate, duration: 24 * 60 * 60)
        case .week:
            return calendar.dateInterval(of: .weekOfYear, for: referenceDate)
                ?? DateInterval(start: referenceDate, duration: 7 * 24 * 60 * 60)
        case .month:
            return calendar.dateInterval(of: .year, for: referenceDate)
                ?? DateInterval(start: referenceDate, duration: 365 * 24 * 60 * 60)
        }
    }

    func shiftedReferenceDate(from referenceDate: Date, direction: Int, calendar: Calendar) -> Date {
        switch self {
        case .day:
            return calendar.date(byAdding: .day, value: direction, to: referenceDate) ?? referenceDate
        case .week:
            return calendar.date(byAdding: .weekOfYear, value: direction, to: referenceDate) ?? referenceDate
        case .month:
            return calendar.date(byAdding: .year, value: direction, to: referenceDate) ?? referenceDate
        }
    }
}
