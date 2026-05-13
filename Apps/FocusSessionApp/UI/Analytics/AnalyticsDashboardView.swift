import SwiftUI

struct AnalyticsDashboardView: View {
    @StateObject private var viewModel: AnalyticsViewModel

    init(viewModel: AnalyticsViewModel = AnalyticsViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        GeometryReader { geometry in
            let widthTier = AppResponsiveWidthTier.detail(for: geometry.size.width)
            let contentInsets = DetailDashboardLayoutMetrics.contentInsets(for: widthTier)

            ZStack {
                AppCanvasBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        header
                        summaryGrid(widthTier: widthTier)
                        if widthTier == .compact {
                            VStack(alignment: .leading, spacing: 24) {
                                trendCard
                                focusBreakdownCard
                            }
                        } else {
                            HStack(alignment: .top, spacing: 24) {
                                trendCard
                                focusBreakdownCard
                            }
                        }
                        moodSummaryCard(widthTier: widthTier)
                        recentSessionsCard
                    }
                    .padding(.top, contentInsets.top)
                    .padding(.leading, contentInsets.leading)
                    .padding(.trailing, contentInsets.trailing)
                    .padding(.bottom, contentInsets.bottom)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.callout)
                    .foregroundStyle(.red)
            }

            DashboardTimeNavigator(
                selectedScope: viewModel.selectedScope,
                referenceTitle: viewModel.referenceTitle,
                timeStrip: viewModel.timeStrip,
                onSelectScope: viewModel.setScope,
                onMoveBackward: viewModel.moveBackward,
                onMoveForward: viewModel.moveForward,
                onSelectDate: viewModel.selectDate
            )
        }
    }

    private func summaryGrid(widthTier: AppResponsiveWidthTier) -> some View {
        LazyVGrid(
            columns: [
                GridItem(.adaptive(minimum: widthTier == .compact ? 140 : 160), spacing: 16)
            ],
            spacing: 16
        ) {
            analyticsCard(
                title: "专注时长",
                value: formatDuration(viewModel.summary.focusTimeSeconds),
                detail: "所选范围内的专注时长"
            )
            analyticsCard(
                title: "已完成专注",
                value: "\(viewModel.summary.completedSessionsCount)",
                detail: "所选范围内完成的专注块"
            )
            analyticsCard(
                title: "平均专注时长",
                value: formatDuration(viewModel.summary.averageCompletedSessionSeconds),
                detail: "平均已完成专注块"
            )
            analyticsCard(
                title: "已记录笔记",
                value: "\(viewModel.summary.notesCapturedCount)",
                detail: "记录了笔记的已完成专注"
            )
        }
    }

    private var trendCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(viewModel.trendTitle)
                .font(.headline)
                .foregroundStyle(AppSurfaceTheme.primaryText)

            AnalyticsTrendPieChartView(
                buckets: viewModel.trendBuckets,
                selectedRangeTitle: viewModel.referenceTitle,
                emptyText: "所选范围内还没有完成的专注块。"
            )
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppCardSurface(style: .standard, cornerRadius: 28))
    }

    private var focusBreakdownCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(viewModel.topTasksTitle)
                .font(.headline)
                .foregroundStyle(AppSurfaceTheme.primaryText)

            TaskBreakdownPieChartView(
                rows: viewModel.focusRows,
                emptyText: "所选范围内还没有完成的任务，因此暂时没有可排名的内容。"
            )
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppCardSurface(style: .standard, cornerRadius: 28))
    }

    private var recentSessionsCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(viewModel.recentSessionsTitle)
                .font(.headline)
                .foregroundStyle(AppSurfaceTheme.primaryText)

            if viewModel.recentSessions.isEmpty {
                Text("在所选范围内完成几次专注后，它们就会显示在这里。")
                    .foregroundStyle(AppSurfaceTheme.secondaryText)
            } else {
                ForEach(viewModel.recentSessions) { session in
                    HStack(alignment: .top, spacing: 14) {
                        Circle()
                            .fill(Color(red: 0.16, green: 0.66, blue: 0.58))
                            .frame(width: 10, height: 10)
                            .padding(.top, 6)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(session.intention)
                                .font(.headline)
                                .foregroundStyle(AppSurfaceTheme.primaryText)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text(formatDuration(session.durationSeconds))
                                .font(.headline)
                                .foregroundStyle(AppSurfaceTheme.primaryText)
                            Text(session.endedAt, format: .dateTime.month(.abbreviated).day().hour().minute())
                                .font(.caption)
                                .foregroundStyle(AppSurfaceTheme.secondaryText)
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppCardSurface(style: .standard, cornerRadius: 28))
    }

    private func moodSummaryCard(widthTier: AppResponsiveWidthTier) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(AppText.tr("Session Mood"))
                .font(.headline)
                .foregroundStyle(AppSurfaceTheme.primaryText)

            LazyVGrid(
                columns: [
                    GridItem(.adaptive(minimum: widthTier == .compact ? 140 : 180), spacing: 14)
                ],
                spacing: 14
            ) {
                ForEach(viewModel.moodRows) { row in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(row.emoji)
                            .font(.system(size: 28))

                        Text(row.title)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppSurfaceTheme.primaryText)

                        Text("\(row.sessionCount)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(AppSurfaceTheme.primaryText)

                        Text(row.share.formatted(.percent.precision(.fractionLength(0))))
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(AppSurfaceTheme.secondaryText)
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppCardSurface(style: .soft, cornerRadius: 24))
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppCardSurface(style: .standard, cornerRadius: 28))
    }

    private func analyticsCard(title: String, value: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundStyle(AppSurfaceTheme.secondaryText)

            Text(value)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(AppSurfaceTheme.primaryText)

            Text(detail)
                .font(.subheadline)
                .foregroundStyle(AppSurfaceTheme.secondaryText)
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppCardSurface(style: .soft, cornerRadius: 24))
    }

    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        if minutes >= 60 {
            return "\(minutes / 60)h \(minutes % 60)m"
        }
        return "\(minutes)m"
    }
}
