import Foundation

public enum DistractionEventKind: Codable, Equatable, Sendable {
    case blockedApp(name: String)
    case blockedWebsite(host: String)
}

public struct DistractionEvent: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var kind: DistractionEventKind
    public var occurredAt: Date

    public init(
        id: UUID = UUID(),
        kind: DistractionEventKind,
        occurredAt: Date = .now
    ) {
        self.id = id
        self.kind = kind
        self.occurredAt = occurredAt
    }
}
