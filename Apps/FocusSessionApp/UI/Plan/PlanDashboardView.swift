import AppKit
import Charts
import SwiftUI

struct PlanDashboardView: View {
    @ObservedObject private var viewModel: PlanViewModel
    @ObservedObject private var tasksViewModel: TasksViewModel
    @ObservedObject private var preferencesStore: AppPreferencesStore
    @State private var expandedGoalIDs: Set<UUID> = []
    @State private var isNoMansLandExpanded = false
    @State private var draggedGoalID: UUID?
    @State private var draggedGoalTranslation: CGFloat = 0
    @State private var draggedSubtaskID: UUID?
    @State private var draggedSubtaskTranslation: CGFloat = 0
    @State private var goalRowFrames: [UUID: CGRect] = [:]
    @State private var dragStartFrames: [UUID: CGRect] = [:]
    @State private var subtaskCardFrames: [UUID: CGRect] = [:]
    @State private var subtaskDragStartFrames: [UUID: CGRect] = [:]
    private let goalListCoordinateSpace = "plan-goal-list"

    init(
        viewModel: PlanViewModel = PlanViewModel(),
        tasksViewModel: TasksViewModel = TasksViewModel(),
        preferencesStore: AppPreferencesStore = AppPreferencesStore()
    ) {
        _viewModel = ObservedObject(wrappedValue: viewModel)
        _tasksViewModel = ObservedObject(wrappedValue: tasksViewModel)
        _preferencesStore = ObservedObject(wrappedValue: preferencesStore)
    }

    var body: some View {
        ZStack {
            AppCanvasBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    headerRow
                    timelineSection
                    goalsSection
                }
                .padding(.horizontal, 32)
                .padding(.top, 28)
                .padding(.bottom, 36)
            }
            .scrollDisabled(draggedGoalID != nil)
            .scrollDisabled(draggedGoalID != nil || draggedSubtaskID != nil)
            .coordinateSpace(name: goalListCoordinateSpace)
            .onPreferenceChange(GoalRowFramePreferenceKey.self) { updatedFrames in
                guard draggedGoalID == nil else { return }
                goalRowFrames = updatedFrames
            }
            .onPreferenceChange(SubtaskCardFramePreferenceKey.self) { updatedFrames in
                guard draggedSubtaskID == nil else { return }
                subtaskCardFrames = updatedFrames
            }
            .onAppear {
                viewModel.load()
                applyGoalSubtaskLaunchPreference()
            }
        }
        .sheet(isPresented: goalSheetBinding) {
            goalComposerSheet
        }
        .sheet(isPresented: subtaskSheetBinding) {
            subtaskComposerSheet
        }
    }

    private var goalSheetBinding: Binding<Bool> {
        Binding(
            get: { viewModel.isPresentingGoalSheet },
            set: { isPresented in
                if !isPresented {
                    viewModel.dismissGoalSheet()
                }
            }
        )
    }

    private var subtaskSheetBinding: Binding<Bool> {
        Binding(
            get: { viewModel.isPresentingSubtaskSheet },
            set: { isPresented in
                if !isPresented {
                    viewModel.dismissSubtaskSheet()
                }
            }
        )
    }

    private var goalSubtaskGridColumns: [GridItem] {
        [
            GridItem(.adaptive(minimum: 150, maximum: 180), spacing: 10, alignment: .top)
        ]
    }

    private var goalStatusColumns: [GridItem] {
        [
            GridItem(.adaptive(minimum: 118, maximum: 148), spacing: 8, alignment: .top)
        ]
    }

    private var headerRow: some View {
        HStack(alignment: .center, spacing: 18) {
            Text("Plan")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(AppSurfaceTheme.primaryText)

            Spacer(minLength: 20)

            Button("Creat") {
                viewModel.presentCreateSheet()
            }
            .buttonStyle(AppAccentButtonStyle())
        }
    }

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center, spacing: 14) {
                Text("Timeline")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(AppSurfaceTheme.primaryText)

                Spacer(minLength: 20)

                Button {
                    viewModel.shiftTimeline(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(AppGlassButtonStyle())

                Text(periodTitle)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppSurfaceTheme.secondaryText)
                    .frame(minWidth: 180)

                Button {
                    viewModel.shiftTimeline(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                }
                .buttonStyle(AppGlassButtonStyle())

                Button("Today") {
                    viewModel.jumpToToday()
                }
                .buttonStyle(AppGlassButtonStyle())
            }

            chartCard
        }
    }

    private var chartCard: some View {
        GeometryReader { geometry in
            let chartViewportWidth = max(geometry.size.width - 32, 1)

            TimelineHorizontalScrollContainer {
                Chart {
                    goalBars
                    todayRule
                }
                .chartOverlay { proxy in
                    GeometryReader { plotGeometry in
                        chartInteractionOverlay(proxy: proxy, geometry: plotGeometry)
                    }
                }
                .chartPlotStyle { plotContent in
                    plotContent
                        .padding(.top, 24)
                        .padding(.bottom, 14)
                }
                .chartXAxis { chartXAxis }
                .chartYAxis(.hidden)
                .chartYScale(domain: viewModel.timelineGoals.map(\.timelineRowID))
                .chartYScale(range: .plotDimension(startPadding: 20, endPadding: 64))
                .chartXScale(domain: viewModel.visibleWindow.start ... viewModel.visibleWindow.end)
                .frame(
                    width: chartContentWidth(forVisibleWidth: chartViewportWidth),
                    height: chartHeight
                )
                .padding(.horizontal, 16)
                .padding(.top, PlanTimelinePresentation.timelineCardTopPadding)
                .padding(.bottom, PlanTimelinePresentation.timelineCardBottomPadding)
            }
        }
        .frame(height: chartCardHeight)
        .background(AppCardSurface(style: .standard, cornerRadius: 24))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    @AxisContentBuilder
    private var chartXAxis: some AxisContent {
        if chartAxisDetailLevel == .monthsAndWeeks || chartAxisDetailLevel == .monthsWeeksAndDays {
            AxisMarks(values: .stride(by: .weekOfYear)) { _ in
                AxisGridLine(
                    stroke: StrokeStyle(lineWidth: 0.8, dash: [4, 4])
                )
                .foregroundStyle(Color(red: 0.76, green: 0.76, blue: 0.76).opacity(0.34))
            }
        }

        if chartAxisDetailLevel == .monthsWeeksAndDays {
            AxisMarks(values: .stride(by: .day, count: 3)) { _ in
                AxisGridLine(
                    stroke: StrokeStyle(lineWidth: 0.6, dash: [2, 5])
                )
                .foregroundStyle(Color(red: 0.76, green: 0.76, blue: 0.76).opacity(0.22))
            }
        }

        AxisMarks(values: .stride(by: .month)) { value in
            AxisGridLine(
                stroke: StrokeStyle(lineWidth: 1)
            )
            .foregroundStyle(Color(red: 0.76, green: 0.76, blue: 0.76).opacity(0.78))
            AxisTick()
            AxisValueLabel {
                if let date = value.as(Date.self) {
                    Text(PlanTimelinePresentation.monthAxisLabel(for: date))
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppSurfaceTheme.secondaryText)
                        .padding(.top, PlanTimelinePresentation.monthAxisLabelTopPadding)
                }
            }
        }
    }

    @ChartContentBuilder
    private var goalBars: some ChartContent {
        ForEach(viewModel.timelineGoals) { goal in
            let placement = PlanTimelinePresentation.labelPlacement(
                for: goal,
                within: viewModel.visibleWindow
            )
            RectangleMark(
                xStart: .value("Start", goal.startAt),
                xEnd: .value("End", goal.endAt),
                y: .value("Goal", goal.timelineRowID)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .foregroundStyle(statusColor(for: goal.status).opacity(0.18))
            .annotation(
                position: annotationPosition(for: placement),
                alignment: annotationAlignment(for: placement),
                spacing: 8
            ) {
                goalBarLabel(goal, placement: placement)
            }

            if let fillEnd = goalProgressFillEnd(for: goal) {
                RectangleMark(
                    xStart: .value("Start", goal.startAt),
                    xEnd: .value("End", fillEnd),
                    y: .value("Goal", goal.timelineRowID)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .foregroundStyle(statusColor(for: goal.status).opacity(0.52))
            }

            goalTimelineStatusMarker(for: goal)
        }
    }

    private var todayRule: some ChartContent {
        RuleMark(x: .value("Today", viewModel.referenceDate))
            .foregroundStyle(Color(red: 0.90, green: 0.73, blue: 0.18))
            .lineStyle(StrokeStyle(lineWidth: 2.5))
            .annotation(position: .top, alignment: .leading) {
                Text(PlanViewModel.todayMarkerTitle(referenceDate: viewModel.referenceDate))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppSurfaceTheme.primaryText)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(AppGlassCapsuleSurface(tint: Color(red: 0.86, green: 0.63, blue: 0.28)))
            }
    }

    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Goals")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(AppSurfaceTheme.primaryText)

            if viewModel.activeGoals.isEmpty {
                Text("No active goals right now.")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(AppSurfaceTheme.tertiaryText)
                    .padding(.vertical, 4)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.activeGoals.enumerated()), id: \.element.id) { index, goal in
                        goalRow(goal, readOnly: false)

                        if index < viewModel.activeGoals.count - 1 {
                            Divider()
                                .padding(.leading, 18)
                        }
                    }
                }
                .background(AppCardSurface(style: .standard, cornerRadius: 24))
            }

            VStack(alignment: .leading, spacing: 12) {
                Button {
                    toggleNoMansLand()
                } label: {
                    HStack(alignment: .center, spacing: 12) {
                        Text("No Man's Land")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(AppSurfaceTheme.primaryText)

                        if !viewModel.noMansLandGoals.isEmpty {
                            Text("\(viewModel.noMansLandGoals.count)")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(AppSurfaceTheme.secondaryText)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(AppGlassCapsuleSurface())
                        }

                        Spacer(minLength: 0)

                        Image(systemName: isNoMansLandExpanded ? "chevron.down" : "chevron.right")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(AppSurfaceTheme.secondaryText)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if isNoMansLandExpanded {
                    if viewModel.noMansLandGoals.isEmpty {
                        Text("No completed or unfinished goals drifting here yet.")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(AppSurfaceTheme.tertiaryText)
                            .padding(.vertical, 4)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(Array(viewModel.noMansLandGoals.enumerated()), id: \.element.id) { index, goal in
                                goalRow(goal, readOnly: true)

                                if index < viewModel.noMansLandGoals.count - 1 {
                                    Divider()
                                        .padding(.leading, 18)
                                }
                            }
                        }
                        .background(AppCardSurface(style: .standard, cornerRadius: 24))
                    }
                }
            }
        }
    }

    private func goalRow(_ goal: PlanGoal, readOnly: Bool) -> some View {
        return HStack(alignment: .top, spacing: 16) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(statusColor(for: goal.status))
                .frame(width: 6)
                .frame(maxHeight: .infinity)
                .opacity(goal.status == .completed ? 0.56 : 0.88)

            VStack(alignment: .leading, spacing: 14) {
                goalRowHeader(for: goal, readOnly: readOnly)
                goalProgressSummary(for: goal, readOnly: readOnly)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .id(goal.id)
        .background(goalRowFrameReader(for: goal))
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .highPriorityGesture(
            DragGesture(minimumDistance: 4, coordinateSpace: .named(goalListCoordinateSpace))
                .onChanged { value in
                    handleGoalDragChanged(for: goal, translation: value.translation.height, readOnly: readOnly)
                }
                .onEnded { _ in
                    handleGoalDragEnded(for: goal, readOnly: readOnly)
                }
        )
        .transaction { transaction in
            if draggedGoalID == goal.id {
                transaction.animation = nil
            }
        }
        .offset(y: dragOffset(for: goal))
        .zIndex(draggedGoalID == goal.id && !readOnly ? 1 : 0)
        .opacity(draggedGoalID == goal.id && !readOnly ? 0.92 : 1)
        .shadow(
            color: draggedGoalID == goal.id && !readOnly
                ? AppSurfaceTheme.glassShadow.opacity(0.78)
                : .clear,
            radius: draggedGoalID == goal.id && !readOnly ? 16 : 0,
            x: 0,
            y: draggedGoalID == goal.id && !readOnly ? 10 : 0
        )
    }

    private func goalRowHeader(for goal: PlanGoal, readOnly: Bool) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 16) {
                goalPrimaryDetails(for: goal)

                Spacer(minLength: 20)

                goalActionCluster(for: goal, readOnly: readOnly)
            }

            VStack(alignment: .leading, spacing: 12) {
                goalPrimaryDetails(for: goal)

                goalActionCluster(for: goal, readOnly: readOnly)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func goalActionCluster(for goal: PlanGoal, readOnly: Bool) -> some View {
        HStack(spacing: 10) {
            goalStatusCapsule(for: goal)

            if !readOnly {
                Button("Edit") {
                    viewModel.presentEditSheet(for: goal)
                }
                .buttonStyle(AppGlassButtonStyle())

                Button("Delete") {
                    viewModel.deleteGoal(goal)
                }
                .buttonStyle(
                    AppGlassButtonStyle(
                        tint: Color(red: 0.90, green: 0.40, blue: 0.42),
                        foregroundColor: Color(red: 0.63, green: 0.18, blue: 0.20)
                    )
                )
            }
        }
    }

    private func goalStatusCapsule(for goal: PlanGoal) -> some View {
        Text(goal.status.title)
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(AppSurfaceTheme.primaryText)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(AppGlassCapsuleSurface(tint: statusColor(for: goal.status)))
    }

    private var goalStatusFlowPicker: some View {
        LazyVGrid(columns: goalStatusColumns, alignment: .leading, spacing: 8) {
            ForEach(PlanGoalStatus.allCases, id: \.self) { status in
                goalStatusChip(for: status)
            }
        }
        .padding(6)
        .background(AppInputSurface(cornerRadius: 18))
    }

    private func goalStatusChip(for status: PlanGoalStatus) -> some View {
        let isSelected = status == viewModel.newGoalStatus

        return Button {
            viewModel.newGoalStatus = status
        } label: {
            Text(status.title)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(isSelected ? AppSurfaceTheme.primaryText : AppSurfaceTheme.secondaryText)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                .minimumScaleFactor(0.82)
                .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    Group {
                        if isSelected {
                            AppGlassRoundedSurface(
                                cornerRadius: 14,
                                tint: statusColor(for: status)
                            )
                        } else {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.clear)
                        }
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(
                            isSelected ? Color.clear : AppSurfaceTheme.outline.opacity(0.9),
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
    }

    private func goalPrimaryDetails(for goal: PlanGoal) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(goal.title)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(AppSurfaceTheme.primaryText)

            Text(goalDateText(goal))
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(AppSurfaceTheme.tertiaryText)

            if let notes = goal.notes, !notes.isEmpty {
                Text(notes)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(AppSurfaceTheme.secondaryText)
                    .lineLimit(2)
            }
        }
    }

    private var goalComposerSheet: some View {
        ZStack {
            AppCanvasBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(viewModel.isEditingGoal ? "Edit Goal" : "Create Goal")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(AppSurfaceTheme.primaryText)

                        Text(
                            viewModel.isEditingGoal
                                ? "Update the goal details here. Allocation Across Subtasks is edited below for this goal."
                                : "Set the long-term goal title, notes, date range, and status. Subtasks can be added from the expanded goal list after saving."
                        )
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(AppSurfaceTheme.secondaryText)
                    }

                    AppPromptedTextField("Goal title", text: $viewModel.newGoalTitle)

                    AppPromptedTextField(
                        "Notes (optional)",
                        text: $viewModel.newGoalNotes,
                        axis: .vertical,
                        verticalPadding: 14
                    )

                    if viewModel.isEditingGoal {
                        goalComposerAllocationSection
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Status")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppSurfaceTheme.secondaryText)

                        goalStatusFlowPicker
                    }

                    HStack(alignment: .top, spacing: 14) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Start time")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(AppSurfaceTheme.secondaryText)

                            DatePicker(
                                "",
                                selection: $viewModel.newGoalStartAt,
                                displayedComponents: [.date, .hourAndMinute]
                            )
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(AppInputSurface(cornerRadius: 18))
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("End time")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(AppSurfaceTheme.secondaryText)

                            DatePicker(
                                "",
                                selection: $viewModel.newGoalEndAt,
                                displayedComponents: [.date, .hourAndMinute]
                            )
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(AppInputSurface(cornerRadius: 18))
                        }
                    }

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.callout)
                            .foregroundStyle(.red)
                    }

                    HStack(spacing: 12) {
                        Spacer(minLength: 0)

                        Button("Cancel") {
                            viewModel.dismissGoalSheet()
                        }
                        .buttonStyle(AppGlassButtonStyle())

                        Button(viewModel.isEditingGoal ? "Save" : "Create") {
                            _ = viewModel.saveGoal()
                        }
                        .buttonStyle(AppAccentButtonStyle())
                    }
                }
                .padding(28)
                .frame(maxWidth: 560, alignment: .leading)
            }
        }
    }

    private var goalComposerAllocationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                Text("Allocation Across Subtasks")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppSurfaceTheme.secondaryText)

                Spacer(minLength: 12)

                Text(
                    "Allocated \(PlanViewModel.formatMetricValue(viewModel.goalComposerAllocatedGoalSharePercent))% · Remaining \(PlanViewModel.formatMetricValue(viewModel.goalComposerRemainingGoalSharePercent))%"
                )
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(AppSurfaceTheme.tertiaryText)
            }

            if viewModel.goalComposerSubtaskShareRows.isEmpty {
                Text("This goal does not have subtasks yet. Add subtasks from the expanded goal list, then return here to rebalance allocation.")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(AppSurfaceTheme.tertiaryText)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(viewModel.goalComposerSubtaskShareRows) { row in
                        HStack(alignment: .center, spacing: 12) {
                            Text(row.title)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(AppSurfaceTheme.primaryText)

                            Spacer(minLength: 12)

                            AppPromptedTextField(
                                "Goal Share %",
                                text: goalComposerSubtaskShareBinding(for: row)
                            )
                            .frame(width: 150)
                        }
                    }
                }
            }
        }
        .padding(18)
        .background(AppInputSurface(cornerRadius: 20))
    }

    private var chartHeight: CGFloat {
        PlanTimelinePresentation.chartHeight(forGoalCount: viewModel.timelineGoals.count)
    }

    private var chartCardHeight: CGFloat {
        chartHeight
            + PlanTimelinePresentation.timelineCardTopPadding
            + PlanTimelinePresentation.timelineCardBottomPadding
            + NSScroller.scrollerWidth(for: .regular, scrollerStyle: .legacy)
    }

    private var chartAxisDetailLevel: PlanTimelineAxisDetailLevel {
        PlanTimelinePresentation.axisDetailLevel(forVisibleMonthSpan: viewModel.visibleMonthSpanForPresentation)
    }

    private func chartContentWidth(forVisibleWidth visibleWidth: CGFloat) -> CGFloat {
        let multiplier = PlanTimelinePresentation.chartContentWidthMultiplier(forVisibleMonthSpan: viewModel.visibleMonthSpanForPresentation)
        return max(visibleWidth * multiplier, visibleWidth)
    }

    private var periodTitle: String {
        let startFormatter = DateFormatter()
        startFormatter.locale = Locale(identifier: "zh_CN")
        startFormatter.dateFormat = "yyyy年M月"

        let endFormatter = DateFormatter()
        endFormatter.locale = Locale(identifier: "zh_CN")
        endFormatter.dateFormat = "M月"

        let endDate = Calendar.autoupdatingCurrent.date(
            byAdding: .day,
            value: -1,
            to: viewModel.visibleWindow.end
        ) ?? viewModel.visibleWindow.end

        if Calendar.autoupdatingCurrent.isDate(
            viewModel.visibleWindow.start,
            equalTo: endDate,
            toGranularity: .year
        ) {
            return "\(startFormatter.string(from: viewModel.visibleWindow.start)) - \(endFormatter.string(from: endDate))"
        }

        return "\(startFormatter.string(from: viewModel.visibleWindow.start)) - \(startFormatter.string(from: endDate))"
    }

    private func goalDateText(_ goal: PlanGoal) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 HH:mm"
        return "\(formatter.string(from: goal.startAt)) - \(formatter.string(from: goal.endAt))"
    }

    @ViewBuilder
    private func goalProgressSummary(for goal: PlanGoal, readOnly: Bool) -> some View {
        let isExpanded = expandedGoalIDs.contains(goal.id)
        let progressTint = statusColor(for: goal.status)
        let progressPercent = viewModel.progressPercent(for: goal)

        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text("Overall Progress")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppSurfaceTheme.secondaryText)

                Spacer(minLength: 12)

                if let progressPercent {
                    Text("\(progressPercent)%")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(AppSurfaceTheme.primaryText)
                } else {
                    Text("No subtasks")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppSurfaceTheme.tertiaryText)
                }
            }

            if let progressPercent {
                GoalProgressBar(
                    progress: Double(progressPercent) / 100,
                    tint: progressTint
                )
                .frame(height: 10)

                HStack(alignment: .center, spacing: 12) {
                    Text("\(viewModel.completedSubtaskCount(for: goal)) / \(goal.subtasks.count) subtasks complete")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(AppSurfaceTheme.tertiaryText)

                    Spacer(minLength: 12)

                    if goal.hasSubtasks && !readOnly {
                        Button {
                            toggleGoalSubtasks(for: goal)
                        } label: {
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(AppSurfaceTheme.secondaryText)
                                .frame(width: 20, height: 20)
                                .contentShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .help(isExpanded ? "Hide Subtasks" : "Show Subtasks")
                    }
                }

                if isExpanded && !readOnly {
                    goalSubtasksExpansionPanel(for: goal)
                }
            } else {
                HStack(alignment: .center, spacing: 12) {
                    Text(readOnly ? "This completed goal has no recorded subtasks." : "Create the first subtask to start tracking milestone progress.")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(AppSurfaceTheme.tertiaryText)

                    Spacer(minLength: 12)

                    if !readOnly {
                        goalAddSubtaskButton(for: goal)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 2)
    }

    private func goalSubtasksExpansionPanel(for goal: PlanGoal) -> some View {
        LazyVGrid(columns: goalSubtaskGridColumns, alignment: .leading, spacing: 10) {
            ForEach(goal.subtasks, id: \.id) { subtask in
                goalSubtaskCard(for: goal, subtask: subtask)
            }

            VStack(spacing: 0) {
                Spacer(minLength: 0)
                goalAddSubtaskButton(for: goal)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .frame(minHeight: 64)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .transition(
            .opacity.combined(with: .scale(scale: 0.96, anchor: .topTrailing))
        )
    }

    private func goalSubtaskCard(for goal: PlanGoal, subtask: PlanGoalSubtask) -> some View {
        let progressPercent = viewModel.progressPercent(for: subtask)
        let linkedTaskCount = viewModel.linkedTaskCount(for: subtask)
        let tint = statusColor(for: goal.status)

        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Text(subtask.title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(AppSurfaceTheme.primaryText)
                    .lineLimit(1)

                Spacer(minLength: 8)

                Text("\(progressPercent)%")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(tint.opacity(0.86))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        Capsule(style: .continuous)
                            .fill(tint.opacity(0.08))
                    )
            }

            HStack(alignment: .center, spacing: 8) {
                ZStack {
                    Circle()
                        .fill(tint.opacity(0.10))
                        .frame(width: 20, height: 20)

                    Image(systemName: progressPercent >= 100 ? "star.fill" : "sparkles")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(
                            progressPercent >= 100
                                ? Color(red: 0.98, green: 0.86, blue: 0.45)
                                : tint.opacity(0.88)
                        )
                }

                VStack(alignment: .leading, spacing: 4) {
                    goalSubtaskMetricBlock(for: subtask)

                    goalSubtaskSecondaryBlock(for: subtask, linkedTaskCount: linkedTaskCount)
                }

                Spacer(minLength: 8)

                Button {
                    if subtask.trackingMode == .quantified {
                        viewModel.incrementSubtaskValue(for: goal, subtask: subtask)
                    } else {
                        viewModel.presentEditSubtaskSheet(for: goal, subtask: subtask)
                    }
                } label: {
                    opticallyCenteredPlusIcon(size: 10, tint: tint)
                        .frame(width: 22, height: 22)
                        .background(
                            Circle()
                                .fill(tint.opacity(0.10))
                        )
                        .overlay(
                            Circle()
                                .stroke(tint.opacity(0.16), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .help(subtask.trackingMode == .quantified ? "Add 1 to current value" : "Edit subtask and manage linked tasks")
            }
        }
        .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
        .padding(8)
        .background(
            subtaskCardProgressSurface(progress: Double(progressPercent) / 100, tint: tint)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(tint.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: tint.opacity(0.08), radius: 6, x: 0, y: 3)
        .background(subtaskCardFrameReader(for: subtask))
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onTapGesture {
            viewModel.presentEditSubtaskSheet(for: goal, subtask: subtask)
        }
        .contextMenu {
            Button("Edit") {
                viewModel.presentEditSubtaskSheet(for: goal, subtask: subtask)
            }

            if canMoveSubtaskLeft(subtask, in: goal) {
                Button("Move Left") {
                    animatedSubtaskReorder {
                        viewModel.moveSubtaskLeft(subtask.id, in: goal.id)
                    }
                }
            }

            if canMoveSubtaskRight(subtask, in: goal) {
                Button("Move Right") {
                    animatedSubtaskReorder {
                        viewModel.moveSubtaskRight(subtask.id, in: goal.id)
                    }
                }
            }

            Button("Delete", role: .destructive) {
                viewModel.deleteSubtask(subtask, from: goal)
            }
        }
        .highPriorityGesture(
            DragGesture(minimumDistance: 4, coordinateSpace: .named(goalListCoordinateSpace))
                .onChanged { value in
                    handleSubtaskDragChanged(
                        for: goal,
                        subtask: subtask,
                        translation: value.translation.width
                    )
                }
                .onEnded { _ in
                    handleSubtaskDragEnded(for: goal, subtask: subtask)
                }
        )
        .transaction { transaction in
            if draggedSubtaskID == subtask.id {
                transaction.animation = nil
            }
        }
        .offset(subtaskDragOffset(for: subtask))
        .zIndex(draggedSubtaskID == subtask.id ? 2 : 0)
        .opacity(draggedSubtaskID == subtask.id ? 0.94 : 1)
    }

    private func goalSubtaskMetricBlock(for subtask: PlanGoalSubtask) -> some View {
        Text(goalSubtaskMetricText(for: subtask))
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundStyle(AppSurfaceTheme.primaryText)
            .lineLimit(2)
            .frame(maxWidth: .infinity, minHeight: 30, alignment: .topLeading)
    }

    private func goalSubtaskSecondaryBlock(for subtask: PlanGoalSubtask, linkedTaskCount: Int) -> some View {
        Text(goalSubtaskSecondaryText(for: subtask, linkedTaskCount: linkedTaskCount))
            .font(.system(size: 8, weight: .semibold, design: .rounded))
            .foregroundStyle(AppSurfaceTheme.tertiaryText)
            .lineLimit(2)
            .frame(maxWidth: .infinity, minHeight: 18, alignment: .topLeading)
    }

    private func goalAddSubtaskButton(for goal: PlanGoal) -> some View {
        let tint = statusColor(for: goal.status)

        return Button {
            expandGoalSubtasks(for: goal)
            viewModel.presentCreateSubtaskSheet(for: goal)
        } label: {
            opticallyCenteredPlusIcon(size: 13, tint: tint)
                .frame(width: 30, height: 30)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.72))
                )
                .overlay(
                    Circle()
                        .stroke(tint.opacity(0.22), lineWidth: 1)
                )
                .shadow(color: tint.opacity(0.10), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
        .help("Create a new subtask")
        .accessibilityLabel("Create a new subtask")
    }

    private func opticallyCenteredPlusIcon(size: CGFloat, tint: Color) -> some View {
        Image(systemName: "plus")
            .font(.system(size: size, weight: .bold))
            .foregroundStyle(tint.opacity(0.92))
            .offset(y: 0.5)
    }

    private var subtaskComposerSheet: some View {
        ZStack {
            AppCanvasBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(viewModel.isEditingSubtask ? "Edit Subtask" : "Create Subtask")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(AppSurfaceTheme.primaryText)

                        Text("Subtask Metrics")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppSurfaceTheme.secondaryText)

                        Text("Choose Estimated when you only know the rough share of the goal, then switch to Quantified once the metric becomes clear.")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(AppSurfaceTheme.secondaryText)
                    }

                    AppPromptedTextField("Subtask title", text: $viewModel.subtaskDraftTitle)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Tracking Mode")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppSurfaceTheme.secondaryText)

                        AppSegmentedControl(
                            options: PlanGoalSubtaskTrackingMode.allCases,
                            selection: Binding(
                                get: { viewModel.subtaskDraftTrackingMode },
                                set: { viewModel.setSubtaskDraftTrackingMode($0) }
                            ),
                            tint: statusColor(for: .inProgress)
                        ) { mode in
                            mode.title
                        }
                    }

                    if viewModel.subtaskDraftTrackingMode == .quantified {
                        HStack(alignment: .top, spacing: 14) {
                            AppPromptedTextField(
                                "Current value",
                                text: Binding(
                                    get: { viewModel.subtaskDraftBaselineValue },
                                    set: { viewModel.setSubtaskDraftBaselineValue($0) }
                                )
                            )

                            AppPromptedTextField(
                                "Target value",
                                text: Binding(
                                    get: { viewModel.subtaskDraftTargetValue },
                                    set: { viewModel.setSubtaskDraftTargetValue($0) }
                                )
                            )
                        }

                        AppPromptedTextField(
                            "Unit label (optional)",
                            text: $viewModel.subtaskDraftUnitLabel
                        )
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Automatic Preview")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppSurfaceTheme.secondaryText)

                        HStack(alignment: .firstTextBaseline, spacing: 12) {
                            Text(subtaskPreviewMetricText)
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(AppSurfaceTheme.primaryText)

                            Spacer(minLength: 12)

                            Text("\(viewModel.currentSubtaskPreviewProgressPercent ?? 0)%")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundStyle(AppSurfaceTheme.primaryText)
                        }

                        if viewModel.subtaskDraftTrackingMode == .estimated {
                            DraggableGoalProgressBar(
                                progress: Double(viewModel.currentSubtaskPreviewProgressPercent ?? 0) / 100,
                                tint: Color(red: 0.78, green: 0.53, blue: 0.36),
                                onProgressChange: { progress in
                                    viewModel.setSubtaskDraftEstimatedPreviewProgress(progress * 100)
                                }
                            )
                            .frame(height: 20)
                        } else {
                            GoalProgressBar(
                                progress: Double(viewModel.currentSubtaskPreviewProgressPercent ?? 0) / 100,
                                tint: Color(red: 0.78, green: 0.53, blue: 0.36)
                            )
                            .frame(height: 10)
                        }
                    }
                    .padding(18)
                    .background(AppGlassRoundedSurface(cornerRadius: 20, tint: Color(red: 0.82, green: 0.70, blue: 0.60)))

                    if viewModel.subtaskDraftTrackingMode == .quantified {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .center, spacing: 12) {
                                Text("Linked Today Tasks")
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundStyle(AppSurfaceTheme.secondaryText)

                                Spacer(minLength: 12)

                                Button {
                                    presentNewTodayTaskFromSubtaskSheet()
                                } label: {
                                    linkedTaskActionButtonLabel(
                                        title: "NewT",
                                        subtitle: "Create today task",
                                        systemImage: "calendar.badge.plus",
                                        accent: Color(red: 0.84, green: 0.63, blue: 0.34)
                                    )
                                    .frame(maxWidth: .infinity, minHeight: 58)
                                }
                                .buttonStyle(
                                    AppGlassButtonStyle(
                                        cornerRadius: 20,
                                        tint: Color(red: 0.89, green: 0.77, blue: 0.66)
                                    )
                                )

                                Button {
                                    viewModel.presentLinkExistingTaskSheet()
                                } label: {
                                    linkedTaskActionButtonLabel(
                                        title: "LinkT",
                                        subtitle: "Attach existing",
                                        systemImage: "link.badge.plus",
                                        accent: Color(red: 0.56, green: 0.62, blue: 0.70)
                                    )
                                    .frame(maxWidth: .infinity, minHeight: 58)
                                }
                                .buttonStyle(
                                    AppGlassButtonStyle(
                                        cornerRadius: 20,
                                        tint: Color(red: 0.82, green: 0.86, blue: 0.91)
                                    )
                                )
                            }

                            if viewModel.linkedTasksForEditingSubtask.isEmpty {
                                Text("Save the subtask, then create or link Today tasks here.")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundStyle(AppSurfaceTheme.tertiaryText)
                            } else {
                                VStack(alignment: .leading, spacing: 10) {
                                    ForEach(viewModel.linkedTasksForEditingSubtask) { task in
                                        HStack(alignment: .firstTextBaseline, spacing: 12) {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(task.title)
                                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                                    .foregroundStyle(AppSurfaceTheme.primaryText)

                                                Text("Contribution \(PlanViewModel.formatMetricValue(task.contributionValue ?? 0))")
                                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                                    .foregroundStyle(AppSurfaceTheme.tertiaryText)
                                            }

                                            Spacer(minLength: 12)

                                            Button("Unlink") {
                                                viewModel.unlinkTask(task)
                                            }
                                            .buttonStyle(AppGlassButtonStyle())
                                        }
                                        .padding(14)
                                        .background(AppInputSurface(cornerRadius: 18))
                                    }
                                }
                            }
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Linked Today Tasks")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(AppSurfaceTheme.secondaryText)

                            Text("Convert this subtask to Quantified to link Today tasks.")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(AppSurfaceTheme.tertiaryText)
                        }
                    }

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.callout)
                            .foregroundStyle(.red)
                    }

                    HStack(spacing: 12) {
                        Spacer(minLength: 0)

                        Button("Cancel") {
                            viewModel.dismissSubtaskSheet()
                        }
                        .buttonStyle(AppGlassButtonStyle())

                        Button(viewModel.isEditingSubtask ? "Save" : "Create") {
                            _ = viewModel.saveSubtask()
                        }
                        .buttonStyle(AppAccentButtonStyle())
                    }
                }
                .padding(28)
                .frame(maxWidth: 560, alignment: .leading)
            }
        }
        .sheet(isPresented: taskLinkSheetBinding) {
            linkExistingTaskSheet
        }
    }

    private var taskLinkSheetBinding: Binding<Bool> {
        Binding(
            get: { viewModel.isPresentingTaskLinkSheet },
            set: { isPresented in
                if !isPresented {
                    viewModel.dismissTaskLinkSheet()
                }
            }
        )
    }

    private var linkExistingTaskSheet: some View {
        ZStack {
            AppCanvasBackground()

            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Link Existing Task")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(AppSurfaceTheme.primaryText)

                    Text("Select an existing Today task or repeating task. If it is already linked to another subtask, linking here will move it.")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(AppSurfaceTheme.secondaryText)
                }

                AppPromptedTextField(
                    "Contribution value",
                    text: $viewModel.linkTaskContributionValue
                )

                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        if viewModel.linkableTasks.isEmpty {
                            Text("No current Today tasks or repeating tasks are available to link.")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(AppSurfaceTheme.tertiaryText)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(14)
                                .background(AppInputSurface(cornerRadius: 18))
                        } else {
                            ForEach(viewModel.linkableTasks) { task in
                                Button {
                                    viewModel.selectTaskForLink(task)
                                } label: {
                                    HStack(alignment: .top, spacing: 12) {
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(task.title)
                                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                                .foregroundStyle(AppSurfaceTheme.primaryText)

                                            if let relationText = linkedTaskRelationText(for: task) {
                                                Text(relationText)
                                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                                    .foregroundStyle(AppSurfaceTheme.tertiaryText)
                                            }
                                        }

                                        Spacer(minLength: 12)

                                        if viewModel.selectedLinkTaskID == task.id {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(Color(red: 0.58, green: 0.66, blue: 0.42))
                                        }
                                    }
                                    .padding(14)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .fill(
                                                viewModel.selectedLinkTaskID == task.id
                                                ? Color.white.opacity(0.30)
                                                : Color.white.opacity(0.16)
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .frame(height: 260)

                HStack(spacing: 12) {
                    Spacer(minLength: 0)

                    Button("Cancel") {
                        viewModel.dismissTaskLinkSheet()
                    }
                    .buttonStyle(AppGlassButtonStyle())

                    Button("Link") {
                        _ = viewModel.confirmSelectedTaskLink()
                    }
                    .buttonStyle(AppAccentButtonStyle())
                }
            }
            .padding(28)
            .frame(maxWidth: 480, alignment: .leading)
        }
    }

    private var subtaskPreviewMetricText: String {
        if viewModel.subtaskDraftTrackingMode == .estimated {
            let progressValue = PlanViewModel.formatMetricValue(viewModel.currentSubtaskPreviewValue)
            return "\(progressValue)% complete"
        }

        let currentValue = PlanViewModel.formatMetricValue(viewModel.currentSubtaskPreviewValue)
        let targetValue = PlanViewModel.formatMetricValue(
            Double(viewModel.subtaskDraftTargetValue) ?? 0
        )
        let unitSuffix = viewModel.subtaskDraftUnitLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        return unitSuffix.isEmpty
            ? "\(currentValue) / \(targetValue)"
            : "\(currentValue) / \(targetValue) \(unitSuffix)"
    }

    private var estimatedCurrentCompletionField: some View {
        AppPromptedTextField(
            "Current completion %",
            text: $viewModel.subtaskDraftEstimatedProgressPercent
        )
    }

    private func goalSubtaskMetricText(for subtask: PlanGoalSubtask) -> String {
        if subtask.trackingMode == .estimated {
            return "\(viewModel.progressPercent(for: subtask))% complete"
        }

        let currentValue = PlanViewModel.formatMetricValue(viewModel.currentValue(for: subtask))
        let targetValue = PlanViewModel.formatMetricValue(subtask.targetValue)

        return subtask.unitLabel.isEmpty
            ? "\(currentValue)→\(targetValue)"
            : "\(currentValue)→\(targetValue) \(subtask.unitLabel)"
    }

    private func goalSubtaskSecondaryText(for subtask: PlanGoalSubtask, linkedTaskCount: Int) -> String {
        let goalShareText = "\(PlanViewModel.formatMetricValue(subtask.goalSharePercent))% of goal"

        guard subtask.trackingMode == .quantified else {
            return goalShareText
        }

        if linkedTaskCount == 0 {
            return goalShareText
        }

        return "\(goalShareText) · \(linkedTaskCount) linked tasks"
    }

    private func linkedTaskRelationText(for task: FocusTask) -> String? {
        guard let linkedSubtaskID = task.linkedSubtaskID else {
            return task.isCompleted ? "Completed task" : "Unlinked task"
        }

        guard let title = viewModel.subtaskTitle(for: linkedSubtaskID) else {
            return "Linked to another subtask"
        }

        return "Currently linked to \(title)"
    }

    private func presentNewTodayTaskFromSubtaskSheet() {
        guard let subtask = viewModel.prepareSubtaskForNewTask() else {
            return
        }

        tasksViewModel.presentCreateSheet(
            linkedSubtaskID: subtask.id,
            linkedSubtaskTitle: subtask.title,
            contributionValue: 1
        )
        viewModel.dismissSubtaskSheet()
    }

    private func goalComposerSubtaskShareBinding(for row: SubtaskSiblingShareRow) -> Binding<String> {
        Binding(
            get: { row.shareText },
            set: { viewModel.setGoalComposerSubtaskShareText($0, for: row.id) }
        )
    }

    private func canMoveSubtaskLeft(_ subtask: PlanGoalSubtask, in goal: PlanGoal) -> Bool {
        guard let index = goal.subtasks.firstIndex(where: { $0.id == subtask.id }) else {
            return false
        }

        return index > 0
    }

    private func canMoveSubtaskRight(_ subtask: PlanGoalSubtask, in goal: PlanGoal) -> Bool {
        guard let index = goal.subtasks.firstIndex(where: { $0.id == subtask.id }) else {
            return false
        }

        return index < goal.subtasks.count - 1
    }

    private func linkedTaskActionButtonLabel(
        title: String,
        subtitle: String,
        systemImage: String,
        accent: Color
    ) -> some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(accent.opacity(0.18))
                    .frame(width: 36, height: 36)

                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(accent.opacity(0.96))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(AppSurfaceTheme.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)

                Text(subtitle)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(AppSurfaceTheme.tertiaryText)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 4)
        .frame(maxWidth: .infinity, minHeight: 46, alignment: .leading)
    }

    private func goalRowFrameReader(for goal: PlanGoal) -> some View {
        GeometryReader { geometry in
            Color.clear.preference(
                key: GoalRowFramePreferenceKey.self,
                value: [goal.id: geometry.frame(in: .named(goalListCoordinateSpace))]
            )
        }
    }

    private func subtaskCardFrameReader(for subtask: PlanGoalSubtask) -> some View {
        GeometryReader { geometry in
            Color.clear.preference(
                key: SubtaskCardFramePreferenceKey.self,
                value: [subtask.id: geometry.frame(in: .named(goalListCoordinateSpace))]
            )
        }
    }

    private func dragOffset(for goal: PlanGoal) -> CGFloat {
        guard draggedGoalID == goal.id else {
            return 0
        }

        return draggedGoalTranslation
    }

    private func handleGoalDragChanged(for goal: PlanGoal, translation: CGFloat, readOnly: Bool) {
        guard !readOnly else { return }
        guard draggedGoalID == nil || draggedGoalID == goal.id else { return }

        if draggedGoalID == nil {
            draggedGoalID = goal.id
            dragStartFrames = goalRowFrames
        }

        draggedGoalTranslation = translation
    }

    private func handleGoalDragEnded(for goal: PlanGoal, readOnly: Bool) {
        guard !readOnly else { return }
        guard draggedGoalID == goal.id else { return }

        let dragTranslation = draggedGoalTranslation
        let stableFrames = dragStartFrames.isEmpty ? goalRowFrames : dragStartFrames
        defer {
            draggedGoalID = nil
            draggedGoalTranslation = 0
            dragStartFrames = [:]
        }

        guard abs(dragTranslation) > 8 else {
            return
        }

        guard let sourceFrame = stableFrames[goal.id] else {
            return
        }

        let draggedMidY = sourceFrame.midY + dragTranslation
        let nearestGoal = viewModel.activeGoals.min { lhs, rhs in
            guard
                let lhsFrame = stableFrames[lhs.id],
                let rhsFrame = stableFrames[rhs.id]
            else {
                return false
            }

            return abs(lhsFrame.midY - draggedMidY) < abs(rhsFrame.midY - draggedMidY)
        }

        guard let nearestGoal, nearestGoal.id != goal.id else {
            return
        }

        withAnimation(.spring(response: 0.24, dampingFraction: 0.84)) {
            viewModel.moveActiveGoal(goal.id, to: nearestGoal.id)
        }
    }

    private func subtaskDragOffset(for subtask: PlanGoalSubtask) -> CGSize {
        guard draggedSubtaskID == subtask.id else {
            return .zero
        }

        return CGSize(width: draggedSubtaskTranslation, height: 0)
    }

    private func handleSubtaskDragChanged(
        for goal: PlanGoal,
        subtask: PlanGoalSubtask,
        translation: CGFloat
    ) {
        guard draggedSubtaskID == nil || draggedSubtaskID == subtask.id else { return }

        if draggedSubtaskID == nil {
            draggedSubtaskID = subtask.id
            subtaskDragStartFrames = subtaskCardFrames
            expandGoalSubtasks(for: goal)
        }

        draggedSubtaskTranslation = translation
    }

    private func handleSubtaskDragEnded(for goal: PlanGoal, subtask: PlanGoalSubtask) {
        guard draggedSubtaskID == subtask.id else { return }

        let dragTranslation = draggedSubtaskTranslation
        let stableFrames = subtaskDragStartFrames.isEmpty ? subtaskCardFrames : subtaskDragStartFrames
        defer {
            draggedSubtaskID = nil
            draggedSubtaskTranslation = 0
            subtaskDragStartFrames = [:]
        }

        guard abs(dragTranslation) > 8 else {
            return
        }

        guard let sourceFrame = stableFrames[subtask.id] else {
            return
        }

        let draggedMidX = sourceFrame.midX + dragTranslation
        let candidateSubtasks = goal.subtasks.filter { $0.id != subtask.id }
        let nearestSubtask = candidateSubtasks.min { lhs, rhs in
            guard
                let lhsFrame = stableFrames[lhs.id],
                let rhsFrame = stableFrames[rhs.id]
            else {
                return false
            }

            return abs(lhsFrame.midX - draggedMidX) < abs(rhsFrame.midX - draggedMidX)
        }

        guard let nearestSubtask else {
            return
        }

        animatedSubtaskReorder {
            viewModel.moveSubtask(subtask.id, in: goal.id, to: nearestSubtask.id)
        }
    }

    private func animatedSubtaskReorder(_ action: () -> Void) {
        withAnimation(.spring(response: 0.24, dampingFraction: 0.84)) {
            action()
        }
    }

    private func toggleGoalSubtasks(for goal: PlanGoal) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if expandedGoalIDs.contains(goal.id) {
                expandedGoalIDs.remove(goal.id)
            } else {
                expandedGoalIDs.insert(goal.id)
            }
        }
    }

    private func expandGoalSubtasks(for goal: PlanGoal) {
        withAnimation(.easeInOut(duration: 0.2)) {
            _ = expandedGoalIDs.insert(goal.id)
        }
    }

    private func applyGoalSubtaskLaunchPreference() {
        expandedGoalIDs = initialExpandedGoalIDs()
    }

    private func initialExpandedGoalIDs() -> Set<UUID> {
        switch preferencesStore.preferences.planGoalLaunchExpansion {
        case .collapsed:
            []
        case .expanded:
            Set(viewModel.activeGoals.filter(\.hasSubtasks).map(\.id))
        }
    }

    private func toggleNoMansLand() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isNoMansLandExpanded.toggle()
        }
    }

    private func annotationPosition(for placement: PlanGoalLabelPlacement) -> AnnotationPosition {
        switch placement {
        case .inside:
            .overlay
        case .leadingOutside:
            .leading
        case .trailingOutside:
            .trailing
        }
    }

    private func annotationAlignment(for placement: PlanGoalLabelPlacement) -> Alignment {
        switch placement {
        case .inside:
            .center
        case .leadingOutside:
            .trailing
        case .trailingOutside:
            .leading
        }
    }

    @ViewBuilder
    private func goalBarLabel(_ goal: PlanGoal, placement: PlanGoalLabelPlacement) -> some View {
        let label = Text(goal.title)
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .lineLimit(1)

        switch placement {
        case .inside:
            label
                .foregroundStyle(AppSurfaceTheme.primaryText)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
        case .leadingOutside, .trailingOutside:
            label
                .foregroundStyle(AppSurfaceTheme.secondaryText)
        }
    }

    @ChartContentBuilder
    private func goalTimelineStatusMarker(for goal: PlanGoal) -> some ChartContent {
        if goal.status == .unfinished, let markerDate = goalTimelineMarkerDate(for: goal) {
            PointMark(
                x: .value("Status Marker", markerDate),
                y: .value("Goal", goal.timelineRowID)
            )
            .foregroundStyle(Color.clear)
            .symbolSize(1)
            .annotation(position: .overlay, alignment: .center) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.84, green: 0.24, blue: 0.22))
                    .padding(6)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.82))
                    )
            }
        }
    }

    private func goalTimelineMarkerDate(for goal: PlanGoal) -> Date? {
        let duration = goal.endAt.timeIntervalSince(goal.startAt)
        guard duration.isFinite, duration >= 0 else {
            return nil
        }

        return goal.startAt.addingTimeInterval(duration / 2)
    }

    @ViewBuilder
    private func chartInteractionOverlay(proxy: ChartProxy, geometry: GeometryProxy) -> some View {
        if let plotFrame = proxy.plotFrame {
            let plotRect = geometry[plotFrame]

            TimelineZoomTrackingSurface { _, deltaY, location in
                let anchorDate = proxy.value(atX: location.x, as: Date.self)
                viewModel.adjustTimelineZoom(deltaY: deltaY, anchorDate: anchorDate)
            }
            .frame(width: plotRect.width, height: plotRect.height)
            .position(x: plotRect.midX, y: plotRect.midY)
        }
    }

    private func goalBarOverlayFrame(
        for goal: PlanGoal,
        proxy: ChartProxy,
        plotRect: CGRect
    ) -> CGRect? {
        guard
            let xStart = proxy.position(forX: goal.startAt),
            let xEnd = proxy.position(forX: goal.endAt),
            let yPosition = proxy.position(forY: goal.timelineRowID)
        else {
            return nil
        }

        let centerX = plotRect.minX + (xStart + xEnd) / 2
        let width = max(abs(xEnd - xStart), 30)
        let height: CGFloat = 34

        return CGRect(
            x: centerX - width / 2,
            y: plotRect.minY + yPosition - height / 2,
            width: width,
            height: height
        )
    }

    private func statusColor(for status: PlanGoalStatus) -> Color {
        switch status {
        case .notStarted:
            Color(red: 0.63, green: 0.68, blue: 0.76)
        case .inProgress:
            Color(red: 0.88, green: 0.46, blue: 0.42)
        case .completed:
            Color(red: 0.42, green: 0.68, blue: 0.52)
        case .unfinished:
            Color(red: 0.84, green: 0.24, blue: 0.22)
        case .onHold:
            Color(red: 0.67, green: 0.60, blue: 0.49)
        }
    }

    private func goalProgressFillEnd(for goal: PlanGoal) -> Date? {
        guard let progressPercent = viewModel.progressPercent(for: goal), progressPercent > 0 else {
            return nil
        }

        let duration = goal.endAt.timeIntervalSince(goal.startAt)
        guard duration > 0 else {
            return progressPercent >= 100 ? goal.endAt : nil
        }

        let progress = min(max(Double(progressPercent) / 100, 0), 1)
        return goal.startAt.addingTimeInterval(duration * progress)
    }

    private func subtaskCardProgressSurface(progress: Double, tint: Color) -> some View {
        GeometryReader { geometry in
            let clampedProgress = min(max(progress, 0), 1)

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(tint.opacity(0.18))

                Rectangle()
                    .fill(tint.opacity(0.52))
                    .frame(width: geometry.size.width * clampedProgress)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}

private struct GoalProgressBar: View {
    let progress: Double
    let tint: Color

    var body: some View {
        GeometryReader { geometry in
            let clampedProgress = min(max(progress, 0), 1)

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: geometry.size.height / 2, style: .continuous)
                    .fill(Color.white.opacity(0.38))

                RoundedRectangle(cornerRadius: geometry.size.height / 2, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                tint.opacity(0.68),
                                tint
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(
                        width: max(
                            geometry.size.height,
                            geometry.size.width * clampedProgress
                        )
                    )
            }
        }
    }
}

private struct DraggableGoalProgressBar: View {
    let progress: Double
    let tint: Color
    let onProgressChange: (Double) -> Void

    var body: some View {
        GeometryReader { geometry in
            let clampedProgress = min(max(progress, 0), 1)
            let handleDiameter = max(geometry.size.height, 18)
            let fillWidth = max(handleDiameter, geometry.size.width * clampedProgress)
            let handleOffset = min(
                max((geometry.size.width * clampedProgress) - (handleDiameter / 2), 0),
                max(geometry.size.width - handleDiameter, 0)
            )

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: geometry.size.height / 2, style: .continuous)
                    .fill(Color.white.opacity(0.38))

                RoundedRectangle(cornerRadius: geometry.size.height / 2, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                tint.opacity(0.68),
                                tint
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: fillWidth)

                Circle()
                    .fill(Color.white.opacity(0.98))
                    .overlay(
                        Circle()
                            .fill(tint.opacity(0.92))
                            .padding(4)
                    )
                    .frame(width: handleDiameter, height: handleDiameter)
                    .shadow(color: tint.opacity(0.22), radius: 4, x: 0, y: 2)
                    .offset(x: handleOffset)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let nextProgress = min(max(value.location.x / max(geometry.size.width, 1), 0), 1)
                        onProgressChange(nextProgress)
                    }
            )
        }
    }
}

private struct TimelineZoomTrackingSurface: NSViewRepresentable {
    let onScroll: (CGFloat, CGFloat, CGPoint) -> Void

    func makeNSView(context: Context) -> TimelineZoomTrackingView {
        let view = TimelineZoomTrackingView(frame: .zero)
        view.onScroll = onScroll
        return view
    }

    func updateNSView(_ nsView: TimelineZoomTrackingView, context: Context) {
        nsView.onScroll = onScroll
    }
}

@MainActor
private struct TimelineHorizontalScrollContainer<Content: View>: NSViewRepresentable {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(rootView: content)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        configure(scrollView)

        let hostingView = context.coordinator.hostingView
        hostingView.layoutSubtreeIfNeeded()
        hostingView.frame = CGRect(origin: .zero, size: hostingView.fittingSize)
        scrollView.documentView = hostingView
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        configure(scrollView)

        let hostingView = context.coordinator.hostingView
        hostingView.rootView = content
        hostingView.layoutSubtreeIfNeeded()
        hostingView.frame = CGRect(origin: .zero, size: hostingView.fittingSize)

        if scrollView.documentView !== hostingView {
            scrollView.documentView = hostingView
        }
    }

    private func configure(_ scrollView: NSScrollView) {
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.hasHorizontalScroller = true
        scrollView.hasVerticalScroller = false
        scrollView.autohidesScrollers = false
        scrollView.scrollerStyle = .legacy
        scrollView.horizontalScrollElasticity = .allowed
        scrollView.verticalScrollElasticity = .none
    }

    @MainActor
    final class Coordinator {
        let hostingView: NSHostingView<Content>

        init(rootView: Content) {
            hostingView = NSHostingView(rootView: rootView)
        }
    }
}

struct TimelineZoomInteractionGate {
    private(set) var isActive = false

    mutating func activate() {
        isActive = true
    }

    mutating func deactivate() {
        isActive = false
    }

    mutating func deactivateIfNeeded(for location: CGPoint, in bounds: CGRect) {
        guard !bounds.contains(location) else { return }
        deactivate()
    }
}

enum TimelineZoomScrollRoute: Equatable {
    case zoom
    case passThrough
}

struct TimelineZoomScrollRouting {
    static func route(deltaX: CGFloat, deltaY: CGFloat, isZoomActive: Bool) -> TimelineZoomScrollRoute {
        guard isZoomActive else { return .passThrough }
        guard deltaX != 0 || deltaY != 0 else { return .passThrough }
        return abs(deltaY) > abs(deltaX) ? .zoom : .passThrough
    }
}

private final class TimelineZoomTrackingView: NSView {
    var onScroll: ((CGFloat, CGFloat, CGPoint) -> Void)?
    private var interactionGate = TimelineZoomInteractionGate()
    private var localClickMonitor: Any?
    private var localScrollMonitor: Any?
    private var windowResignObserver: NSObjectProtocol?

    override var isFlipped: Bool { true }

    override func hitTest(_ point: NSPoint) -> NSView? {
        nil
    }

    override func viewWillMove(toWindow newWindow: NSWindow?) {
        if newWindow == nil {
            removeEventMonitoring()
        }
        super.viewWillMove(toWindow: newWindow)
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard window != nil else { return }
        configureEventMonitoring()
        interactionGate.deactivate()
    }

    private func configureEventMonitoring() {
        removeEventMonitoring()

        localClickMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        ) { [weak self] event in
            guard let self else { return event }

            let location = self.convert(event.locationInWindow, from: nil)
            if self.bounds.contains(location) {
                self.interactionGate.activate()
            } else {
                self.interactionGate.deactivateIfNeeded(for: location, in: self.bounds)
            }

            return event
        }

        localScrollMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.scrollWheel]
        ) { [weak self] event in
            guard let self else { return event }

            let location = self.convert(event.locationInWindow, from: nil)
            guard self.bounds.contains(location) else {
                return event
            }

            switch TimelineZoomScrollRouting.route(
                deltaX: event.scrollingDeltaX,
                deltaY: event.scrollingDeltaY,
                isZoomActive: self.interactionGate.isActive
            ) {
            case .zoom:
                self.onScroll?(event.scrollingDeltaX, event.scrollingDeltaY, location)
                return nil
            case .passThrough:
                return event
            }
        }

        guard let window else { return }
        windowResignObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didResignKeyNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.interactionGate.deactivate()
            }
        }
    }

    private func removeEventMonitoring() {
        Self.removeEventMonitoring(
            localClickMonitor: localClickMonitor,
            localScrollMonitor: localScrollMonitor,
            windowResignObserver: windowResignObserver
        )
        localClickMonitor = nil
        localScrollMonitor = nil
        windowResignObserver = nil
    }

    private static func removeEventMonitoring(
        localClickMonitor: Any?,
        localScrollMonitor: Any?,
        windowResignObserver: NSObjectProtocol?
    ) {
        if let localClickMonitor {
            NSEvent.removeMonitor(localClickMonitor)
        }

        if let localScrollMonitor {
            NSEvent.removeMonitor(localScrollMonitor)
        }

        if let windowResignObserver {
            NotificationCenter.default.removeObserver(windowResignObserver)
        }
    }
}

private struct GoalRowFramePreferenceKey: PreferenceKey {
    static let defaultValue: [UUID: CGRect] = [:]

    static func reduce(value: inout [UUID: CGRect], nextValue: () -> [UUID: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

private struct SubtaskCardFramePreferenceKey: PreferenceKey {
    static let defaultValue: [UUID: CGRect] = [:]

    static func reduce(value: inout [UUID: CGRect], nextValue: () -> [UUID: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}
