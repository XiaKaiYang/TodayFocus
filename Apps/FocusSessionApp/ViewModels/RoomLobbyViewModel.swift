import Foundation

@MainActor
final class RoomLobbyViewModel: ObservableObject {
    @Published private(set) var currentRoom: RoomRecord?
    @Published private(set) var members: [RoomMemberRecord] = []
    @Published private(set) var tables: [PKTableSummary] = []
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
    private let tableSource: PKTableSource

    var canStartSession: Bool {
        guard let room = currentRoom, currentMembership?.role == .owner else { return false }
        return room.status == .lobby && members.allSatisfy { $0.readyState == .ready || $0.role == .owner }
    }

    var inviteCode: String? { currentRoom?.inviteCode }
    var isSignedIn: Bool { accountViewModel.isSignedIn }
    var accountDisplayName: String? { accountViewModel.displayName }
    var centerTimerText: String {
        if let currentSessionViewModel {
            return currentSessionViewModel.remainingTimeText(at: Date())
        }

        guard let currentRoom else {
            return "00:00"
        }

        return String(format: "%02d:00", currentRoom.plannedMinutes)
    }

    var centerStatusText: String {
        if let currentSessionViewModel {
            return currentSessionViewModel.phaseText.uppercased()
        }

        return AppText.tr("RUNNING")
    }

    init(
        roomRepository: any RoomRepositoryProtocol,
        pkSessionRepository: any PKSessionRepositoryProtocol,
        accountViewModel: AccountViewModel,
        currentSessionViewModel: CurrentSessionViewModel? = nil,
        pkSessionCoordinator: (any PKSessionCoordinatorProtocol)? = nil,
        supervisionCoordinator: (any SupervisionCoordinatorProtocol)? = nil,
        tableSource: PKTableSource? = nil
    ) {
        self.roomRepository = roomRepository
        self.pkSessionRepository = pkSessionRepository
        self.accountViewModel = accountViewModel
        self.currentSessionViewModel = currentSessionViewModel
        self.pkSessionCoordinator = pkSessionCoordinator
        self.supervisionCoordinator = supervisionCoordinator
        if let tableSource {
            self.tableSource = tableSource
        } else if roomRepository is LocalRoomRepository || roomRepository is StubRoomRepository {
            self.tableSource = .local
        } else {
            self.tableSource = .live
        }
    }

    func loadTableHall() async {
        guard currentRoom == nil else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await seedLocalTablesIfNeeded()
            let rooms = try await roomRepository.fetchRooms()
            let currentUserID = currentUserID()
            var summaries: [PKTableSummary] = []

            for room in rooms {
                let roomMembers = try await roomRepository.fetchMembers(roomID: room.roomID)
                summaries.append(
                    makeTableSummary(
                        room: room,
                        members: roomMembers,
                        currentUserID: currentUserID
                    )
                )
            }

            tables = summaries.sorted(by: compareTables(_:_:))
        } catch {
            errorMessage = error.localizedDescription
            tables = []
        }
    }

    func selectTable(_ table: PKTableSummary) async {
        guard let userID = currentUserID() else {
            errorMessage = AppText.tr("Sign in to join a room.")
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            guard let room = try await roomRepository.fetchRoom(roomID: table.roomID) else {
                errorMessage = AppText.tr("Table is no longer available.")
                return
            }

            var roomMembers = try await roomRepository.fetchMembers(roomID: room.roomID)
            if let existingMembership = roomMembers.first(where: { $0.userID == userID && $0.joinState == .joined }) {
                currentRoom = room
                currentMembership = existingMembership
                members = roomMembers
                return
            }

            guard table.status == .open else {
                errorMessage = table.status == .running
                    ? AppText.tr("This table is already running.")
                    : AppText.tr("This table is full.")
                return
            }

            let membership = RoomMemberRecord(
                roomID: room.roomID,
                userID: userID,
                role: .member
            )
            try await roomRepository.upsertMember(membership)
            roomMembers = try await roomRepository.fetchMembers(roomID: room.roomID)
            currentRoom = room
            currentMembership = roomMembers.first(where: { $0.userID == userID })
            members = roomMembers
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createRoom(title: String, plannedMinutes: Int) async {
        guard let userID = currentUserID() else {
            errorMessage = AppText.tr("Sign in to create a room.")
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
            errorMessage = AppText.tr("Sign in to join a room.")
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            guard let room = try await roomRepository.fetchRoom(byInviteCode: inviteCode) else {
                errorMessage = AppText.format("Room not found for code: %@", inviteCode)
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
        await loadTableHall()
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

    private func makeTableSummary(
        room: RoomRecord,
        members: [RoomMemberRecord],
        currentUserID: String?
    ) -> PKTableSummary {
        let activeMembers = members.filter { $0.joinState == .joined }
        let memberCount = activeMembers.count
        let isCurrentUsersTable = currentUserID.map { userID in
            activeMembers.contains(where: { $0.userID == userID })
        } ?? false

        let status: PKTableStatus
        switch room.status {
        case .running:
            status = .running
        case .ended, .cancelled:
            status = .full
        case .lobby:
            status = memberCount >= 4 ? .full : .open
        }

        return PKTableSummary(
            roomID: room.roomID,
            title: room.title,
            plannedMinutes: room.plannedMinutes,
            inviteCode: room.inviteCode,
            memberCount: memberCount,
            status: status,
            source: tableSource,
            isCurrentUsersTable: isCurrentUsersTable
        )
    }

    private func compareTables(_ lhs: PKTableSummary, _ rhs: PKTableSummary) -> Bool {
        if lhs.isCurrentUsersTable != rhs.isCurrentUsersTable {
            return lhs.isCurrentUsersTable && !rhs.isCurrentUsersTable
        }

        let order: [PKTableStatus: Int] = [
            .open: 0,
            .running: 1,
            .full: 2
        ]

        if order[lhs.status] != order[rhs.status] {
            return (order[lhs.status] ?? 99) < (order[rhs.status] ?? 99)
        }

        return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
    }

    private func seedLocalTablesIfNeeded() async throws {
        guard tableSource == .local else { return }
        let existingRooms = try await roomRepository.fetchRooms()
        guard existingRooms.isEmpty else { return }

        let seedRooms: [RoomRecord] = [
            RoomRecord(roomID: "local-table-1", ownerUserID: "owner-1", title: "考研 PK", plannedMinutes: 25, inviteCode: "SSUCTG"),
            RoomRecord(roomID: "local-table-2", ownerUserID: "owner-2", title: "英语冲刺", plannedMinutes: 45, inviteCode: "ENGL45"),
            RoomRecord(roomID: "local-table-3", ownerUserID: "owner-3", title: "算法同桌", plannedMinutes: 30, inviteCode: "ALGO30", status: .running),
            RoomRecord(roomID: "local-table-4", ownerUserID: "owner-4", title: "论文精修", plannedMinutes: 50, inviteCode: "PAPER5")
        ]

        for room in seedRooms {
            try await roomRepository.createRoom(room)
        }

        let seededMembers: [RoomMemberRecord] = [
            RoomMemberRecord(roomID: "local-table-1", userID: "owner-1", role: .owner, readyState: .ready),
            RoomMemberRecord(roomID: "local-table-2", userID: "owner-2", role: .owner, readyState: .ready),
            RoomMemberRecord(roomID: "local-table-2", userID: "member-2a", role: .member, readyState: .notReady),
            RoomMemberRecord(roomID: "local-table-3", userID: "owner-3", role: .owner, readyState: .ready),
            RoomMemberRecord(roomID: "local-table-3", userID: "member-3a", role: .member, readyState: .ready, currentSeatState: .present, currentActivityState: .active),
            RoomMemberRecord(roomID: "local-table-4", userID: "owner-4", role: .owner, readyState: .ready),
            RoomMemberRecord(roomID: "local-table-4", userID: "member-4a", role: .member, readyState: .ready),
            RoomMemberRecord(roomID: "local-table-4", userID: "member-4b", role: .member, readyState: .ready),
            RoomMemberRecord(roomID: "local-table-4", userID: "member-4c", role: .member, readyState: .ready)
        ]

        for member in seededMembers {
            try await roomRepository.upsertMember(member)
        }
    }
}
