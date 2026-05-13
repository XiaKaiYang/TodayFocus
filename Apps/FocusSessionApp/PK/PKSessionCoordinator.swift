import Foundation

@MainActor
protocol PKSessionCoordinatorProtocol: AnyObject {
    func sessionDidStart(roomID: String, sessionID: String, plannedMinutes: Int) async
    func sessionDidPause()
    func sessionDidResume()
    func sessionDidFinish(verifiedMinutes: Int)
    func sessionDidAbandon()
}

@MainActor
final class PKSessionCoordinator: ObservableObject, PKSessionCoordinatorProtocol {
    @Published private(set) var currentPKSessionID: String?
    @Published private(set) var pkSessionStatus: PKSessionStatus = .running

    private let pkSessionRepository: any PKSessionRepositoryProtocol
    private let roomRepository: any RoomRepositoryProtocol

    private var currentRoomID: String?

    init(
        pkSessionRepository: any PKSessionRepositoryProtocol = PKSessionRepository(),
        roomRepository: any RoomRepositoryProtocol = RoomRepository()
    ) {
        self.pkSessionRepository = pkSessionRepository
        self.roomRepository = roomRepository
    }

    func sessionDidStart(roomID: String, sessionID: String, plannedMinutes: Int) async {
        currentPKSessionID = sessionID
        currentRoomID = roomID
        pkSessionStatus = .running

        do {
            let session = PKSessionRecord(
                sessionID: sessionID,
                roomID: roomID,
                plannedMinutes: plannedMinutes
            )
            try await pkSessionRepository.createSession(session)
        } catch {
            // Session already created by lobby; update current tracking
        }
    }

    func sessionDidPause() {}

    func sessionDidResume() {}

    func sessionDidFinish(verifiedMinutes: Int) {
        guard let sessionID = currentPKSessionID else { return }
        pkSessionStatus = .ended
        Task {
            do {
                if var session = try await pkSessionRepository.fetchCurrentSession(roomID: currentRoomID ?? "") {
                    session.status = .ended
                    session.endAt = Date()
                    try await pkSessionRepository.updateSession(session)
                } else {
                    var session = PKSessionRecord(sessionID: sessionID, roomID: currentRoomID ?? "", plannedMinutes: verifiedMinutes)
                    session.status = .ended
                    session.endAt = Date()
                    try await pkSessionRepository.updateSession(session)
                }
            } catch {}
        }
    }

    func sessionDidAbandon() {
        guard let sessionID = currentPKSessionID else { return }
        pkSessionStatus = .cancelled
        Task {
            do {
                if var session = try await pkSessionRepository.fetchCurrentSession(roomID: currentRoomID ?? "") {
                    session.status = .cancelled
                    session.endAt = Date()
                    try await pkSessionRepository.updateSession(session)
                } else {
                    var session = PKSessionRecord(sessionID: sessionID, roomID: currentRoomID ?? "", plannedMinutes: 0)
                    session.status = .cancelled
                    session.endAt = Date()
                    try await pkSessionRepository.updateSession(session)
                }
            } catch {}
        }
    }
}

@MainActor
final class StubPKSessionCoordinator: PKSessionCoordinatorProtocol {
    var didStartCalled = false
    var didFinishCalled = false
    var didAbandonCalled = false
    var lastVerifiedMinutes: Int?

    func sessionDidStart(roomID: String, sessionID: String, plannedMinutes: Int) async {
        didStartCalled = true
    }

    func sessionDidPause() {}

    func sessionDidResume() {}

    func sessionDidFinish(verifiedMinutes: Int) {
        didFinishCalled = true
        lastVerifiedMinutes = verifiedMinutes
    }

    func sessionDidAbandon() {
        didAbandonCalled = true
    }
}
