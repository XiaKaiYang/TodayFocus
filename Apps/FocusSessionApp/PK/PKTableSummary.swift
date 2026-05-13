import Foundation

enum PKTableSource: String, Equatable, Sendable {
    case live
    case local
}

enum PKTableStatus: String, Equatable, Sendable {
    case open
    case running
    case full
}

struct PKTableSummary: Identifiable, Equatable, Sendable {
    let id: String
    let roomID: String
    let title: String
    let plannedMinutes: Int
    let inviteCode: String
    let memberCount: Int
    let capacity: Int
    let status: PKTableStatus
    let source: PKTableSource
    let isCurrentUsersTable: Bool

    init(
        roomID: String,
        title: String,
        plannedMinutes: Int,
        inviteCode: String,
        memberCount: Int,
        capacity: Int = 4,
        status: PKTableStatus,
        source: PKTableSource,
        isCurrentUsersTable: Bool
    ) {
        self.id = roomID
        self.roomID = roomID
        self.title = title
        self.plannedMinutes = plannedMinutes
        self.inviteCode = inviteCode
        self.memberCount = memberCount
        self.capacity = capacity
        self.status = status
        self.source = source
        self.isCurrentUsersTable = isCurrentUsersTable
    }
}
