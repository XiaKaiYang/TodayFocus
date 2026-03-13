import SwiftUI
import FocusSessionCore

struct BlockerSettingsView: View {
    @StateObject private var viewModel: BlockerViewModel

    init(viewModel: BlockerViewModel = BlockerViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            AppCanvasBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    summaryCards
                    HStack(alignment: .top, spacing: 24) {
                        ruleComposer
                        rulesOverview
                    }
                    eventsCard
                }
                .padding(32)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Blocker")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(AppSurfaceTheme.primaryText)

            Text("Local app rules are live. Keep this page open while you tune the first focus-safe rule set.")
                .font(.title3)
                .foregroundStyle(AppSurfaceTheme.secondaryText)

            Toggle(isOn: $viewModel.isBlockingEnabled) {
                Text("Enable local app blocking")
                    .font(.headline)
                    .foregroundStyle(AppSurfaceTheme.primaryText)
            }
            .toggleStyle(.switch)

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.callout)
                    .foregroundStyle(.red)
            }
        }
    }

    private var summaryCards: some View {
        HStack(spacing: 16) {
            blockerMetricCard(
                title: "App Rules",
                value: "\(viewModel.appRules.count)",
                detail: "Rules targeting native apps"
            )
            blockerMetricCard(
                title: "Website Rules",
                value: "\(viewModel.domainRules.count)",
                detail: "Ready for Safari export"
            )
            blockerMetricCard(
                title: "Blocked Hits",
                value: "\(viewModel.recentEvents.count)",
                detail: "Recent distraction attempts"
            )
            blockerMetricCard(
                title: "Last Hit",
                value: viewModel.lastBlockedAppName ?? "None",
                detail: "Most recent blocked app"
            )
        }
    }

    private var ruleComposer: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Add Rule")
                .font(.headline)
                .foregroundStyle(AppSurfaceTheme.primaryText)

            AppSegmentedControl(
                options: BlockerTargetKind.allCases,
                selection: $viewModel.newTargetKind,
                tint: Color(red: 0.39, green: 0.56, blue: 0.82)
            ) { kind in
                kind.title
            }

            AppSegmentedControl(
                options: [.deny, .allow],
                selection: $viewModel.newRuleMode,
                tint: Color(red: 0.86, green: 0.47, blue: 0.47)
            ) { mode in
                switch mode {
                case .deny:
                    "Deny"
                case .allow:
                    "Allow"
                }
            }

            AppPromptedTextField(
                viewModel.newTargetKind == .app ? "Safari" : "youtube.com",
                text: $viewModel.newRuleValue
            )

            Toggle(isOn: $viewModel.activeDuringFocus) {
                Text("Active during focus")
                    .foregroundStyle(AppSurfaceTheme.primaryText)
            }

            Toggle(isOn: $viewModel.activeDuringBreak) {
                Text("Active during break")
                    .foregroundStyle(AppSurfaceTheme.primaryText)
            }

            Button("Save Rule") {
                viewModel.createRule()
            }
            .buttonStyle(AppAccentButtonStyle())
        }
        .padding(24)
        .frame(maxWidth: 320, alignment: .leading)
        .background(AppCardSurface(style: .standard, cornerRadius: 28))
    }

    private var rulesOverview: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Rules")
                .font(.headline)
                .foregroundStyle(AppSurfaceTheme.primaryText)

            if viewModel.rules.isEmpty {
                Text("No blocker rules yet. Add the first app or website you want to control.")
                    .foregroundStyle(AppSurfaceTheme.secondaryText)
            } else {
                ruleSection(title: "Apps", rules: viewModel.appRules)
                Divider()
                ruleSection(title: "Websites", rules: viewModel.domainRules)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppCardSurface(style: .standard, cornerRadius: 28))
    }

    private func ruleSection(title: String, rules: [BlockingRule]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppSurfaceTheme.secondaryText)

            if rules.isEmpty {
                Text("None")
                    .foregroundStyle(AppSurfaceTheme.secondaryText)
            } else {
                ForEach(rules) { rule in
                    HStack(alignment: .top, spacing: 12) {
                        Circle()
                            .fill(rule.mode == .deny ? Color.red : Color.green)
                            .frame(width: 10, height: 10)
                            .padding(.top, 6)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(ruleTitle(rule))
                                .font(.headline)
                                .foregroundStyle(AppSurfaceTheme.primaryText)
                            Text(ruleSubtitle(rule))
                                .font(.caption)
                                .foregroundStyle(AppSurfaceTheme.secondaryText)
                        }

                        Spacer()

                        Button("Delete") {
                            viewModel.deleteRule(rule)
                        }
                        .buttonStyle(
                            AppGlassButtonStyle(
                                tint: Color(red: 0.90, green: 0.40, blue: 0.42),
                                foregroundColor: Color(red: 0.63, green: 0.18, blue: 0.20)
                            )
                        )
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private var eventsCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Recent Blocked Attempts")
                .font(.headline)
                .foregroundStyle(AppSurfaceTheme.primaryText)

            if viewModel.recentEvents.isEmpty {
                Text("Switch to a blocked app while blocker is enabled and the event log will appear here.")
                    .foregroundStyle(AppSurfaceTheme.secondaryText)
            } else {
                ForEach(viewModel.recentEvents) { event in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(eventTitle(event))
                                .font(.headline)
                                .foregroundStyle(AppSurfaceTheme.primaryText)
                            Text(event.occurredAt, format: .dateTime.month(.abbreviated).day().hour().minute())
                                .font(.caption)
                                .foregroundStyle(AppSurfaceTheme.secondaryText)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppCardSurface(style: .standard, cornerRadius: 28))
    }

    private func blockerMetricCard(title: String, value: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(AppSurfaceTheme.secondaryText)
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(AppSurfaceTheme.primaryText)
            Text(detail)
                .font(.caption)
                .foregroundStyle(AppSurfaceTheme.secondaryText)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppCardSurface(style: .soft, cornerRadius: 24))
    }

    private func ruleTitle(_ rule: BlockingRule) -> String {
        switch rule.target {
        case let .app(name):
            name
        case let .domain(host):
            host
        }
    }

    private func ruleSubtitle(_ rule: BlockingRule) -> String {
        let modeText = rule.mode == .deny ? "Deny list" : "Allow list"
        let focusText = rule.activeDuringFocus ? "Focus" : ""
        let breakText = rule.activeDuringBreak ? "Break" : ""
        let activeText = [focusText, breakText].filter { !$0.isEmpty }.joined(separator: " + ")
        return activeText.isEmpty ? modeText : "\(modeText) · \(activeText)"
    }

    private func eventTitle(_ event: DistractionEvent) -> String {
        switch event.kind {
        case let .blockedApp(name):
            "Blocked app: \(name)"
        case let .blockedWebsite(host):
            "Blocked website: \(host)"
        }
    }
}
