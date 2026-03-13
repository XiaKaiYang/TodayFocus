import Foundation
import FocusSessionCore

struct AppBlockProvider {
    let rules: [BlockingRule]

    func decision(
        forFrontmostAppName appName: String,
        isOnBreak: Bool
    ) -> BlockDecision {
        let activeRules = appRules(activeOnBreak: isOnBreak)
        let normalizedAppName = normalized(appName)

        let allowList = activeRules
            .filter { $0.mode == .allow }
            .compactMap(appName(from:))
            .map(normalized)
        if !allowList.isEmpty {
            return allowList.contains(normalizedAppName)
                ? .allow
                : .block(reason: .allowList)
        }

        let denyList = activeRules
            .filter { $0.mode == .deny }
            .compactMap(appName(from:))
            .map(normalized)
        return denyList.contains(normalizedAppName)
            ? .block(reason: .denyList)
            : .allow
    }

    private func appRules(activeOnBreak isOnBreak: Bool) -> [BlockingRule] {
        rules.filter { rule in
            switch rule.target {
            case .app:
                return isOnBreak ? rule.activeDuringBreak : rule.activeDuringFocus
            case .domain:
                return false
            }
        }
    }

    private func appName(from rule: BlockingRule) -> String? {
        guard case let .app(name) = rule.target else {
            return nil
        }
        return name
    }

    private func normalized(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
