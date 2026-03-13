import SwiftUI

struct TasksDashboardView: View {
    @ObservedObject private var viewModel: TasksViewModel
    @State private var collapsedPriorities: Set<TaskPriority> = []
    @State private var selectedScope: TasksDashboardScope = .today
    private let onTaskStarted: () -> Void

    init(
        viewModel: TasksViewModel = TasksViewModel(),
        onTaskStarted: @escaping () -> Void = {}
    ) {
        _viewModel = ObservedObject(wrappedValue: viewModel)
        self.onTaskStarted = onTaskStarted
    }

    var body: some View {
        let prioritySections = viewModel.prioritySections(in: selectedScope)

        ZStack {
            AppCanvasBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    headerRow

                    if prioritySections.isEmpty {
                        Text(selectedScope == .today ? "No active tasks" : "No tasks for tomorrow")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(AppSurfaceTheme.tertiaryText)
                    } else {
                        ForEach(prioritySections) { section in
                            prioritySection(section, scope: selectedScope)
                        }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 28)
                .padding(.bottom, 112)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .overlay(alignment: .bottom) {
            scopeSwitcher
        }
        .onAppear {
            selectedScope = .today
        }
    }

    private var headerRow: some View {
        HStack(alignment: .center, spacing: 18) {
            Text(selectedScope == .today ? "Today" : "Tomorrow")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(AppSurfaceTheme.primaryText)

            Spacer(minLength: 20)

            if selectedScope == .today {
                Button("Creat") {
                    viewModel.presentCreateSheet()
                }
                .buttonStyle(AppAccentButtonStyle())
            }
        }
    }

    private func taskActionRow(task: FocusTask, scope: TasksDashboardScope) -> some View {
        ViewThatFits(in: .horizontal) {
            taskActionRowContent(task: task, scope: scope)

            VStack(alignment: .leading, spacing: 8) {
                Text("\(task.estimatedMinutes) min")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(AppSurfaceTheme.tertiaryText)

                taskActionButtons(task: task, scope: scope)
            }
        }
    }

    private func taskDescriptionBlock(task: FocusTask) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center, spacing: 8) {
                Text(task.title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(task.isCompleted ? AppSurfaceTheme.secondaryText : AppSurfaceTheme.primaryText)
                    .strikethrough(task.isCompleted, color: AppSurfaceTheme.tertiaryText)

                taskRecurrenceBadge(for: task)
                linkedTaskBadge(for: task)

                Spacer(minLength: 0)
            }

            if let details = task.details, !details.isEmpty {
                Text(details)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(task.isCompleted ? AppSurfaceTheme.tertiaryText : AppSurfaceTheme.secondaryText)
                    .lineLimit(2)
            }

            if let repeatSummary = taskRepeatSummaryText(for: task) {
                Text(repeatSummary)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(AppSurfaceTheme.tertiaryText)
                    .lineLimit(1)
            }

        }
        .opacity(task.isCompleted ? 0.74 : 1)
    }

    private func prioritySection(
        _ section: TaskPrioritySection,
        scope: TasksDashboardScope
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Button {
                toggleSection(section.priority)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: collapsedPriorities.contains(section.priority) ? "chevron.right" : "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppSurfaceTheme.secondaryText)

                    Text(section.title)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(AppSurfaceTheme.primaryText)

                    Text("\(section.tasks.count)")
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .foregroundStyle(AppSurfaceTheme.tertiaryText)

                    Spacer(minLength: 0)
                }
            }
            .buttonStyle(.plain)

            if !collapsedPriorities.contains(section.priority) {
                if section.tasks.isEmpty {
                    Text("No tasks yet")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(AppSurfaceTheme.tertiaryText)
                        .padding(.leading, 30)
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(section.tasks.enumerated()), id: \.element.id) { index, task in
                            taskRow(task, scope: scope)

                            if index < section.tasks.count - 1 {
                                Divider()
                                    .padding(.leading, scope == .today ? 44 : 20)
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func taskRow(
        _ task: FocusTask,
        scope: TasksDashboardScope
    ) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 14) {
                if scope == .today {
                    completionToggle(for: task)
                }

                taskDescriptionBlock(task: task)
                    .frame(maxWidth: .infinity, alignment: .leading)

                taskActionRow(task: task, scope: scope)
                    .layoutPriority(1)
            }

            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 14) {
                    if scope == .today {
                        completionToggle(for: task)
                    }

                    taskDescriptionBlock(task: task)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                taskActionRow(task: task, scope: scope)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.vertical, 16)
        .padding(.leading, scope == .today ? 28 : 20)
        .padding(.trailing, 4)
    }

    private func completionToggle(for task: FocusTask) -> some View {
        Button {
            if task.isCompleted {
                viewModel.restoreTask(task)
            } else {
                viewModel.markTaskCompleted(task)
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(priorityTint(for: task.priority), lineWidth: 2)
                    .frame(width: 28, height: 28)

                if task.isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(priorityTint(for: task.priority))
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.top, 2)
    }

    private func taskActionRowContent(task: FocusTask, scope: TasksDashboardScope) -> some View {
        HStack(spacing: 10) {
            Text("\(task.estimatedMinutes) min")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(AppSurfaceTheme.tertiaryText)

            taskActionButtons(task: task, scope: scope)
        }
    }

    private func taskActionButtons(
        task: FocusTask,
        scope: TasksDashboardScope
    ) -> some View {
        HStack(spacing: 10) {
            if scope == .today && !task.isCompleted {
                Button {
                    if viewModel.startFocus(for: task) {
                        onTaskStarted()
                    }
                } label: {
                    Text("Select")
                        .lineLimit(1)
                        .frame(minWidth: 78)
                }
                .buttonStyle(AppAccentButtonStyle())
            }

            Button("Edit") {
                viewModel.presentEditSheet(for: task)
            }
            .buttonStyle(AppGlassButtonStyle())

            Button("Delete") {
                viewModel.deleteTask(task)
            }
            .buttonStyle(
                AppGlassButtonStyle(
                    tint: Color(red: 0.90, green: 0.40, blue: 0.42),
                    foregroundColor: Color(red: 0.63, green: 0.18, blue: 0.20)
                )
            )
            .lineLimit(1)
        }
    }

    private func toggleSection(_ priority: TaskPriority) {
        if collapsedPriorities.contains(priority) {
            collapsedPriorities.remove(priority)
        } else {
            collapsedPriorities.insert(priority)
        }
    }

    private func priorityTint(for priority: TaskPriority) -> Color {
        switch priority {
        case .high:
            Color(red: 0.86, green: 0.30, blue: 0.28)
        case .medium:
            Color(red: 0.78, green: 0.57, blue: 0.29)
        case .low:
            Color(red: 0.45, green: 0.56, blue: 0.68)
        case .none:
            Color(red: 0.56, green: 0.56, blue: 0.56)
        }
    }

    @ViewBuilder
    private func taskRecurrenceBadge(for task: FocusTask) -> some View {
        if task.isRepeating, let recurrenceProgressText = task.recurrenceProgressText {
            let badgeText = recurrenceProgressText == "∞" ? "∞" : recurrenceProgressText

            HStack(spacing: 5) {
                Image(systemName: "repeat")
                    .font(.system(size: 10, weight: .bold))

                Text(badgeText)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
            }
            .foregroundStyle(Color(red: 0.43, green: 0.44, blue: 0.49))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule(style: .continuous)
                    .fill(Color(red: 0.90, green: 0.90, blue: 0.92))
            )
        }
    }

    @ViewBuilder
    private func linkedTaskBadge(for task: FocusTask) -> some View {
        if task.isLinkedToSubtask {
            HStack(spacing: 5) {
                Image(systemName: "link")
                    .font(.system(size: 10, weight: .bold))

                Text("Linked")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
            }
            .foregroundStyle(AppSurfaceTheme.taskSelectorWarmText)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule(style: .continuous)
                    .fill(AppSurfaceTheme.taskSelectorWarmBorder.opacity(0.14))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(AppSurfaceTheme.taskSelectorWarmBorder.opacity(0.28), lineWidth: 1)
            )
        }
    }

    private func taskRepeatSummaryText(for task: FocusTask) -> String? {
        guard task.repeatRule != .none else {
            return nil
        }

        var parts = [task.repeatRule.title]
        if task.repeatRule == .weekly, let repeatWeekday = task.repeatWeekday {
            parts.append(repeatWeekday.title)
        }

        return parts.joined(separator: " · ")
    }

    private var scopeSwitcher: some View {
        HStack {
            Spacer(minLength: 0)

            HStack(spacing: 14) {
                ForEach(TasksDashboardScope.allCases, id: \.self) { scope in
                    let isSelected = scope == selectedScope
                    let helpTitle = scope == .today ? "Today" : "Tomorrow"

                    Button {
                        guard selectedScope != scope else { return }
                        withAnimation(.spring(response: 0.22, dampingFraction: 0.84, blendDuration: 0.12)) {
                            selectedScope = scope
                        }
                    } label: {
                        Image(systemName: scopeSwitcherSymbolName(for: scope))
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(
                                isSelected
                                    ? AppSurfaceTheme.taskSelectorWarmGlyph
                                    : AppSurfaceTheme.secondaryText
                            )
                            .frame(width: 20, height: 20)
                            .frame(width: 34, height: 30)
                    }
                    .buttonStyle(.plain)
                    .help(helpTitle)
                    .accessibilityLabel(helpTitle)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                AppGlassCapsuleSurface(
                    tint: AppSurfaceTheme.taskSelectorWarmBorder
                )
            )

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
        .padding(.top, 6)
        .padding(.bottom, 18)
    }

    private func scopeSwitcherSymbolName(for scope: TasksDashboardScope) -> String {
        switch scope {
        case .today:
            "sun.max"
        case .tomorrow:
            "calendar"
        }
    }

    static func scheduleText(
        startAt: Date,
        endAt: Date,
        calendar: Calendar = .current,
        referenceDate: Date = Date()
    ) -> String {
        let dateTimeFormatter = makeTaskDateTimeFormatter(timeZone: calendar.timeZone)
        let timeFormatter = makeTaskTimeFormatter(timeZone: calendar.timeZone)

        if calendar.isDate(startAt, inSameDayAs: endAt) {
            if calendar.isDate(startAt, inSameDayAs: referenceDate) {
                return "今日 \(timeFormatter.string(from: startAt)) - \(timeFormatter.string(from: endAt))"
            }

            return "\(dateTimeFormatter.string(from: startAt)) - \(timeFormatter.string(from: endAt))"
        }

        let startText = calendar.isDate(startAt, inSameDayAs: referenceDate)
            ? "今日 \(timeFormatter.string(from: startAt))"
            : dateTimeFormatter.string(from: startAt)
        let endText = calendar.isDate(endAt, inSameDayAs: referenceDate)
            ? "今日 \(timeFormatter.string(from: endAt))"
            : dateTimeFormatter.string(from: endAt)

        return "\(startText) - \(endText)"
    }

    private static func makeTaskDateTimeFormatter(timeZone: TimeZone) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.timeZone = timeZone
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter
    }

    private static func makeTaskTimeFormatter(timeZone: TimeZone) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.timeZone = timeZone
        formatter.dateFormat = "HH:mm"
        return formatter
    }
}

struct SharedTaskComposerSheet: View {
    @ObservedObject private var viewModel: TasksViewModel

    init(viewModel: TasksViewModel) {
        _viewModel = ObservedObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            AppCanvasBackground()

            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(viewModel.isEditingTask ? "Edit" : "Creat")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(AppSurfaceTheme.primaryText)

                    Text(viewModel.isEditingTask
                         ? "Update the task, repeat cadence, and priority."
                         : "Add a task, choose repeat cadence, set the focus length, then jump back into the list.")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(AppSurfaceTheme.secondaryText)
                }

                AppPromptedTextField("Task title", text: $viewModel.newTaskTitle)

                AppPromptedTextField(
                    "Notes (optional)",
                    text: $viewModel.newTaskDetails,
                    axis: .vertical,
                    verticalPadding: 14
                )

                if viewModel.linkedSubtaskID != nil {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Linked Subtask")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppSurfaceTheme.secondaryText)

                        Text(viewModel.linkedSubtaskTitle ?? "Selected from Plan")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(AppSurfaceTheme.primaryText)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppInputSurface(cornerRadius: 18))

                        AppPromptedTextField(
                            "Contribution value",
                            text: $viewModel.contributionValueText
                        )
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Priority")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppSurfaceTheme.secondaryText)

                    AppSegmentedControl(
                        options: TaskPriority.allCases,
                        selection: $viewModel.newTaskPriority,
                        tint: priorityTint(for: viewModel.newTaskPriority)
                    ) { priority in
                        priority.composerTitle
                        }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Repeat")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppSurfaceTheme.secondaryText)

                    AppSegmentedControl(
                        options: TaskRepeatRule.allCases,
                        selection: $viewModel.newTaskRepeatRule,
                        tint: priorityTint(for: viewModel.newTaskPriority)
                    ) { rule in
                        rule.title
                    }
                }

                if viewModel.newTaskRepeatRule == .weekly {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Repeat day")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppSurfaceTheme.secondaryText)

                        AppDropdownField(
                            selection: viewModel.newTaskRepeatWeekday,
                            selectedTitle: viewModel.newTaskRepeatWeekday.title,
                            options: repeatWeekdayOptions,
                            onSelect: { viewModel.newTaskRepeatWeekday = $0 }
                        )
                    }
                }

                if viewModel.newTaskRepeatRule != .none {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Repeat count")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppSurfaceTheme.secondaryText)

                        AppPromptedTextField(
                            "Leave blank for unlimited",
                            text: $viewModel.newTaskRepeatCountText
                        )
                    }
                }

                AppInlineStepper(
                    title: "Pomodoro",
                    valueText: "\(viewModel.newEstimatedMinutes) min",
                    decrementDisabled: viewModel.newEstimatedMinutes <= 5,
                    incrementDisabled: viewModel.newEstimatedMinutes >= 120,
                    onDecrement: {
                        viewModel.newEstimatedMinutes = max(5, viewModel.newEstimatedMinutes - 5)
                    },
                    onIncrement: {
                        viewModel.newEstimatedMinutes = min(120, viewModel.newEstimatedMinutes + 5)
                    }
                )

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.callout)
                        .foregroundStyle(.red)
                }

                HStack(spacing: 12) {
                    Spacer(minLength: 0)

                    Button("Cancel") {
                        viewModel.dismissCreateSheet()
                    }
                    .buttonStyle(AppGlassButtonStyle())

                    Button(viewModel.isEditingTask ? "Save" : "Creat") {
                        _ = viewModel.saveTask()
                    }
                    .buttonStyle(AppAccentButtonStyle())
                }
            }
            .padding(28)
            .frame(maxWidth: 460, alignment: .leading)
        }
    }

    private func priorityTint(for priority: TaskPriority) -> Color {
        switch priority {
        case .high:
            Color(red: 0.86, green: 0.30, blue: 0.28)
        case .medium:
            Color(red: 0.78, green: 0.57, blue: 0.29)
        case .low:
            Color(red: 0.45, green: 0.56, blue: 0.68)
        case .none:
            Color(red: 0.56, green: 0.56, blue: 0.56)
        }
    }

    private var repeatWeekdayOptions: [AppDropdownOption<TaskRepeatWeekday>] {
        TaskRepeatWeekday.allCases.map { weekday in
            AppDropdownOption(value: weekday, title: weekday.title)
        }
    }
}
