import XCTest

final class TrashDashboardViewSourceTests: XCTestCase {
    func testTrashPageOnlyOwnsCompletedTasks() throws {
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
        let trashDashboardSource = try String(
            contentsOfFile: "\(root)/UI/Trash/TrashDashboardView.swift",
            encoding: .utf8
        )

        XCTAssertTrue(appSectionSource.contains("case trash"))
        XCTAssertTrue(appSectionSource.contains("case .trash"))
        XCTAssertTrue(appSectionSource.contains("\"Trash\""))
        XCTAssertTrue(appSectionSource.contains("\"trash\""))

        XCTAssertTrue(appShellSource.contains("footerSidebarSections"))
        XCTAssertTrue(appShellSource.contains("sidebarUtilityRow(for: section)"))
        XCTAssertTrue(appShellSource.contains("TrashDashboardView(tasksViewModel: tasksViewModel, planViewModel: planViewModel)"))

        XCTAssertTrue(planViewModelSource.contains("var activeGoals: [PlanGoal]"))
        XCTAssertTrue(planViewModelSource.contains("var noMansLandGoals: [PlanGoal]"))
        XCTAssertTrue(planViewModelSource.contains("goals.filter { !$0.status.isTerminal }"))
        XCTAssertTrue(planViewModelSource.contains("goals.filter(\\.status.isTerminal)"))

        XCTAssertTrue(trashDashboardSource.contains("Completed Tasks"))
        XCTAssertTrue(trashDashboardSource.contains("tasksViewModel.completedTasks"))
        XCTAssertTrue(trashDashboardSource.contains("tasksViewModel.restoreTask(task)"))
        XCTAssertTrue(trashDashboardSource.contains("tasksViewModel.deleteTask(task)"))
        XCTAssertFalse(trashDashboardSource.contains("Completed Goals"))
        XCTAssertFalse(trashDashboardSource.contains("planViewModel.noMansLandGoals"))
        XCTAssertFalse(trashDashboardSource.contains("planViewModel.restoreGoal(goal)"))
        XCTAssertFalse(trashDashboardSource.contains("planViewModel.deleteGoal(goal)"))

        XCTAssertFalse(tasksDashboardSource.contains("isTrashCollapsed"))
        XCTAssertFalse(tasksDashboardSource.contains("trashSection"))
        XCTAssertFalse(tasksDashboardSource.contains("Text(\"Trash\")"))
        XCTAssertFalse(tasksDashboardSource.contains("viewModel.trashedTasks"))
    }
}
