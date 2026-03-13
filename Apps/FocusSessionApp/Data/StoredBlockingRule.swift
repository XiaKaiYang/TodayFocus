import Foundation
import SwiftData
import FocusSessionCore

@Model
final class StoredBlockingRule {
    @Attribute(.unique) var id: UUID
    var modeRawValue: String
    var targetType: String
    var targetValue: String
    var activeDuringFocus: Bool
    var activeDuringBreak: Bool

    init(rule: BlockingRule) {
        self.id = rule.id
        self.modeRawValue = rule.mode.rawValue
        self.activeDuringFocus = rule.activeDuringFocus
        self.activeDuringBreak = rule.activeDuringBreak

        switch rule.target {
        case let .app(name):
            self.targetType = "app"
            self.targetValue = name
        case let .domain(host):
            self.targetType = "domain"
            self.targetValue = host
        }
    }

    var domainModel: BlockingRule {
        BlockingRule(
            id: id,
            mode: BlockingRuleMode(rawValue: modeRawValue) ?? .deny,
            target: target,
            activeDuringFocus: activeDuringFocus,
            activeDuringBreak: activeDuringBreak
        )
    }

    private var target: BlockingRuleTarget {
        switch targetType {
        case "domain":
            .domain(host: targetValue)
        default:
            .app(name: targetValue)
        }
    }
}
