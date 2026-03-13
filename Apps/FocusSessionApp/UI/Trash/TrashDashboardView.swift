import SwiftUI

struct TrashDashboardView: View {
    @ObservedObject private var tasksViewModel: TasksViewModel
    @ObservedObject private var planViewModel: PlanViewModel

    init(tasksViewModel: TasksViewModel, planViewModel: PlanViewModel) {
        _tasksViewModel = ObservedObject(wrappedValue: tasksViewModel)
        _planViewModel = ObservedObject(wrappedValue: planViewModel)
    }

    var body: some View {
        ZStack {
            AppCanvasBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    completedTasksSection
                }
                .padding(28)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Trash")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(AppSurfaceTheme.primaryText)

            Text("Review completed tasks, then restore them or delete them permanently.")
                .font(.title3)
                .foregroundStyle(AppSurfaceTheme.secondaryText)
        }
    }

    private var completedTasksSection: some View {
        completedSectionCard(
            title: "Completed Tasks",
            count: tasksViewModel.completedTasks.count
        ) {
            if tasksViewModel.completedTasks.isEmpty {
                emptyState("No completed tasks")
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(tasksViewModel.completedTasks.enumerated()), id: \.element.id) { index, task in
                        completedTaskRow(task)

                        if index < tasksViewModel.completedTasks.count - 1 {
                            Divider()
                                .padding(.leading, 20)
                        }
                    }
                }
            }
        }
    }

    private func completedSectionCard<Content: View>(
        title: String,
        count: Int,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 10) {
                Text(title)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(AppSurfaceTheme.primaryText)

                Text("\(count)")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundStyle(AppSurfaceTheme.tertiaryText)
            }

            content()
        }
        .padding(22)
        .background(AppCardSurface(style: .standard, cornerRadius: 24))
    }

    private func completedTaskRow(_ task: FocusTask) -> some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(task.title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppSurfaceTheme.primaryText)

                if let details = task.details, !details.isEmpty {
                    Text(details)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(AppSurfaceTheme.secondaryText)
                }

                if let startAt = task.startAt, let endAt = task.endAt {
                    Text(TasksDashboardView.scheduleText(startAt: startAt, endAt: endAt))
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(AppSurfaceTheme.tertiaryText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 10) {
                Button("Restore") {
                    tasksViewModel.restoreTask(task)
                }
                .buttonStyle(AppGlassButtonStyle())

                Button("Delete") {
                    tasksViewModel.deleteTask(task)
                }
                .buttonStyle(
                    AppGlassButtonStyle(
                        tint: Color(red: 0.90, green: 0.40, blue: 0.42),
                        foregroundColor: Color(red: 0.63, green: 0.18, blue: 0.20)
                    )
                )
            }
        }
        .padding(.vertical, 14)
    }

    private func emptyState(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 15, weight: .medium, design: .rounded))
            .foregroundStyle(AppSurfaceTheme.tertiaryText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
    }

}
