import FocusSessionCore
import SwiftUI

@MainActor
final class AppShellViewModel: ObservableObject {
    @Published var selectedSection: AppSection?

    init(
        configuration: AppLaunchConfiguration = .current,
        preferencesStore: AppPreferencesStore? = nil
    ) {
        selectedSection = AppSection.resolvedLaunchSection(
            preferredSection: configuration.initialSection
                ?? preferencesStore?.preferences.launchSection,
            on: .macOS
        )
    }

    func handleIncomingURL(_ url: URL) {
        guard let destination = FocusSessionDeepLink.destination(for: url) else {
            return
        }

        switch destination {
        case .plan:
            selectedSection = .plan
        }
    }
}

struct AppShellView: View {
    @StateObject private var viewModel: AppShellViewModel
    @StateObject private var preferencesStore: AppPreferencesStore
    @StateObject private var soundCenter: SoundCenter
    @StateObject private var currentSessionViewModel: CurrentSessionViewModel
    @StateObject private var tasksViewModel: TasksViewModel
    @StateObject private var planViewModel: PlanViewModel
    @StateObject private var whiteNoiseViewModel: WhiteNoiseViewModel
    @StateObject private var notesViewModel: NotesLibraryViewModel
    @StateObject private var analyticsViewModel: AnalyticsViewModel
    @StateObject private var blockerViewModel: BlockerViewModel
    @StateObject private var settingsViewModel: SettingsViewModel
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var sectionRefreshTask: Task<Void, Never>?
    @Namespace private var sidebarSelectionAnimation

    init(
        configuration: AppLaunchConfiguration = .current,
        preferencesStore: AppPreferencesStore? = nil,
        blockerViewModel: BlockerViewModel? = nil,
        currentSessionViewModel: CurrentSessionViewModel? = nil,
        tasksViewModel: TasksViewModel? = nil,
        soundCenter: SoundCenter? = nil
    ) {
        let resolvedPreferencesStore = preferencesStore ?? AppPreferencesStore()
        let resolvedSoundCenter = soundCenter ?? SoundCenter()
        let resolvedAnalyticsViewModel = AnalyticsViewModel()
        let resolvedNotesViewModel = NotesLibraryViewModel()
        let resolvedCurrentSessionViewModel = currentSessionViewModel
            ?? CurrentSessionViewModel(
                preferencesStore: resolvedPreferencesStore,
                soundEffectPlayer: resolvedSoundCenter,
                onHistoryChanged: {
                    resolvedAnalyticsViewModel.load()
                    resolvedNotesViewModel.load()
                }
            )
        let resolvedPlanViewModel = PlanViewModel()
        let resolvedBlockerViewModel = blockerViewModel
            ?? (configuration.usesBlockerDemo ? BlockerViewModel.demo() : BlockerViewModel())
        let resolvedTasksViewModel = tasksViewModel ?? TasksViewModel(
            onStartTask: { task, subtask in
                resolvedCurrentSessionViewModel.selectTask(task, subtask: subtask)
            },
            onTasksChanged: {
                resolvedCurrentSessionViewModel.reloadData()
                resolvedPlanViewModel.load()
            },
            soundEffectPlayer: resolvedSoundCenter
        )
        let resolvedWhiteNoiseViewModel = WhiteNoiseViewModel(
            preferencesStore: resolvedPreferencesStore
        )
        let resolvedSettingsViewModel = SettingsViewModel(
            preferencesStore: resolvedPreferencesStore,
            onDataChanged: {
                resolvedCurrentSessionViewModel.reloadData()
                resolvedTasksViewModel.load()
                resolvedPlanViewModel.load()
                resolvedNotesViewModel.load()
                resolvedAnalyticsViewModel.load()
                resolvedBlockerViewModel.load()
            }
        )

        _viewModel = StateObject(
            wrappedValue: AppShellViewModel(
                configuration: configuration,
                preferencesStore: resolvedPreferencesStore
            )
        )
        _preferencesStore = StateObject(wrappedValue: resolvedPreferencesStore)
        _soundCenter = StateObject(wrappedValue: resolvedSoundCenter)
        _currentSessionViewModel = StateObject(
            wrappedValue: resolvedCurrentSessionViewModel
        )
        _tasksViewModel = StateObject(
            wrappedValue: resolvedTasksViewModel
        )
        _planViewModel = StateObject(wrappedValue: resolvedPlanViewModel)
        _whiteNoiseViewModel = StateObject(wrappedValue: resolvedWhiteNoiseViewModel)
        _notesViewModel = StateObject(wrappedValue: resolvedNotesViewModel)
        _analyticsViewModel = StateObject(wrappedValue: resolvedAnalyticsViewModel)
        _blockerViewModel = StateObject(wrappedValue: resolvedBlockerViewModel)
        _settingsViewModel = StateObject(wrappedValue: resolvedSettingsViewModel)
    }

    var body: some View {
        GeometryReader { geometry in
            let widthTier = AppResponsiveWidthTier.shell(for: geometry.size.width)

            NavigationSplitView(columnVisibility: $columnVisibility) {
                ZStack {
                    AppCanvasBackground()

                    VStack(spacing: 0) {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 2) {
                                ForEach(primarySidebarSections) { section in
                                    sidebarRow(for: section)
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.top, 18)
                            .padding(.bottom, 12)
                        }

                        HStack(spacing: 12) {
                            ForEach(footerSidebarSections) { section in
                                sidebarUtilityRow(for: section)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 18)
                    }
                }
                .frame(
                    minWidth: shellSidebarWidth(for: widthTier),
                    idealWidth: shellSidebarWidth(for: widthTier)
                )
            } detail: {
                detailView(for: viewModel.selectedSection ?? .tasks)
            }
        }
        .sheet(isPresented: taskSheetBinding) {
            SharedTaskComposerSheet(viewModel: tasksViewModel)
        }
        .navigationSplitViewStyle(.balanced)
        .background(WindowChromeConfigurator())
        .background(
            AppMenuTitleSynchronizer(
                title: currentSessionViewModel.menuBarTitle,
                highlightsActiveTask: {
                    switch currentSessionViewModel.sessionState.phase {
                    case .focusing, .focusPaused, .breakRunning, .breakPaused:
                        true
                    case .idle, .reflecting, .completed, .abandoned:
                        false
                    }
                }()
            )
        )
        .onAppear {
            syncBlockerWithSession()
            syncBackgroundSound()
        }
        .onOpenURL { url in
            viewModel.handleIncomingURL(url)
        }
        .onChange(of: currentSessionViewModel.sessionState.phase) { _, _ in
            syncBlockerWithSession()
            syncBackgroundSound()
        }
        .onChange(of: preferencesStore.preferences.autoEnableBlockerDuringFocus) { _, _ in
            syncBlockerWithSession()
        }
        .onChange(of: preferencesStore.preferences) { _, _ in
            syncBackgroundSound()
        }
        .onChange(of: viewModel.selectedSection) { _, newSection in
            guard let newSection else { return }
            sectionRefreshTask?.cancel()
            sectionRefreshTask = Task { @MainActor in
                await Task.yield()
                guard !Task.isCancelled else { return }
                switch newSection {
                case .plan:
                    planViewModel.load()
                case .tasks:
                    tasksViewModel.load()
                case .trash:
                    tasksViewModel.load()
                    planViewModel.load()
                case .currentSession:
                    currentSessionViewModel.reloadData()
                case .whiteNoise:
                    break
                case .notes:
                    notesViewModel.load()
                case .analytics:
                    analyticsViewModel.load()
                case .blocker, .settings:
                    break
                }
            }
        }
        .onDisappear {
            sectionRefreshTask?.cancel()
        }
    }

    private func shellSidebarWidth(for widthTier: AppResponsiveWidthTier) -> CGFloat {
        switch widthTier {
        case .compact:
            188
        case .regular:
            220
        case .expanded:
            240
        }
    }

    private var primarySidebarSections: [AppSection] {
        AppSection.allCases.filter { $0 != .trash && $0 != .settings }
    }

    private var footerSidebarSections: [AppSection] {
        [.trash, .settings]
    }

    @ViewBuilder
    private func detailView(for section: AppSection) -> some View {
        switch section {
        case .plan:
            PlanDashboardView(viewModel: planViewModel, tasksViewModel: tasksViewModel, preferencesStore: preferencesStore)
        case .currentSession:
            CurrentSessionView(viewModel: currentSessionViewModel)
        case .whiteNoise:
            WhiteNoiseDashboardView(viewModel: whiteNoiseViewModel)
        case .blocker:
            BlockerSettingsView(viewModel: blockerViewModel)
        case .tasks:
            TasksDashboardView(viewModel: tasksViewModel) {
                viewModel.selectedSection = .currentSession
            }
        case .notes:
            NotesLibraryView(viewModel: notesViewModel)
        case .analytics:
            AnalyticsDashboardView(viewModel: analyticsViewModel)
        case .trash:
            TrashDashboardView(tasksViewModel: tasksViewModel, planViewModel: planViewModel)
        case .settings:
            SettingsDashboardView(viewModel: settingsViewModel)
        }
    }

    private var taskSheetBinding: Binding<Bool> {
        Binding(
            get: { tasksViewModel.isPresentingCreateSheet },
            set: { isPresented in
                if !isPresented {
                    tasksViewModel.dismissCreateSheet()
                }
            }
        )
    }

    private func syncBlockerWithSession() {
        blockerViewModel.syncSessionPhase(
            currentSessionViewModel.sessionState.phase,
            autoEnableDuringFocus: preferencesStore.preferences.autoEnableBlockerDuringFocus
        )
    }

    private func syncBackgroundSound() {
        let preferences = preferencesStore.preferences

        guard preferences.backgroundSoundEnabled else {
            soundCenter.stopLoop()
            return
        }

        switch currentSessionViewModel.sessionState.phase {
        case .focusing, .focusPaused:
            soundCenter.startLoop(
                named: preferences.sessionSoundName,
                volume: preferences.sessionSoundVolume
            )
        case .breakRunning, .breakPaused:
            soundCenter.startLoop(
                named: preferences.breakSoundName,
                volume: preferences.breakSoundVolume
            )
        case .idle, .reflecting, .completed, .abandoned:
            soundCenter.stopLoop()
        }
    }

    private func sidebarRow(for section: AppSection) -> some View {
        let isSelected = section == (viewModel.selectedSection ?? .tasks)

        return Button {
            guard viewModel.selectedSection != section else { return }
            withAnimation(.spring(response: 0.22, dampingFraction: 0.82, blendDuration: 0.12)) {
                viewModel.selectedSection = section
            }
        } label: {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 999, style: .continuous)
                    .fill(.clear)
                    .frame(width: 4, height: 24)

                Image(systemName: section.symbolName)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(
                        isSelected ? AppSurfaceTheme.primaryText : AppSurfaceTheme.secondaryText
                    )
                    .frame(width: 18)

                Text(section.sidebarTitle)
                    .font(
                        .system(
                            size: 16,
                            weight: isSelected ? .semibold : .medium,
                            design: .rounded
                        )
                    )
                    .foregroundStyle(
                        isSelected ? AppSurfaceTheme.primaryText : AppSurfaceTheme.secondaryText
                    )

                Spacer(minLength: 0)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 6)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.34),
                                    Color.white.opacity(0.16)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.white.opacity(0.28), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.08), radius: 14, y: 7)
                        .matchedGeometryEffect(id: "sidebarSelectionBackground", in: sidebarSelectionAnimation)
                }
            }
            .overlay(alignment: .leading) {
                if isSelected {
                    RoundedRectangle(cornerRadius: 999, style: .continuous)
                        .fill(AppSurfaceTheme.sidebarSelectionAccent)
                        .frame(width: 4, height: 24)
                        .offset(x: 6)
                        .matchedGeometryEffect(id: "sidebarSelectionAccent", in: sidebarSelectionAnimation)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func sidebarUtilityRow(for section: AppSection) -> some View {
        let isSelected = section == (viewModel.selectedSection ?? .tasks)

        return Button {
            guard viewModel.selectedSection != section else { return }
            withAnimation(.spring(response: 0.22, dampingFraction: 0.82, blendDuration: 0.12)) {
                viewModel.selectedSection = section
            }
        } label: {
            Image(systemName: section.symbolName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(
                    isSelected ? AppSurfaceTheme.primaryText : AppSurfaceTheme.secondaryText
                )
                .frame(width: 40, height: 40)
                .background {
                    if isSelected {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.34),
                                        Color.white.opacity(0.16)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.28), lineWidth: 1)
                            )
                    }
                }
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .help(section.title)
    }
}
