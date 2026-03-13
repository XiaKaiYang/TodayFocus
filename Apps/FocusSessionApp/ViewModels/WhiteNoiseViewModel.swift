import Combine
import Foundation

@MainActor
final class WhiteNoiseViewModel: ObservableObject {
    @Published private(set) var preferences: AppPreferences

    private let preferencesStore: AppPreferencesStore
    private var cancellables = Set<AnyCancellable>()

    init(preferencesStore: AppPreferencesStore = AppPreferencesStore()) {
        self.preferencesStore = preferencesStore
        preferences = preferencesStore.preferences

        preferencesStore.$preferences
            .sink { [weak self] in
                self?.preferences = $0
            }
            .store(in: &cancellables)
    }

    var sessionSoundOptions: [AppDropdownOption<String>] {
        Self.ambientSoundAssetNames.map(Self.soundOption(for:))
    }

    var sessionEndSoundOptions: [AppDropdownOption<String>] {
        Self.eventSoundAssetNames.map(Self.soundOption(for:))
    }

    var breakSoundOptions: [AppDropdownOption<String>] {
        Self.ambientSoundAssetNames.map(Self.soundOption(for:))
    }

    var breakEndSoundOptions: [AppDropdownOption<String>] {
        Self.eventSoundAssetNames.map(Self.soundOption(for:))
    }

    func setBackgroundSoundEnabled(_ isEnabled: Bool) {
        preferencesStore.setBackgroundSoundEnabled(isEnabled)
    }

    func updateSessionSoundName(_ assetName: String) {
        preferencesStore.updateSessionSoundName(assetName)
    }

    func updateSessionSoundVolume(_ volume: Double) {
        preferencesStore.updateSessionSoundVolume(volume)
    }

    func updateSessionEndSoundName(_ assetName: String) {
        preferencesStore.updateSessionEndSoundName(assetName)
    }

    func updateSessionEndSoundVolume(_ volume: Double) {
        preferencesStore.updateSessionEndSoundVolume(volume)
    }

    func updateBreakSoundName(_ assetName: String) {
        preferencesStore.updateBreakSoundName(assetName)
    }

    func updateBreakSoundVolume(_ volume: Double) {
        preferencesStore.updateBreakSoundVolume(volume)
    }

    func updateBreakEndSoundName(_ assetName: String) {
        preferencesStore.updateBreakEndSoundName(assetName)
    }

    func updateBreakEndSoundVolume(_ volume: Double) {
        preferencesStore.updateBreakEndSoundVolume(volume)
    }

    func displayTitle(for assetName: String) -> String {
        Self.displayTitle(for: assetName)
    }

    private static let ambientSoundAssetNames = [
        "Clock Ticking.wav",
        "Duskfall on a River.mp3",
        "Gong.mp3",
        "Kitchen Timer.wav",
        "Light Rain Falling on Forest Floor.mp3",
        "Mountain Atmosphere.mp3",
        "Ocean Waves.mp3",
        "Peaceful Wind Atop a Hill.mp3",
        "Thunder in the Woods.mp3"
    ]

    private static let eventSoundAssetNames = [
        "achievement.wav",
        "confident.wav",
        "ending-soon.wav",
        "eventually.wav",
        "light.wav",
        "stop.wav",
        "default.wav",
        "Clock.m4a",
        "africa.mp3",
        "blocks.mp3",
        "chimes.mp3",
        "crystal.mp3",
        "drip.aac",
        "harp.mp3",
        "jingle.aac",
        "knock.aac",
        "ladder.mp3",
        "lattice.mp3",
        "leap.mp3",
        "matrix.mp3",
        "music_box.mp3",
        "pomo_end.aac",
        "pulse.mp3",
        "spiral.aac",
        "Gong.mp3"
    ]

    private static func soundOption(for assetName: String) -> AppDropdownOption<String> {
        AppDropdownOption(value: assetName, title: displayTitle(for: assetName))
    }

    private static func displayTitle(for assetName: String) -> String {
        let baseName = URL(fileURLWithPath: assetName).deletingPathExtension().lastPathComponent
        return baseName
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .localizedCapitalized
    }
}
