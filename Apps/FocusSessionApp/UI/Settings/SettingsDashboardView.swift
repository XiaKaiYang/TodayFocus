import SwiftUI

struct SettingsDashboardView: View {
    @StateObject private var viewModel: SettingsViewModel

    init(viewModel: SettingsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            AppCanvasBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    FocusDefaultsSection(viewModel: viewModel)
                    if AppPlatform.current == .macOS {
                        BlockerAutomationSection(viewModel: viewModel)
                    }
                    StartupSection(viewModel: viewModel)
                    LocalDataSection(viewModel: viewModel)
                }
                .padding(28)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Settings")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(AppSurfaceTheme.primaryText)

            Text(
                AppPlatform.current == .macOS
                    ? "Tune the default focus flow, blocker automation, startup destination, and local data lifecycle."
                    : "Tune the default focus flow, synced data behavior, and startup destination on this device."
            )
                .font(.title3)
                .foregroundStyle(AppSurfaceTheme.secondaryText)

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.callout)
                    .foregroundStyle(Color(red: 1.0, green: 0.50, blue: 0.52))
            }
        }
    }
}

private struct FocusDefaultsSection: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        SettingsSectionCard(
            title: "Focus Defaults",
            subtitle: "Change the base duration that the dial and new sessions start from."
        ) {
            VStack(alignment: .leading, spacing: 18) {
                SettingsMetricTile(
                    title: "Default Focus",
                    value: "\(viewModel.preferences.defaultFocusDurationMinutes) min"
                )

                AppInlineStepper(
                    title: "Adjust in 5-minute steps",
                    valueText: "\(viewModel.preferences.defaultFocusDurationMinutes) min",
                    decrementDisabled: viewModel.preferences.defaultFocusDurationMinutes <= 5,
                    incrementDisabled: viewModel.preferences.defaultFocusDurationMinutes >= 60,
                    onDecrement: {
                        viewModel.updateDefaultFocusDurationMinutes(
                            max(5, viewModel.preferences.defaultFocusDurationMinutes - 5)
                        )
                    },
                    onIncrement: {
                        viewModel.updateDefaultFocusDurationMinutes(
                            min(60, viewModel.preferences.defaultFocusDurationMinutes + 5)
                        )
                    }
                )
            }
        }
    }
}

private struct BlockerAutomationSection: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        SettingsSectionCard(
            title: "Blocker Automation",
            subtitle: "Let the blocker follow the focus lifecycle without overriding manual control."
        ) {
            Toggle(
                "Automatically enable blocker while a focus session is active",
                isOn: Binding(
                    get: { viewModel.preferences.autoEnableBlockerDuringFocus },
                    set: { isEnabled in
                        viewModel.setAutoEnableBlockerDuringFocus(isEnabled)
                    }
                )
            )
            .toggleStyle(.switch)
            .foregroundStyle(AppSurfaceTheme.primaryText)
        }
    }
}

private struct StartupSection: View {
    @ObservedObject var viewModel: SettingsViewModel

    private var launchDestinationOptions: [AppDropdownOption<AppSection>] {
        AppSection.launchDestinationSections(on: AppPlatform.current).map { section in
            AppDropdownOption(value: section, title: section.title)
        }
    }

    private var planGoalLaunchExpansionOptions: [AppDropdownOption<PlanGoalLaunchExpansion>] {
        [
            AppDropdownOption(value: .collapsed, title: "Default Collapsed"),
            AppDropdownOption(value: .expanded, title: "Default Expanded")
        ]
    }

    var body: some View {
        SettingsSectionCard(
            title: "Startup",
            subtitle: "Pick the section the app should land on when there is no explicit launch override."
        ) {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Launch Destination")
                        .font(.headline)
                        .foregroundStyle(AppSurfaceTheme.primaryText)

                    AppDropdownField(
                        selection: viewModel.preferences.launchSection,
                        selectedTitle: viewModel.preferences.launchSection.title,
                        options: launchDestinationOptions,
                        height: 44,
                        cornerRadius: 18,
                        fillColor: AppSurfaceTheme.taskSelectorWarmBorder.opacity(0.035),
                        strokeColor: AppSurfaceTheme.taskSelectorWarmBorder.opacity(0.40),
                        textColor: AppSurfaceTheme.primaryText,
                        glyphColor: AppSurfaceTheme.taskSelectorWarmGlyph,
                        subtitleColor: AppSurfaceTheme.secondaryText,
                        popoverTint: Color(red: 0.76, green: 0.68, blue: 0.61)
                    ) { section in
                        viewModel.updateLaunchSection(section)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Plan Goal Subtasks")
                        .font(.headline)
                        .foregroundStyle(AppSurfaceTheme.primaryText)

                    AppDropdownField(
                        selection: viewModel.preferences.planGoalLaunchExpansion,
                        selectedTitle: viewModel.preferences.planGoalLaunchExpansion.title,
                        options: planGoalLaunchExpansionOptions,
                        height: 44,
                        cornerRadius: 18,
                        fillColor: AppSurfaceTheme.taskSelectorWarmBorder.opacity(0.035),
                        strokeColor: AppSurfaceTheme.taskSelectorWarmBorder.opacity(0.40),
                        textColor: AppSurfaceTheme.primaryText,
                        glyphColor: AppSurfaceTheme.taskSelectorWarmGlyph,
                        subtitleColor: AppSurfaceTheme.secondaryText,
                        popoverTint: Color(red: 0.76, green: 0.68, blue: 0.61)
                    ) { expansion in
                        viewModel.updatePlanGoalLaunchExpansion(expansion)
                    }
                }

                SettingsMetricTile(
                    title: "Recent Sessions",
                    value: "\(viewModel.preferences.recentSessionsLimit) shown"
                )

                AppInlineStepper(
                    title: "History rows on Current Session",
                    valueText: "\(viewModel.preferences.recentSessionsLimit) shown",
                    decrementDisabled: viewModel.preferences.recentSessionsLimit <= 3,
                    incrementDisabled: viewModel.preferences.recentSessionsLimit >= 20,
                    onDecrement: {
                        viewModel.updateRecentSessionsLimit(
                            max(3, viewModel.preferences.recentSessionsLimit - 1)
                        )
                    },
                    onIncrement: {
                        viewModel.updateRecentSessionsLimit(
                            min(20, viewModel.preferences.recentSessionsLimit + 1)
                        )
                    }
                )
            }
        }
    }
}

private struct LocalDataSection: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        SettingsSectionCard(
            title: AppPlatform.current == .macOS ? "Local Data" : "Synced Data",
            subtitle: AppPlatform.current == .macOS
                ? "Clear specific slices without touching the rest, or wipe the full local workspace."
                : "Clear specific slices from the shared CloudKit-backed data set without changing your local display preferences."
        ) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 16) {
                    DataMetricTile(title: "Focus", value: "\(viewModel.dataSummary.focusSessionsCount)")
                    DataMetricTile(title: "Tasks", value: "\(viewModel.dataSummary.tasksCount)")
                    DataMetricTile(title: "Goals", value: "\(viewModel.dataSummary.goalsCount)")
                    if AppPlatform.current == .macOS {
                        DataMetricTile(title: "Rules", value: "\(viewModel.dataSummary.blockerRulesCount)")
                        DataMetricTile(title: "Blocked Hits", value: "\(viewModel.dataSummary.blockedEventsCount)")
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    SettingsActionButton(
                        title: AppPlatform.current == .macOS ? "Clear Focus History" : "Clear Synced Focus History",
                        tint: nil,
                        foregroundColor: AppSurfaceTheme.primaryText
                    ) {
                        viewModel.clearFocusHistory()
                    }
                    SettingsActionButton(
                        title: AppPlatform.current == .macOS ? "Clear Completed Tasks" : "Clear Synced Completed Tasks",
                        tint: nil,
                        foregroundColor: AppSurfaceTheme.primaryText
                    ) {
                        viewModel.clearCompletedTasks()
                    }
                    if AppPlatform.current == .macOS {
                        SettingsActionButton(
                            title: "Clear Blocker Activity",
                            tint: nil,
                            foregroundColor: AppSurfaceTheme.primaryText
                        ) {
                            viewModel.clearBlockerActivity()
                        }
                    }
                    SettingsActionButton(
                        title: AppPlatform.current == .macOS ? "Reset All Local Data" : "Reset All Synced Data",
                        tint: Color(red: 0.80, green: 0.25, blue: 0.26),
                        foregroundColor: .white
                    ) {
                        viewModel.resetAllLocalData()
                    }
                }
            }
        }
    }
}

private struct SettingsSectionCard<Content: View>: View {
    let title: String
    let subtitle: String
    let content: Content

    init(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(AppSurfaceTheme.primaryText)

                Text(subtitle)
                    .font(.body)
                    .foregroundStyle(AppSurfaceTheme.secondaryText)
            }

            content
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppCardSurface(style: .standard, cornerRadius: 28))
    }
}

private struct SettingsMetricTile: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppSurfaceTheme.secondaryText)

            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(AppSurfaceTheme.primaryText)
        }
        .padding(18)
        .background(AppCardSurface(style: .elevated, cornerRadius: 20))
    }
}

private struct DataMetricTile: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppSurfaceTheme.secondaryText)

            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(AppSurfaceTheme.primaryText)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppCardSurface(style: .elevated, cornerRadius: 20))
    }
}

private struct SettingsActionButton: View {
    let title: String
    let tint: Color?
    let foregroundColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(
            AppGlassButtonStyle(
                tint: tint,
                foregroundColor: foregroundColor
            )
        )
    }
}
