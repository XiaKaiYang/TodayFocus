import Foundation

@MainActor
final class RoomLobbyViewModel: ObservableObject {
    @Published private(set) var currentRoom: RoomRecord?
    @Published private(set) var members: [RoomMemberRecord] = []
    @Published private(set) var currentMembership: RoomMemberRecord?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published var inviteCodeInput = ""

    private let roomRepository: any RoomRepositoryProtocol
    private let pkSessionRepository: any PKSessionRepositoryProtocol
    private let accountViewModel: AccountViewModel
    private let currentSessionViewModel: CurrentSessionViewModel?
    private let pkSessionCoordinator: (any PKSessionCoordinatorProtocol)?
    private(set) var supervisionCoordinator: (any SupervisionCoordinatorProtocol)?

    var canStartSession: Bool {
        guard let room = currentRoom, currentMembership?.role == .owner else { return false }
        return room.status == .lobby && members.allSatisfy { $0.readyState == .ready || $0.role == .owner }
    }

    var inviteCode: String? { currentRoom?.inviteCode }
    var isSignedIn: Bool { accountViewModel.isSignedIn }
    var accountDisplayName: String? { accountViewModel.displayName }

    init(
        roomRepository: any RoomRepositoryProtocol,
        pkSessionRepository: any PKSessionRepositoryProtocol,
        accountViewModel: AccountViewModel,
        currentSessionViewModel: CurrentSessionViewModel? = nil,
        pkSessionCoordinator: (any PKSessionCoordinatorProtocol)? = nil,
        supervisionCoordinator: (any SupervisionCoordinatorProtocol)? = nil
    ) {
        self.roomRepository = roomRepository
        self.pkSessionRepository = pkSessionRepository
        self.accountViewModel = accountViewModel
        self.currentSessionViewModel = currentSessionViewModel
        self.pkSessionCoordinator = pkSessionCoordinator
        self.supervisionCoordinator = supervisionCoordinator
    }

    func createRoom(title: String, plannedMinutes: Int) async {
        guard let userID = currentUserID() else {
            errorMessage = "Sign in to create a room."
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let room = RoomRecord(
                ownerUserID: userID,
                title: title,
                plannedMinutes: plannedMinutes
            )
            try await roomRepository.createRoom(room)
            let membership = RoomMemberRecord(
                roomID: room.roomID,
                userID: userID,
                role: .owner,
                readyState: .ready
            )
            try await roomRepository.upsertMember(membership)
            currentRoom = room
            currentMembership = membership
            members = [membership]
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func joinRoom(inviteCode: String) async {
        guard let userID = currentUserID() else {
            errorMessage = "Sign in to join a room."
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            guard let room = try await roomRepository.fetchRoom(byInviteCode: inviteCode) else {
                errorMessage = "Room not found for code: \(inviteCode)"
                return
            }
            let membership = RoomMemberRecord(
                roomID: room.roomID,
                userID: userID,
                role: .member
            )
            try await roomRepository.upsertMember(membership)
            let allMembers = try await roomRepository.fetchMembers(roomID: room.roomID)
            currentRoom = room
            currentMembership = membership
            members = allMembers
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func setReady(_ ready: Bool) async {
        guard var membership = currentMembership else { return }
        membership.readyState = ready ? .ready : .notReady
        do {
            try await roomRepository.upsertMember(membership)
            currentMembership = membership
            if let idx = members.firstIndex(where: { $0.userID == membership.userID }) {
                members[idx] = membership
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func startSession() async {
        guard let room = currentRoom else { return }
        guard canStartSession else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let sessionID = UUID().uuidString
            let session = PKSessionRecord(
                sessionID: sessionID,
                roomID: room.roomID,
                plannedMinutes: room.plannedMinutes
            )
            try await pkSessionRepository.createSession(session)

            var updatedRoom = room
            updatedRoom.status = .running
            updatedRoom.startedAt = Date()
            updatedRoom.currentSessionID = sessionID
            try await roomRepository.updateRoom(updatedRoom)
            currentRoom = updatedRoom

            if let pkSessionCoordinator {
                currentSessionViewModel?.bindPKSession(
                    roomID: updatedRoom.roomID,
                    sessionID: sessionID,
                    coordinator: pkSessionCoordinator
                )
                currentSessionViewModel?.startPKLinkedSession(
                    title: updatedRoom.title,
                    plannedMinutes: updatedRoom.plannedMinutes
                )
            }

            if let supervisionCoordinator, let userID = currentUserID() {
                await supervisionCoordinator.checkPermissions()
                if case .eligible = supervisionCoordinator.eligibility {
                    supervisionCoordinator.startSupervision(
                        sessionID: sessionID,
                        roomID: updatedRoom.roomID,
                        userID: userID
                    )
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func leaveRoom() async {
        guard var membership = currentMembership else { return }
        membership.joinState = .left
        do {
            try await roomRepository.upsertMember(membership)
        } catch {
            errorMessage = error.localizedDescription
        }
        currentSessionViewModel?.unbindPKSession()
        supervisionCoordinator?.stopSupervision()
        currentRoom = nil
        currentMembership = nil
        members = []
    }

    func refreshMembers() async {
        guard let room = currentRoom else { return }
        do {
            members = try await roomRepository.fetchMembers(roomID: room.roomID)
            if let userID = currentUserID() {
                currentMembership = members.first { $0.userID == userID }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signIn() {
        accountViewModel.signIn()
    }

    private func currentUserID() -> String? {
        accountViewModel.currentUserID ?? accountViewModel.currentProfile?.userID
    }
}
