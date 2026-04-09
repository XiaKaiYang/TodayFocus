import SwiftUI

@MainActor
final class MobileAppSessionServices: ObservableObject {
    let preferencesStore: AppPreferencesStore
    let soundCenter: SoundCenter
    let currentSessionViewModel: CurrentSessionViewModel
    let tasksViewModel: TasksViewModel
    let planViewModel: PlanViewModel
    let whiteNoiseViewModel: WhiteNoiseViewModel
    let notesViewModel: NotesLibraryViewModel
    let analyticsViewModel: AnalyticsViewModel
    let settingsViewModel: SettingsViewModel

    init() {
        let preferencesStore = AppPreferencesStore()
        self.preferencesStore = preferencesStore

        let soundCenter = SoundCenter()
        self.soundCenter = soundCenter

        let analyticsViewModel = AnalyticsViewModel()
        self.analyticsViewModel = analyticsViewModel

        let notesViewModel = NotesLibraryViewModel()
        self.notesViewModel = notesViewModel

        let currentSessionViewModel = CurrentSessionViewModel(
            preferencesStore: preferencesStore,
            soundEffectPlayer: soundCenter,
            onHistoryChanged: {
                analyticsViewModel.load()
                notesViewModel.load()
            }
        )
        self.currentSessionViewModel = currentSessionViewModel

        let planViewModel = PlanViewModel()
        self.planViewModel = planViewModel

        let tasksViewModel = TasksViewModel(
            onStartTask: { task, subtask in
                currentSessionViewModel.selectTask(task, subtask: subtask)
            },
            onTasksChanged: {
                currentSessionViewModel.reloadData()
                planViewModel.load()
                notesViewModel.load()
                analyticsViewModel.load()
            },
            soundEffectPlayer: soundCenter
        )
        self.tasksViewModel = tasksViewModel

        whiteNoiseViewModel = WhiteNoiseViewModel(
            preferencesStore: preferencesStore
        )

        settingsViewModel = SettingsViewModel(
            preferencesStore: preferencesStore,
            onDataChanged: {
                currentSessionViewModel.reloadData()
                tasksViewModel.load()
                planViewModel.load()
                notesViewModel.load()
                analyticsViewModel.load()
            }
        )
    }
}

@main
struct FocusSessionMobileApp: App {
    @StateObject private var services = MobileAppSessionServices()

    var body: some Scene {
        WindowGroup {
            MobileAppShellView(
                configuration: .current,
                services: services
            )
        }
    }
}
