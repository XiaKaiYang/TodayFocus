import Foundation

public enum BlockingRuleMode: String, Codable, Equatable, Hashable, Sendable {
    case allow
    case deny
}

public enum BlockingRuleTarget: Codable, Equatable, Sendable {
    case app(name: String)
    case domain(host: String)
}

public struct BlockingRule: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var mode: BlockingRuleMode
    public var target: BlockingRuleTarget
    public var activeDuringFocus: Bool
    public var activeDuringBreak: Bool

    public init(
        id: UUID = UUID(),
        mode: BlockingRuleMode,
        target: BlockingRuleTarget,
        activeDuringFocus: Bool = true,
        activeDuringBreak: Bool = false
    ) {
        self.id = id
        self.mode = mode
        self.target = target
        self.activeDuringFocus = activeDuringFocus
        self.activeDuringBreak = activeDuringBreak
    }
}
