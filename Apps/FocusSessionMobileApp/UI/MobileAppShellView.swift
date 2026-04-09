import SwiftUI

struct MobileAppShellView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @StateObject private var services: MobileAppSessionServices
    @State private var selectedPhoneTab: MobilePrimaryTab
    @State private var selectedPadSection: AppSection
    @State private var selectedMoreSection: AppSection?
    @State private var morePath: [AppSection] = []

    init(
        configuration: AppLaunchConfiguration = .current,
        services: MobileAppSessionServices? = nil
    ) {
        let resolvedServices = services ?? MobileAppSessionServices()
        let preferredSection = AppSection.resolvedLaunchSection(
            preferredSection: configuration.initialSection ?? resolvedServices.preferencesStore.preferences.launchSection,
            on: .iOS
        )
        let phoneLaunchState = MobileShellRouting.phoneLaunchState(
            preferredSection: preferredSection
        )

        _services = StateObject(wrappedValue: resolvedServices)
        _selectedPhoneTab = State(initialValue: phoneLaunchState.selectedTab)
        _selectedPadSection = State(
            initialValue: MobileShellRouting.padLaunchSection(
                preferredSection: preferredSection
            )
        )
        _selectedMoreSection = State(initialValue: phoneLaunchState.selectedMoreSection)
    }

    var body: some View {
        Group {
            if usesSplitNavigation {
                padShell
            } else {
                phoneShell
            }
        }
        .sheet(isPresented: taskSheetBinding) {
            SharedTaskComposerSheet(viewModel: services.tasksViewModel)
        }
        .onAppear {
            syncBackgroundSound()
            applyInitialMoreSelectionIfNeeded()
        }
        .onChange(of: services.currentSessionViewModel.sessionState.phase) { _, _ in
            syncBackgroundSound()
        }
        .onChange(of: services.preferencesStore.preferences) { _, _ in
            syncBackgroundSound()
        }
    }

    private var usesSplitNavigation: Bool {
        horizontalSizeClass == .regular
    }

    private var phoneShell: some View {
        TabView(selection: $selectedPhoneTab) {
            NavigationStack {
                sectionView(.tasks)
            }
            .tabItem {
                Label(MobilePrimaryTab.tasks.title, systemImage: MobilePrimaryTab.tasks.symbolName)
            }
            .tag(MobilePrimaryTab.tasks)

            NavigationStack {
                sectionView(.currentSession)
            }
            .tabItem {
                Label(MobilePrimaryTab.currentSession.title, systemImage: MobilePrimaryTab.currentSession.symbolName)
            }
            .tag(MobilePrimaryTab.currentSession)

            NavigationStack {
                sectionView(.plan)
            }
            .tabItem {
                Label(MobilePrimaryTab.plan.title, systemImage: MobilePrimaryTab.plan.symbolName)
            }
            .tag(MobilePrimaryTab.plan)

            NavigationStack {
                sectionView(.notes)
            }
            .tabItem {
                Label(MobilePrimaryTab.notes.title, systemImage: MobilePrimaryTab.notes.symbolName)
            }
            .tag(MobilePrimaryTab.notes)

            NavigationStack(path: $morePath) {
                List(MobilePrimaryTab.moreSections) { section in
                    NavigationLink(value: section) {
                        Label(section.title, systemImage: section.symbolName)
                    }
                }
                .navigationTitle(MobilePrimaryTab.more.title)
                .navigationDestination(for: AppSection.self) { section in
                    sectionView(section)
                        .navigationTitle(section.title)
                        .navigationBarTitleDisplayMode(.inline)
                }
            }
            .tabItem {
                Label(MobilePrimaryTab.more.title, systemImage: MobilePrimaryTab.more.symbolName)
            }
            .tag(MobilePrimaryTab.more)
        }
    }

    private var padShell: some View {
        NavigationSplitView {
            List(AppSection.availableSections(on: .iOS)) { section in
                Button {
                    selectedPadSection = section
                } label: {
                    Label(section.sidebarTitle, systemImage: section.symbolName)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fontWeight(selectedPadSection == section ? .semibold : .regular)
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("TodayFocus")
        } detail: {
            NavigationStack {
                sectionView(selectedPadSection)
            }
        }
    }

    @ViewBuilder
    private func sectionView(_ section: AppSection) -> some View {
        switch section {
        case .tasks:
            TasksDashboardView(viewModel: services.tasksViewModel) {
                selectedPhoneTab = .currentSession
                selectedPadSection = .currentSession
            }
        case .plan:
            PlanDashboardView(
                viewModel: services.planViewModel,
                tasksViewModel: services.tasksViewModel,
                preferencesStore: services.preferencesStore
            )
        case .currentSession:
            CurrentSessionView(viewModel: services.currentSessionViewModel)
        case .whiteNoise:
            WhiteNoiseDashboardView(viewModel: services.whiteNoiseViewModel)
        case .notes:
            NotesLibraryView(viewModel: services.notesViewModel)
        case .analytics:
            AnalyticsDashboardView(viewModel: services.analyticsViewModel)
        case .trash:
            TrashDashboardView(
                tasksViewModel: services.tasksViewModel,
                planViewModel: services.planViewModel
            )
        case .settings:
            SettingsDashboardView(viewModel: services.settingsViewModel)
        case .blocker:
            unavailableBlockerView
        }
    }

    private var unavailableBlockerView: some View {
        ZStack {
            AppCanvasBackground()

            VStack(alignment: .leading, spacing: 12) {
                Text("Blocker")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(AppSurfaceTheme.primaryText)

                Text("Blocker stays on macOS for this version of TodayFocus.")
                    .font(.title3)
                    .foregroundStyle(AppSurfaceTheme.secondaryText)
            }
            .padding(28)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    private var taskSheetBinding: Binding<Bool> {
        Binding(
            get: { services.tasksViewModel.isPresentingCreateSheet },
            set: { isPresented in
                if !isPresented {
                    services.tasksViewModel.dismissCreateSheet()
                }
            }
        )
    }

    private func applyInitialMoreSelectionIfNeeded() {
        guard selectedPhoneTab == .more else { return }
        guard morePath.isEmpty, let selectedMoreSection else { return }
        morePath = [selectedMoreSection]
    }

    private func syncBackgroundSound() {
        let preferences = services.preferencesStore.preferences

        guard preferences.backgroundSoundEnabled else {
            services.soundCenter.stopLoop()
            return
        }

        switch services.currentSessionViewModel.sessionState.phase {
        case .focusing, .focusPaused:
            services.soundCenter.startLoop(
                named: preferences.sessionSoundName,
                volume: preferences.sessionSoundVolume
            )
        case .breakRunning, .breakPaused:
            services.soundCenter.startLoop(
                named: preferences.breakSoundName,
                volume: preferences.breakSoundVolume
            )
        case .idle, .reflecting, .completed, .abandoned:
            services.soundCenter.stopLoop()
        }
    }
}
