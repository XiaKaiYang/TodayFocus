import Foundation

enum RoomStatus: String, Codable, Sendable {
    case lobby, running, ended, cancelled
}

enum MemberRole: String, Codable, Sendable {
    case owner, member
}

enum MemberJoinState: String, Codable, Sendable {
    case joined, left, kicked
}

enum MemberReadyState: String, Codable, Sendable {
    case notReady, ready
}

enum SeatState: String, Codable, Sendable {
    case present, away, unknown
}

enum ActivityState: String, Codable, Sendable {
    case active, inactive, unknown
}

enum PKSessionStatus: String, Codable, Sendable {
    case running, ended, cancelled
}
