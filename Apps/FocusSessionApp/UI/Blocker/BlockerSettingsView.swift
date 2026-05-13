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
            Text("屏蔽器")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(AppSurfaceTheme.primaryText)

            Text("本地屏蔽规则已经生效。你可以在这里调整专注时的软件与网站屏蔽方案。")
                .font(.title3)
                .foregroundStyle(AppSurfaceTheme.secondaryText)

            Toggle(isOn: $viewModel.isBlockingEnabled) {
                Text("启用本地应用屏蔽")
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
                title: "应用规则",
                value: "\(viewModel.appRules.count)",
                detail: "当前面向软件的规则数量"
            )
            blockerMetricCard(
                title: "网站规则",
                value: "\(viewModel.domainRules.count)",
                detail: "当前面向网站的规则数量"
            )
            blockerMetricCard(
                title: "屏蔽状态",
                value: viewModel.isBlockingEnabled ? "已开启" : "已关闭",
                detail: "专注中会按规则自动生效"
            )
            blockerMetricCard(
                title: "最近命中",
                value: viewModel.lastBlockedAppName ?? "暂无",
                detail: "最近一次被拦截的软件"
            )
        }
    }

    private var ruleComposer: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("快速添加规则")
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
                    "屏蔽"
                case .allow:
                    "放行"
                }
            }

            AppPromptedTextField(
                viewModel.newTargetKind == .app ? "Safari" : "youtube.com",
                text: $viewModel.newRuleValue
            )

            Toggle(isOn: $viewModel.activeDuringFocus) {
                Text("专注时生效")
                    .foregroundStyle(AppSurfaceTheme.primaryText)
            }

            Toggle(isOn: $viewModel.activeDuringBreak) {
                Text("休息时生效")
                    .foregroundStyle(AppSurfaceTheme.primaryText)
            }

            Button("保存规则") {
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
            Text("规则概览")
                .font(.headline)
                .foregroundStyle(AppSurfaceTheme.primaryText)

            if viewModel.rules.isEmpty {
                Text("还没有任何规则，先添加第一个想要控制的软件或网站。")
                    .foregroundStyle(AppSurfaceTheme.secondaryText)
            } else {
                ruleSection(title: "软件", rules: viewModel.appRules)
                Divider()
                ruleSection(title: "网站", rules: viewModel.domainRules)
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
                Text("暂无")
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

                        Button("删除") {
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
            Text("屏蔽统计")
                .font(.headline)
                .foregroundStyle(AppSurfaceTheme.primaryText)

            blockerCountRow(title: "软件已屏蔽", value: viewModel.blockedAppCount)
            blockerCountRow(title: "网站已屏蔽", value: viewModel.blockedWebsiteCount)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppCardSurface(style: .standard, cornerRadius: 28))
    }

    private func blockerCountRow(title: String, value: Int) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(AppSurfaceTheme.secondaryText)

            Spacer()

            Text("\(value) 次")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(AppSurfaceTheme.primaryText)
        }
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
        let modeText = rule.mode == .deny ? "屏蔽名单" : "放行名单"
        let focusText = rule.activeDuringFocus ? "专注" : ""
        let breakText = rule.activeDuringBreak ? "休息" : ""
        let activeText = [focusText, breakText].filter { !$0.isEmpty }.joined(separator: " + ")
        return activeText.isEmpty ? modeText : "\(modeText) · \(activeText)"
    }
}
