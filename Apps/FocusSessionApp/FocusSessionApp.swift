import AppKit
import SwiftUI

@MainActor
final class AppSessionServices: ObservableObject {
    let preferencesStore: AppPreferencesStore
    let soundCenter: SoundCenter
    let currentSessionViewModel: CurrentSessionViewModel
    let statusItemController: CurrentSessionStatusItemController

    init() {
        let preferencesStore = AppPreferencesStore()
        self.preferencesStore = preferencesStore
        soundCenter = SoundCenter()
        currentSessionViewModel = CurrentSessionViewModel(
            preferencesStore: preferencesStore,
            soundEffectPlayer: soundCenter
        )
        statusItemController = CurrentSessionStatusItemController(
            currentSessionViewModel: currentSessionViewModel
        )
    }
}

@main
struct FocusSessionApp: App {
    @StateObject private var services = AppSessionServices()

    var body: some Scene {
        WindowGroup {
            AppShellView(
                configuration: .current,
                preferencesStore: services.preferencesStore,
                currentSessionViewModel: services.currentSessionViewModel,
                soundCenter: services.soundCenter
            )
                .frame(minWidth: 900, minHeight: 620)
        }
        .windowStyle(.hiddenTitleBar)

        Settings {
            SettingsDashboardView(viewModel: SettingsViewModel(preferencesStore: services.preferencesStore))
        }
    }
}
