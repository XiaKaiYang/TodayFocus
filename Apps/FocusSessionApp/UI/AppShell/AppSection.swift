import Foundation

enum AppPlatform: Equatable {
    case macOS
    case iOS

    static var current: AppPlatform {
        #if os(iOS)
        .iOS
        #else
        .macOS
        #endif
    }
}

enum AppSection: String, CaseIterable, Hashable, Identifiable {
    case tasks
    case plan
    case currentSession
    case whiteNoise
    case notes
    case analytics
    case pk
    case blocker
    case account
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
            .pk,
            .blocker,
            .account,
            .settings
        ]
    }

    func isAvailable(on platform: AppPlatform) -> Bool {
        switch self {
        case .pk:
            return platform == .macOS
        default:
            switch platform {
            case .macOS:
                return true
            case .iOS:
                return self != .blocker
            }
        }
    }

    static func availableSections(on platform: AppPlatform) -> [AppSection] {
        allCases.filter { $0.isAvailable(on: platform) }
    }

    static func resolvedLaunchSection(
        preferredSection: AppSection?,
        on platform: AppPlatform,
        fallback: AppSection = .tasks
    ) -> AppSection {
        guard let preferredSection, preferredSection.isAvailable(on: platform) else {
            return fallback
        }

        return preferredSection
    }

    static func launchDestinationSections(on platform: AppPlatform) -> [AppSection] {
        availableSections(on: platform).filter {
            switch $0 {
            case .account, .settings:
                false
            case .tasks, .plan, .currentSession, .whiteNoise, .notes, .analytics, .pk, .blocker:
                true
            }
        }
    }

    var title: String {
        switch self {
        case .tasks:
            AppText.tr("app.section.tasks.title")
        case .plan:
            AppText.tr("app.section.plan.title")
        case .currentSession:
            AppText.tr("app.section.currentSession.title")
        case .whiteNoise:
            AppText.tr("app.section.whiteNoise.title")
        case .notes:
            AppText.tr("app.section.notes.title")
        case .analytics:
            AppText.tr("app.section.analytics.title")
        case .pk:
            AppText.tr("app.section.pk.title")
        case .blocker:
            AppText.tr("app.section.blocker.title")
        case .account:
            AppText.tr("app.section.account.title")
        case .settings:
            AppText.tr("app.section.settings.title")
        }
    }

    var sidebarTitle: String {
        switch self {
        case .tasks:
            AppText.tr("app.section.tasks.sidebar")
        case .plan:
            AppText.tr("app.section.plan.sidebar")
        case .currentSession:
            AppText.tr("app.section.currentSession.sidebar")
        case .whiteNoise:
            AppText.tr("app.section.whiteNoise.sidebar")
        case .pk:
            AppText.tr("app.section.pk.sidebar")
        case .analytics:
            AppText.tr("app.section.analytics.sidebar")
        case .blocker:
            AppText.tr("app.section.blocker.sidebar")
        case .account:
            AppText.tr("app.section.account.sidebar")
        default:
            title
        }
    }

    var subtitle: String {
        switch self {
        case .tasks:
            AppText.tr("app.section.tasks.subtitle")
        case .plan:
            AppText.tr("app.section.plan.subtitle")
        case .currentSession:
            AppText.tr("app.section.currentSession.subtitle")
        case .whiteNoise:
            AppText.tr("app.section.whiteNoise.subtitle")
        case .notes:
            AppText.tr("app.section.notes.subtitle")
        case .analytics:
            AppText.tr("app.section.analytics.subtitle")
        case .pk:
            AppText.tr("app.section.pk.subtitle")
        case .blocker:
            AppText.tr("app.section.blocker.subtitle")
        case .account:
            AppText.tr("app.section.account.subtitle")
        case .settings:
            AppText.tr("app.section.settings.subtitle")
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
        case .pk:
            "person.2.fill"
        case .blocker:
            "hand.raised"
        case .account:
            "person.crop.circle"
        case .settings:
            "gearshape"
        }
    }
}
