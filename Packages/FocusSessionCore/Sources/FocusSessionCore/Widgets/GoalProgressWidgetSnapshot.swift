import Foundation

public enum GoalProgressWidgetTintToken: String, CaseIterable, Codable, Equatable {
    case lilac
    case sky
    case peach
    case sage
    case mint
    case amber
}

public struct GoalProgressWidgetItem: Codable, Equatable, Identifiable {
    public let id: UUID
    public var title: String
    public var progressPercent: Int
    public var progressLabel: String
    public var tintToken: GoalProgressWidgetTintToken

    public init(
        id: UUID,
        title: String,
        progressPercent: Int,
        progressLabel: String,
        tintToken: GoalProgressWidgetTintToken
    ) {
        self.id = id
        self.title = title
        self.progressPercent = progressPercent
        self.progressLabel = progressLabel
        self.tintToken = tintToken
    }
}

public struct GoalProgressWidgetSnapshot: Codable, Equatable {
    public var items: [GoalProgressWidgetItem]
    public var updatedAt: Date

    public init(items: [GoalProgressWidgetItem], updatedAt: Date) {
        self.items = items
        self.updatedAt = updatedAt
    }
}
