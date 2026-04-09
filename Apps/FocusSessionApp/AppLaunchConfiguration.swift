import Foundation

struct AppLaunchConfiguration {
    let initialSection: AppSection?
    let usesBlockerDemo: Bool

    init(environment: [String: String]) {
        if let demoMode = environment["FOCUSSESSION_DEMO_MODE"]?.lowercased(),
           demoMode == "blocker" {
            initialSection = .blocker
            usesBlockerDemo = true
            return
        }

        if let rawSection = environment["FOCUSSESSION_INITIAL_SECTION"] {
            initialSection = AppSection.allCases.first {
                $0.rawValue.caseInsensitiveCompare(rawSection) == .orderedSame
            }
        } else {
            initialSection = nil
        }

        usesBlockerDemo = false
    }

    static var current: AppLaunchConfiguration {
        AppLaunchConfiguration(environment: ProcessInfo.processInfo.environment)
    }
}
