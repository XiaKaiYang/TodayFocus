import XCTest
@testable import FocusSession

@MainActor
final class AppShellViewModelTests: XCTestCase {
    func testDefaultSelectionStartsAtTasks() {
        let viewModel = AppShellViewModel()

        XCTAssertEqual(viewModel.selectedSection, .tasks)
    }

    func testPreferenceLaunchSectionIsUsedWhenConfigurationDoesNotOverride() {
        let suiteName = UUID().uuidString
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let preferencesStore = AppPreferencesStore(userDefaults: defaults)
        preferencesStore.updateLaunchSection(.tasks)

        let viewModel = AppShellViewModel(preferencesStore: preferencesStore)

        XCTAssertEqual(viewModel.selectedSection, .tasks)
    }

    func testConfigurationLaunchSectionOverridesPreferenceLaunchSection() {
        let suiteName = UUID().uuidString
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let preferencesStore = AppPreferencesStore(userDefaults: defaults)
        preferencesStore.updateLaunchSection(.tasks)

        let viewModel = AppShellViewModel(
            configuration: AppLaunchConfiguration(
                environment: ["FOCUSSESSION_INITIAL_SECTION": "analytics"]
            ),
            preferencesStore: preferencesStore
        )

        XCTAssertEqual(viewModel.selectedSection, .analytics)
    }

    func testSectionsExposePrimarySidebarDestinations() {
        XCTAssertEqual(
            AppSection.allCases.map(\.sidebarTitle),
            [
                "Today",
                "Plan",
                "Session",
                "White Noise",
                "Notes",
                "Analytics",
                "Blocker",
                "Trash",
                "Settings"
            ]
        )
    }

    func testAppShellRoutesPlanSectionIntoDedicatedDashboard() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let appShellFileURL = root.appendingPathComponent("Apps/FocusSessionApp/UI/AppShell/AppShellView.swift")
        let appShellContents = try String(contentsOf: appShellFileURL, encoding: .utf8)

        XCTAssertTrue(
            appShellContents.contains("case .plan"),
            "The app shell should route the new Plan sidebar section."
        )
        XCTAssertTrue(
            appShellContents.contains("PlanDashboardView"),
            "The Plan section should render a dedicated dashboard instead of falling through to an existing screen."
        )
        XCTAssertTrue(
            appShellContents.contains("PlanDashboardView(viewModel: planViewModel, tasksViewModel: tasksViewModel, preferencesStore: preferencesStore)"),
            "The Plan screen should receive the shared tasks view model so it can open the full Today task composer from subtasks."
        )
        XCTAssertTrue(
            appShellContents.contains("case .trash"),
            "The app shell should route the unified completed-items trash section."
        )
        XCTAssertTrue(
            appShellContents.contains("TrashDashboardView(tasksViewModel: tasksViewModel, planViewModel: planViewModel)"),
            "The Trash section should render a dedicated dashboard for completed tasks."
        )
    }

    func testAppShellPinsTrashAndSettingsToBottomUtilityFooter() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let appShellFileURL = root.appendingPathComponent("Apps/FocusSessionApp/UI/AppShell/AppShellView.swift")
        let appShellContents = try String(contentsOf: appShellFileURL, encoding: .utf8)

        XCTAssertTrue(
            appShellContents.contains("ForEach(primarySidebarSections)"),
            "The scrollable sidebar list should render only the primary sections."
        )
        XCTAssertTrue(
            appShellContents.contains("private var primarySidebarSections: [AppSection]"),
            "The app shell should define a dedicated primary section collection instead of relying on allCases for the whole sidebar."
        )
        XCTAssertTrue(
            appShellContents.contains("AppSection.allCases.filter { $0 != .trash && $0 != .settings }"),
            "The primary sidebar collection should exclude both Trash and Settings so they can render in a fixed footer."
        )
        XCTAssertTrue(
            appShellContents.contains("private var footerSidebarSections: [AppSection]"),
            "The app shell should define a dedicated footer collection for utility destinations."
        )
        XCTAssertTrue(
            appShellContents.contains("ForEach(footerSidebarSections)"),
            "The footer should render utility destinations separately from the scrollable list."
        )
        XCTAssertTrue(
            appShellContents.contains("sidebarUtilityRow(for: section)"),
            "Trash and Settings should use a dedicated icon-only footer row style."
        )
    }

    func testAppShellUsesAnimatedLiquidSelectionForSidebar() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let appShellFileURL = root.appendingPathComponent("Apps/FocusSessionApp/UI/AppShell/AppShellView.swift")
        let appShellContents = try String(contentsOf: appShellFileURL, encoding: .utf8)

        XCTAssertTrue(
            appShellContents.contains("@Namespace private var sidebarSelectionAnimation"),
            "The sidebar should define a shared animation namespace so the active selection surface can slide between rows."
        )
        XCTAssertTrue(
            appShellContents.contains(#"matchedGeometryEffect(id: "sidebarSelectionBackground""#),
            "The selected sidebar row should render a shared background capsule for the liquid slide effect."
        )
        XCTAssertTrue(
            appShellContents.contains(#"matchedGeometryEffect(id: "sidebarSelectionAccent""#),
            "The leading accent should move with the shared selection surface instead of blinking in place."
        )
        XCTAssertTrue(
            appShellContents.contains("withAnimation(.spring("),
            "Sidebar section switches should use spring animation so the selection feels fluid when it moves."
        )
    }

    func testAppShellKeepsSidebarSwitchResponsiveWhileRefreshingSections() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let appShellFileURL = root.appendingPathComponent("Apps/FocusSessionApp/UI/AppShell/AppShellView.swift")
        let appShellContents = try String(contentsOf: appShellFileURL, encoding: .utf8)

        XCTAssertTrue(
            appShellContents.contains("withAnimation(.spring(response: 0.22"),
            "Sidebar selection should use a snappier spring so the switch does not feel delayed."
        )
        XCTAssertTrue(
            appShellContents.contains("Task { @MainActor in"),
            "Section refresh work should be deferred into an asynchronous task so the tab switch can render first."
        )
        XCTAssertTrue(
            appShellContents.contains("await Task.yield()"),
            "The app shell should yield once before reloading section data so the UI can commit the navigation change immediately."
        )
        XCTAssertTrue(
            appShellContents.contains("case .tasks:\n                    tasksViewModel.load()"),
            "Switching into Tasks should reload the task list so items created from Plan appear immediately."
        )
        XCTAssertTrue(
            appShellContents.contains("resolvedCurrentSessionViewModel.reloadData()"),
            "Task mutations should refresh the Current Session data source as well."
        )
        XCTAssertTrue(
            appShellContents.contains("resolvedPlanViewModel.load()"),
            "Task mutations should also refresh the Plan dashboard so derived subtask progress stays in sync."
        )
        XCTAssertTrue(
            appShellContents.contains("SharedTaskComposerSheet(viewModel: tasksViewModel)"),
            "The shared Today task composer should be hosted at the app shell level so both Plan and Tasks can present the same form."
        )
    }

    func testAppShellSharesAnalyticsViewModelAndRefreshesHistoryConsumersAfterSessionSubmit() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let appShellFileURL = root.appendingPathComponent("Apps/FocusSessionApp/UI/AppShell/AppShellView.swift")
        let appShellContents = try String(contentsOf: appShellFileURL, encoding: .utf8)

        XCTAssertTrue(
            appShellContents.contains("@StateObject private var analyticsViewModel"),
            "Analytics should use a shared view model instance so reflection submits refresh the current dashboard data immediately."
        )
        XCTAssertTrue(
            appShellContents.contains("AnalyticsDashboardView(viewModel: analyticsViewModel)"),
            "The analytics screen should render with the shared analytics view model instead of creating a fresh instance on each section switch."
        )
        XCTAssertTrue(
            appShellContents.contains("resolvedAnalyticsViewModel.load()"),
            "Session-history updates should refresh analytics as soon as the reflection submit writes a completed session."
        )
        XCTAssertTrue(
            appShellContents.contains("resolvedNotesViewModel.load()"),
            "Session-history updates should also refresh the Notes library after reflection submit."
        )
    }

    func testSettingsLaunchDestinationIncludesPlan() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let settingsFileURL = root.appendingPathComponent("Apps/FocusSessionApp/UI/Settings/SettingsDashboardView.swift")
        let settingsContents = try String(contentsOf: settingsFileURL, encoding: .utf8)

        XCTAssertTrue(
            settingsContents.contains("AppDropdownOption(value: .plan"),
            "Startup settings should allow launching straight into Plan."
        )
    }

    func testAppConfiguresCustomStatusItemWithCurrentSessionTitle() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let appFileURL = root.appendingPathComponent("Apps/FocusSessionApp/FocusSessionApp.swift")
        let statusItemFileURL = root.appendingPathComponent("Apps/FocusSessionApp/UI/AppShell/CurrentSessionStatusItemController.swift")
        let appContents = try String(contentsOf: appFileURL, encoding: .utf8)
        let statusItemContents = try String(contentsOf: statusItemFileURL, encoding: .utf8)

        XCTAssertTrue(
            appContents.contains("CurrentSessionStatusItemController"),
            "The app should expose a macOS status item controller so active focus work can surface in the system menu bar."
        )
        XCTAssertTrue(
            statusItemContents.contains("currentSessionViewModel.statusItemTitle(at:"),
            "The status item should use the dedicated live status title so it can show the active task text and countdown after Start Session."
        )
    }

    func testVisibleAppNameFallsBackToTodayFocus() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let appFileURL = root.appendingPathComponent("Apps/FocusSessionApp/UI/AppShell/CurrentSessionStatusItemController.swift")
        let projectFileURL = root.appendingPathComponent("project.yml")
        let infoPlistURL = root.appendingPathComponent("Apps/FocusSessionApp/Info.plist")

        let appContents = try String(contentsOf: appFileURL, encoding: .utf8)
        let projectContents = try String(contentsOf: projectFileURL, encoding: .utf8)
        let infoPlistContents = try String(contentsOf: infoPlistURL, encoding: .utf8)

        XCTAssertTrue(
            appContents.contains("Open TodayFocus"),
            "The menu bar action should use the user-facing app name TodayFocus."
        )
        XCTAssertTrue(
            projectContents.contains("CFBundleDisplayName: TodayFocus"),
            "The generated app display name should use TodayFocus."
        )
        XCTAssertTrue(
            projectContents.contains("PRODUCT_NAME: TodayFocus"),
            "The built app bundle should also be named TodayFocus so macOS surfaces the right title in the UI."
        )
        XCTAssertTrue(
            infoPlistContents.contains("<string>TodayFocus</string>"),
            "The source Info.plist should also fall back to TodayFocus so the user-facing app name stays consistent."
        )
    }

    func testAppKeepsFocusSessionModuleNameWhileShippingTodayFocusBundleName() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let projectFileURL = root.appendingPathComponent("project.yml")
        let projectContents = try String(contentsOf: projectFileURL, encoding: .utf8)

        XCTAssertTrue(
            projectContents.contains("PRODUCT_MODULE_NAME: FocusSession"),
            "The Swift module should stay FocusSession so the existing source and tests do not need a full import rename."
        )
        XCTAssertTrue(
            projectContents.contains("TEST_HOST: $(BUILT_PRODUCTS_DIR)/TodayFocus.app/Contents/MacOS/TodayFocus"),
            "The app test host should follow the renamed TodayFocus bundle and executable."
        )
    }
}
