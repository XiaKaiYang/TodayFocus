import XCTest

final class SettingsDashboardViewSourceTests: XCTestCase {
    func testStartupSettingsExposePlanGoalLaunchExpansionPreference() throws {
        let root = "/Users/xiakaiyang/Documents/New project/Apps/FocusSessionApp"
        let settingsSource = try String(
            contentsOfFile: "\(root)/UI/Settings/SettingsDashboardView.swift",
            encoding: .utf8
        )
        let settingsViewModelSource = try String(
            contentsOfFile: "\(root)/ViewModels/SettingsViewModel.swift",
            encoding: .utf8
        )
        let appPreferencesSource = try String(
            contentsOfFile: "\(root)/AppPreferencesStore.swift",
            encoding: .utf8
        )
        let appShellSource = try String(
            contentsOfFile: "\(root)/UI/AppShell/AppShellView.swift",
            encoding: .utf8
        )
        let appSource = try String(
            contentsOfFile: "\(root)/FocusSessionApp.swift",
            encoding: .utf8
        )

        XCTAssertTrue(appPreferencesSource.contains("enum PlanGoalLaunchExpansion"))
        XCTAssertTrue(appPreferencesSource.contains("var planGoalLaunchExpansion"))
        XCTAssertTrue(appPreferencesSource.contains("updatePlanGoalLaunchExpansion"))

        XCTAssertTrue(settingsSource.contains("Plan Goal Subtasks"))
        XCTAssertTrue(settingsSource.contains("viewModel.preferences.planGoalLaunchExpansion"))
        XCTAssertTrue(settingsSource.contains("viewModel.updatePlanGoalLaunchExpansion"))
        XCTAssertTrue(settingsSource.contains("Default Collapsed"))
        XCTAssertTrue(settingsSource.contains("Default Expanded"))

        XCTAssertTrue(settingsViewModelSource.contains("func updatePlanGoalLaunchExpansion"))
        XCTAssertTrue(appShellSource.contains("PlanDashboardView(viewModel: planViewModel, tasksViewModel: tasksViewModel, preferencesStore: preferencesStore)"))
        XCTAssertTrue(appSource.contains("SettingsViewModel(preferencesStore: services.preferencesStore)"))
    }
}
