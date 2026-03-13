import Foundation

public struct BlockerProfileSnapshot: Codable, Equatable, Sendable {
    public var rules: [BlockingRule]
    public var isOnBreak: Bool

    public init(rules: [BlockingRule], isOnBreak: Bool = false) {
        self.rules = rules
        self.isOnBreak = isOnBreak
    }
}
