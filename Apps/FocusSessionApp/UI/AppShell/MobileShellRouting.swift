import Foundation

enum MobilePrimaryTab: String, CaseIterable, Hashable, Identifiable {
    case tasks
    case currentSession
    case plan
    case notes
    case more

    var id: String { rawValue }

    var title: String {
        switch self {
        case .tasks:
            "Today"
        case .currentSession:
            "Session"
        case .plan:
            "Plan"
        case .notes:
            "Notes"
        case .more:
            "More"
        }
    }

    var symbolName: String {
        switch self {
        case .tasks:
            "checklist"
        case .currentSession:
            "timer"
        case .plan:
            "calendar"
        case .notes:
            "note.text"
        case .more:
            "ellipsis.circle"
        }
    }

    var rootSection: AppSection? {
        switch self {
        case .tasks:
            .tasks
        case .currentSession:
            .currentSession
        case .plan:
            .plan
        case .notes:
            .notes
        case .more:
            nil
        }
    }

    static var moreSections: [AppSection] {
        [.whiteNoise, .analytics, .trash, .settings]
    }

    static func tab(for section: AppSection) -> MobilePrimaryTab {
        switch section {
        case .tasks:
            .tasks
        case .currentSession:
            .currentSession
        case .plan:
            .plan
        case .notes:
            .notes
        case .whiteNoise, .analytics, .trash, .settings, .blocker:
            .more
        }
    }
}

struct MobilePhoneLaunchState: Equatable {
    let selectedTab: MobilePrimaryTab
    let selectedMoreSection: AppSection?
}

enum MobileShellRouting {
    static func phoneLaunchState(preferredSection: AppSection?) -> MobilePhoneLaunchState {
        let section = AppSection.resolvedLaunchSection(
            preferredSection: preferredSection,
            on: .iOS
        )
        let tab = MobilePrimaryTab.tab(for: section)
        let selectedMoreSection = MobilePrimaryTab.moreSections.contains(section) ? section : nil
        return MobilePhoneLaunchState(
            selectedTab: tab,
            selectedMoreSection: selectedMoreSection
        )
    }

    static func padLaunchSection(preferredSection: AppSection?) -> AppSection {
        AppSection.resolvedLaunchSection(
            preferredSection: preferredSection,
            on: .iOS
        )
    }
}
