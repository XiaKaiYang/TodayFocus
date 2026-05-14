import XCTest

final class TrashDashboardViewSourceTests: XCTestCase {
    func testTrashPageIsRemovedFromNavigationAndSource() throws {
        let root = "/Users/xiakaiyang/Documents/New project/Apps/FocusSessionApp"
        let appSectionSource = try String(
            contentsOfFile: "\(root)/UI/AppShell/AppSection.swift",
            encoding: .utf8
        )
        let appShellSource = try String(
            contentsOfFile: "\(root)/UI/AppShell/AppShellView.swift",
            encoding: .utf8
        )
        let tasksDashboardSource = try String(
            contentsOfFile: "\(root)/UI/Tasks/TasksDashboardView.swift",
            encoding: .utf8
        )
        let planViewModelSource = try String(
            contentsOfFile: "\(root)/ViewModels/PlanViewModel.swift",
            encoding: .utf8
        )
        let trashDashboardPath = "\(root)/UI/Trash/TrashDashboardView.swift"

        XCTAssertFalse(appSectionSource.contains("case trash"))
        XCTAssertFalse(appSectionSource.contains("case .trash"))
        XCTAssertFalse(appSectionSource.contains("\"app.section.trash.title\""))

        XCTAssertFalse(appShellSource.contains("TrashDashboardView(tasksViewModel: tasksViewModel, planViewModel: planViewModel)"))
        XCTAssertFalse(appShellSource.contains("[.trash, .settings]"))
        XCTAssertTrue(appShellSource.contains("[.account, .settings]"))

        XCTAssertTrue(planViewModelSource.contains("var activeGoals: [PlanGoal]"))
        XCTAssertTrue(planViewModelSource.contains("var noMansLandGoals: [PlanGoal]"))
        XCTAssertTrue(planViewModelSource.contains("goals.filter { !$0.status.isTerminal }"))
        XCTAssertTrue(planViewModelSource.contains("goals.filter(\\.status.isTerminal)"))

        XCTAssertFalse(FileManager.default.fileExists(atPath: trashDashboardPath))

        XCTAssertFalse(tasksDashboardSource.contains("isTrashCollapsed"))
        XCTAssertFalse(tasksDashboardSource.contains("trashSection"))
        XCTAssertFalse(tasksDashboardSource.contains("Text(\"Trash\")"))
        XCTAssertFalse(tasksDashboardSource.contains("viewModel.trashedTasks"))
    }
}
