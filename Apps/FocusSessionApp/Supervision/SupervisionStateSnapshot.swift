import Foundation

struct SupervisionStateSnapshot: Equatable, Sendable {
    let sessionID: String
    let roomID: String
    let userID: String
    var seatState: SeatState
    var activityState: ActivityState
    var lastSeatChangeAt: Date
    var lastActiveAt: Date
    var lastUploadedAt: Date?
    let clientModelVersion: Int

    init(sessionID: String, roomID: String, userID: String, now: Date = Date()) {
        self.sessionID = sessionID
        self.roomID = roomID
        self.userID = userID
        seatState = .unknown
        activityState = .unknown
        lastSeatChangeAt = now
        lastActiveAt = now
        clientModelVersion = 1
    }
}
