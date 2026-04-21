import Foundation

actor LocalPKRepositoryStore {
    var rooms: [String: RoomRecord] = [:]
    var members: [String: [RoomMemberRecord]] = [:]
    var sessions: [String: PKSessionRecord] = [:]
    var buckets: [LeaderboardBucketRecord] = []

    func reset() {
        rooms = [:]
        members = [:]
        sessions = [:]
        buckets = []
    }

    func saveRoom(_ room: RoomRecord) {
        rooms[room.roomID] = room
    }

    func fetchRoom(roomID: String) -> RoomRecord? {
        rooms[roomID]
    }

    func fetchRoom(inviteCode: String) -> RoomRecord? {
        rooms.values.first { $0.inviteCode == inviteCode }
    }

    func saveMember(_ member: RoomMemberRecord) {
        var currentMembers = members[member.roomID] ?? []
        if let index = currentMembers.firstIndex(where: { $0.userID == member.userID }) {
            currentMembers[index] = member
        } else {
            currentMembers.append(member)
        }
        members[member.roomID] = currentMembers
    }

    func fetchMembers(roomID: String) -> [RoomMemberRecord] {
        members[roomID] ?? []
    }

    func saveSession(_ session: PKSessionRecord) {
        sessions[session.sessionID] = session
    }

    func fetchCurrentSession(roomID: String) -> PKSessionRecord? {
        sessions.values
            .filter { $0.roomID == roomID }
            .sorted { $0.startAt > $1.startAt }
            .first
    }

    func saveBucket(_ bucket: LeaderboardBucketRecord) {
        if let index = buckets.firstIndex(where: { $0.bucketID == bucket.bucketID }) {
            buckets[index] = bucket
        } else {
            buckets.append(bucket)
        }
    }

    func fetchBuckets(roomID: String, period: LeaderboardPeriod, periodKey: String) -> [LeaderboardBucketRecord] {
        buckets.filter { $0.roomID == roomID && $0.period == period && $0.periodKey == periodKey }
    }
}

final class LocalRoomRepository: RoomRepositoryProtocol, @unchecked Sendable {
    static let shared = LocalRoomRepository()

    private let store: LocalPKRepositoryStore

    init(store: LocalPKRepositoryStore = LocalPKRepositoryStore()) {
        self.store = store
    }

    func createRoom(_ room: RoomRecord) async throws {
        await store.saveRoom(room)
    }

    func fetchRoom(byInviteCode code: String) async throws -> RoomRecord? {
        await store.fetchRoom(inviteCode: code)
    }

    func fetchRoom(roomID: String) async throws -> RoomRecord? {
        await store.fetchRoom(roomID: roomID)
    }

    func updateRoom(_ room: RoomRecord) async throws {
        await store.saveRoom(room)
    }

    func upsertMember(_ member: RoomMemberRecord) async throws {
        await store.saveMember(member)
    }

    func fetchMembers(roomID: String) async throws -> [RoomMemberRecord] {
        await store.fetchMembers(roomID: roomID)
    }
}

final class LocalPKSessionRepository: PKSessionRepositoryProtocol, @unchecked Sendable {
    static let shared = LocalPKSessionRepository()

    private let store: LocalPKRepositoryStore

    init(store: LocalPKRepositoryStore = LocalPKRepositoryStore()) {
        self.store = store
    }

    func createSession(_ session: PKSessionRecord) async throws {
        await store.saveSession(session)
    }

    func fetchCurrentSession(roomID: String) async throws -> PKSessionRecord? {
        await store.fetchCurrentSession(roomID: roomID)
    }

    func updateSession(_ session: PKSessionRecord) async throws {
        await store.saveSession(session)
    }
}

final class LocalLeaderboardRepository: LeaderboardRepositoryProtocol, @unchecked Sendable {
    static let shared = LocalLeaderboardRepository()

    private let store: LocalPKRepositoryStore

    init(store: LocalPKRepositoryStore = LocalPKRepositoryStore()) {
        self.store = store
    }

    func fetchBuckets(roomID: String, period: LeaderboardPeriod, periodKey: String) async throws -> [LeaderboardBucketRecord] {
        await store.fetchBuckets(roomID: roomID, period: period, periodKey: periodKey)
    }

    func upsertBucket(_ bucket: LeaderboardBucketRecord) async throws {
        await store.saveBucket(bucket)
    }
}

enum PKRepositoryFactory {
    static private let sharedStore = LocalPKRepositoryStore()

    static func makeRoomRepository(cloudAvailable: Bool = CloudKitDatabaseProvider.isAvailable()) -> any RoomRepositoryProtocol {
        if cloudAvailable {
            return RoomRepository()
        }

        return LocalRoomRepository(store: sharedStore)
    }

    static func makePKSessionRepository(cloudAvailable: Bool = CloudKitDatabaseProvider.isAvailable()) -> any PKSessionRepositoryProtocol {
        if cloudAvailable {
            return PKSessionRepository()
        }

        return LocalPKSessionRepository(store: sharedStore)
    }

    static func makeLeaderboardRepository(cloudAvailable: Bool = CloudKitDatabaseProvider.isAvailable()) -> any LeaderboardRepositoryProtocol {
        if cloudAvailable {
            return LeaderboardRepository()
        }

        return LocalLeaderboardRepository(store: sharedStore)
    }
}
