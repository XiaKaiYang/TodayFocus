import Foundation
import Combine

enum PlanGoalLaunchExpansion: String, CaseIterable, Equatable, Hashable {
    case collapsed
    case expanded

    var title: String {
        switch self {
        case .collapsed:
            "Default Collapsed"
        case .expanded:
            "Default Expanded"
        }
    }
}

struct AppPreferences: Equatable {
    var defaultFocusDurationMinutes = 25
    var launchSection: AppSection = .tasks
    var planGoalLaunchExpansion: PlanGoalLaunchExpansion = .collapsed
    var autoEnableBlockerDuringFocus = true
    var recentSessionsLimit = 8
    var backgroundSoundEnabled = false
    var sessionSoundName = "Clock Ticking.wav"
    var sessionSoundVolume = 0.4
    var sessionEndSoundName = "eventually.wav"
    var sessionEndSoundVolume = 0.65
    var breakSoundName = "Ocean Waves.mp3"
    var breakSoundVolume = 0.4
    var breakEndSoundName = "Gong.mp3"
    var breakEndSoundVolume = 0.65
}

@MainActor
final class AppPreferencesStore: ObservableObject {
    @Published private(set) var preferences: AppPreferences

    private let userDefaults: UserDefaults

    private enum Key {
        static let defaultFocusDurationMinutes = "preferences.defaultFocusDurationMinutes"
        static let launchSection = "preferences.launchSection"
        static let planGoalLaunchExpansion = "preferences.planGoalLaunchExpansion"
        static let autoEnableBlockerDuringFocus = "preferences.autoEnableBlockerDuringFocus"
        static let recentSessionsLimit = "preferences.recentSessionsLimit"
        static let backgroundSoundEnabled = "preferences.backgroundSoundEnabled"
        static let sessionSoundName = "preferences.sessionSoundName"
        static let sessionSoundVolume = "preferences.sessionSoundVolume"
        static let sessionEndSoundName = "preferences.sessionEndSoundName"
        static let sessionEndSoundVolume = "preferences.sessionEndSoundVolume"
        static let breakSoundName = "preferences.breakSoundName"
        static let breakSoundVolume = "preferences.breakSoundVolume"
        static let breakEndSoundName = "preferences.breakEndSoundName"
        static let breakEndSoundVolume = "preferences.breakEndSoundVolume"
    }

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        preferences = Self.load(from: userDefaults)
    }

    func updateDefaultFocusDurationMinutes(_ minutes: Int) {
        update {
            $0.defaultFocusDurationMinutes = min(max(minutes, 5), 60)
        }
    }

    func updateLaunchSection(_ section: AppSection) {
        update {
            $0.launchSection = section
        }
    }

    func updatePlanGoalLaunchExpansion(_ expansion: PlanGoalLaunchExpansion) {
        update {
            $0.planGoalLaunchExpansion = expansion
        }
    }

    func setAutoEnableBlockerDuringFocus(_ isEnabled: Bool) {
        update {
            $0.autoEnableBlockerDuringFocus = isEnabled
        }
    }

    func updateRecentSessionsLimit(_ limit: Int) {
        update {
            $0.recentSessionsLimit = min(max(limit, 3), 20)
        }
    }

    func setBackgroundSoundEnabled(_ isEnabled: Bool) {
        update {
            $0.backgroundSoundEnabled = isEnabled
        }
    }

    func updateSessionSoundName(_ name: String) {
        update {
            $0.sessionSoundName = name
        }
    }

    func updateSessionSoundVolume(_ volume: Double) {
        update {
            $0.sessionSoundVolume = Self.clampedVolume(volume)
        }
    }

    func updateSessionEndSoundName(_ name: String) {
        update {
            $0.sessionEndSoundName = name
        }
    }

    func updateSessionEndSoundVolume(_ volume: Double) {
        update {
            $0.sessionEndSoundVolume = Self.clampedVolume(volume)
        }
    }

    func updateBreakSoundName(_ name: String) {
        update {
            $0.breakSoundName = name
        }
    }

    func updateBreakSoundVolume(_ volume: Double) {
        update {
            $0.breakSoundVolume = Self.clampedVolume(volume)
        }
    }

    func updateBreakEndSoundName(_ name: String) {
        update {
            $0.breakEndSoundName = name
        }
    }

    func updateBreakEndSoundVolume(_ volume: Double) {
        update {
            $0.breakEndSoundVolume = Self.clampedVolume(volume)
        }
    }

    func reset() {
        preferences = AppPreferences()
        persist()
    }

    private func update(_ mutation: (inout AppPreferences) -> Void) {
        var updatedPreferences = preferences
        mutation(&updatedPreferences)
        preferences = updatedPreferences
        persist()
    }

    private func persist() {
        userDefaults.set(preferences.defaultFocusDurationMinutes, forKey: Key.defaultFocusDurationMinutes)
        userDefaults.set(preferences.launchSection.rawValue, forKey: Key.launchSection)
        userDefaults.set(preferences.planGoalLaunchExpansion.rawValue, forKey: Key.planGoalLaunchExpansion)
        userDefaults.set(preferences.autoEnableBlockerDuringFocus, forKey: Key.autoEnableBlockerDuringFocus)
        userDefaults.set(preferences.recentSessionsLimit, forKey: Key.recentSessionsLimit)
        userDefaults.set(preferences.backgroundSoundEnabled, forKey: Key.backgroundSoundEnabled)
        userDefaults.set(preferences.sessionSoundName, forKey: Key.sessionSoundName)
        userDefaults.set(preferences.sessionSoundVolume, forKey: Key.sessionSoundVolume)
        userDefaults.set(preferences.sessionEndSoundName, forKey: Key.sessionEndSoundName)
        userDefaults.set(preferences.sessionEndSoundVolume, forKey: Key.sessionEndSoundVolume)
        userDefaults.set(preferences.breakSoundName, forKey: Key.breakSoundName)
        userDefaults.set(preferences.breakSoundVolume, forKey: Key.breakSoundVolume)
        userDefaults.set(preferences.breakEndSoundName, forKey: Key.breakEndSoundName)
        userDefaults.set(preferences.breakEndSoundVolume, forKey: Key.breakEndSoundVolume)
    }

    private static func load(from userDefaults: UserDefaults) -> AppPreferences {
        var preferences = AppPreferences()

        let storedFocusDuration = userDefaults.integer(forKey: Key.defaultFocusDurationMinutes)
        if storedFocusDuration != 0 {
            preferences.defaultFocusDurationMinutes = min(max(storedFocusDuration, 5), 60)
        }

        if let rawLaunchSection = userDefaults.string(forKey: Key.launchSection),
           let launchSection = AppSection(rawValue: rawLaunchSection) {
            preferences.launchSection = launchSection
        }

        if let rawPlanGoalLaunchExpansion = userDefaults.string(forKey: Key.planGoalLaunchExpansion),
           let planGoalLaunchExpansion = PlanGoalLaunchExpansion(rawValue: rawPlanGoalLaunchExpansion) {
            preferences.planGoalLaunchExpansion = planGoalLaunchExpansion
        }

        if userDefaults.object(forKey: Key.autoEnableBlockerDuringFocus) != nil {
            preferences.autoEnableBlockerDuringFocus = userDefaults.bool(forKey: Key.autoEnableBlockerDuringFocus)
        }

        let storedRecentSessionsLimit = userDefaults.integer(forKey: Key.recentSessionsLimit)
        if storedRecentSessionsLimit != 0 {
            preferences.recentSessionsLimit = min(max(storedRecentSessionsLimit, 3), 20)
        }

        if userDefaults.object(forKey: Key.backgroundSoundEnabled) != nil {
            preferences.backgroundSoundEnabled = userDefaults.bool(forKey: Key.backgroundSoundEnabled)
        }

        if let storedSessionSoundName = userDefaults.string(forKey: Key.sessionSoundName),
           !storedSessionSoundName.isEmpty {
            preferences.sessionSoundName = storedSessionSoundName
        }

        if userDefaults.object(forKey: Key.sessionSoundVolume) != nil {
            preferences.sessionSoundVolume = clampedVolume(userDefaults.double(forKey: Key.sessionSoundVolume))
        }

        if let storedSessionEndSoundName = userDefaults.string(forKey: Key.sessionEndSoundName),
           !storedSessionEndSoundName.isEmpty {
            preferences.sessionEndSoundName = storedSessionEndSoundName
        }

        if userDefaults.object(forKey: Key.sessionEndSoundVolume) != nil {
            preferences.sessionEndSoundVolume = clampedVolume(userDefaults.double(forKey: Key.sessionEndSoundVolume))
        }

        if let storedBreakSoundName = userDefaults.string(forKey: Key.breakSoundName),
           !storedBreakSoundName.isEmpty {
            preferences.breakSoundName = storedBreakSoundName
        }

        if userDefaults.object(forKey: Key.breakSoundVolume) != nil {
            preferences.breakSoundVolume = clampedVolume(userDefaults.double(forKey: Key.breakSoundVolume))
        }

        if let storedBreakEndSoundName = userDefaults.string(forKey: Key.breakEndSoundName),
           !storedBreakEndSoundName.isEmpty {
            preferences.breakEndSoundName = storedBreakEndSoundName
        }

        if userDefaults.object(forKey: Key.breakEndSoundVolume) != nil {
            preferences.breakEndSoundVolume = clampedVolume(userDefaults.double(forKey: Key.breakEndSoundVolume))
        }

        return preferences
    }

    private static func clampedVolume(_ volume: Double) -> Double {
        min(max(volume, 0), 1)
    }
}
