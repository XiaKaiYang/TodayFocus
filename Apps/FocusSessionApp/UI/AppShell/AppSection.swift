import Foundation

enum AppSection: String, CaseIterable, Hashable, Identifiable {
    case tasks
    case plan
    case currentSession
    case whiteNoise
    case notes
    case analytics
    case blocker
    case trash
    case settings

    var id: Self { self }

    static var allCases: [AppSection] {
        [
            .tasks,
            .plan,
            .currentSession,
            .whiteNoise,
            .notes,
            .analytics,
            .blocker,
            .trash,
            .settings
        ]
    }

    var title: String {
        switch self {
        case .tasks:
            "Today"
        case .plan:
            "Plan"
        case .currentSession:
            "Current Session"
        case .whiteNoise:
            "White Noise"
        case .notes:
            "Notes"
        case .analytics:
            "Analytics"
        case .blocker:
            "Blocker"
        case .trash:
            "Trash"
        case .settings:
            "Settings"
        }
    }

    var sidebarTitle: String {
        switch self {
        case .tasks:
            "Today"
        case .plan:
            "Plan"
        case .currentSession:
            "Session"
        case .whiteNoise:
            "White Noise"
        case .trash:
            "Trash"
        default:
            title
        }
    }

    var subtitle: String {
        switch self {
        case .tasks:
            "Capture and organize today."
        case .plan:
            "Map goals across time."
        case .currentSession:
            "Run the active focus cycle."
        case .whiteNoise:
            "Shape the soundscape and cues."
        case .notes:
            "Browse previous session notes."
        case .analytics:
            "Review momentum and trends."
        case .blocker:
            "Control distractions and rules."
        case .trash:
            "Review completed tasks."
        case .settings:
            "Tune behavior and integrations."
        }
    }

    var symbolName: String {
        switch self {
        case .tasks:
            "checklist"
        case .plan:
            "calendar"
        case .currentSession:
            "timer"
        case .whiteNoise:
            "speaker.wave.3"
        case .notes:
            "note.text"
        case .analytics:
            "chart.bar.xaxis"
        case .blocker:
            "hand.raised"
        case .trash:
            "trash"
        case .settings:
            "gearshape"
        }
    }
}
