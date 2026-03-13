import Foundation

public enum BlockReason: String, Codable, Equatable, Sendable {
    case denyList
    case allowList
}

public enum BlockDecision: Codable, Equatable, Sendable {
    case allow
    case block(reason: BlockReason)
}
