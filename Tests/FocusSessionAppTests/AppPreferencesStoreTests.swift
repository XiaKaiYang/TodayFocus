import XCTest
@testable import FocusSession

@MainActor
final class AppPreferencesStoreTests: XCTestCase {
    func testDefaultsMatchProductBaseline() {
        let suiteName = UUID().uuidString
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = AppPreferencesStore(userDefaults: defaults)

        XCTAssertEqual(store.preferences.defaultFocusDurationMinutes, 25)
        XCTAssertEqual(store.preferences.launchSection, .tasks)
        XCTAssertEqual(store.preferences.planGoalLaunchExpansion, .collapsed)
        XCTAssertTrue(store.preferences.autoEnableBlockerDuringFocus)
        XCTAssertEqual(store.preferences.recentSessionsLimit, 8)
        XCTAssertFalse(store.preferences.backgroundSoundEnabled)
        XCTAssertEqual(store.preferences.sessionSoundName, "Clock Ticking.wav")
        XCTAssertEqual(store.preferences.sessionSoundVolume, 0.4, accuracy: 0.0001)
        XCTAssertEqual(store.preferences.sessionEndSoundName, "eventually.wav")
        XCTAssertEqual(store.preferences.sessionEndSoundVolume, 0.65, accuracy: 0.0001)
        XCTAssertEqual(store.preferences.breakSoundName, "Ocean Waves.mp3")
        XCTAssertEqual(store.preferences.breakSoundVolume, 0.4, accuracy: 0.0001)
        XCTAssertEqual(store.preferences.breakEndSoundName, "Gong.mp3")
        XCTAssertEqual(store.preferences.breakEndSoundVolume, 0.65, accuracy: 0.0001)
    }

    func testUpdatesPersistAcrossStoreInstances() {
        let suiteName = UUID().uuidString
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = AppPreferencesStore(userDefaults: defaults)
        store.updateDefaultFocusDurationMinutes(40)
        store.updateLaunchSection(.tasks)
        store.updatePlanGoalLaunchExpansion(.expanded)
        store.setAutoEnableBlockerDuringFocus(false)
        store.updateRecentSessionsLimit(12)
        store.setBackgroundSoundEnabled(true)
        store.updateSessionSoundName("Ocean Waves.mp3")
        store.updateSessionSoundVolume(0.22)
        store.updateSessionEndSoundName("achievement.wav")
        store.updateSessionEndSoundVolume(0.91)
        store.updateBreakSoundName("Mountain Atmosphere.mp3")
        store.updateBreakSoundVolume(0.33)
        store.updateBreakEndSoundName("default.wav")
        store.updateBreakEndSoundVolume(0.44)

        let reloadedStore = AppPreferencesStore(userDefaults: defaults)

        XCTAssertEqual(reloadedStore.preferences.defaultFocusDurationMinutes, 40)
        XCTAssertEqual(reloadedStore.preferences.launchSection, .tasks)
        XCTAssertEqual(reloadedStore.preferences.planGoalLaunchExpansion, .expanded)
        XCTAssertFalse(reloadedStore.preferences.autoEnableBlockerDuringFocus)
        XCTAssertEqual(reloadedStore.preferences.recentSessionsLimit, 12)
        XCTAssertTrue(reloadedStore.preferences.backgroundSoundEnabled)
        XCTAssertEqual(reloadedStore.preferences.sessionSoundName, "Ocean Waves.mp3")
        XCTAssertEqual(reloadedStore.preferences.sessionSoundVolume, 0.22, accuracy: 0.0001)
        XCTAssertEqual(reloadedStore.preferences.sessionEndSoundName, "achievement.wav")
        XCTAssertEqual(reloadedStore.preferences.sessionEndSoundVolume, 0.91, accuracy: 0.0001)
        XCTAssertEqual(reloadedStore.preferences.breakSoundName, "Mountain Atmosphere.mp3")
        XCTAssertEqual(reloadedStore.preferences.breakSoundVolume, 0.33, accuracy: 0.0001)
        XCTAssertEqual(reloadedStore.preferences.breakEndSoundName, "default.wav")
        XCTAssertEqual(reloadedStore.preferences.breakEndSoundVolume, 0.44, accuracy: 0.0001)
    }
}
