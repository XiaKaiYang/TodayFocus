import CloudKit
import Foundation

protocol RoomRepositoryProtocol: Sendable {
    func createRoom(_ room: RoomRecord) async throws
    func fetchRoom(byInviteCode code: String) async throws -> RoomRecord?
    func fetchRoom(roomID: String) async throws -> RoomRecord?
    func fetchRooms() async throws -> [RoomRecord]
    func updateRoom(_ room: RoomRecord) async throws
    func upsertMember(_ member: RoomMemberRecord) async throws
    func fetchMembers(roomID: String) async throws -> [RoomMemberRecord]
}

final class RoomRepository: RoomRepositoryProtocol, @unchecked Sendable {
    let databaseScope: CKDatabase.Scope
    private let databaseProvider: @Sendable (CKDatabase.Scope) throws -> CKDatabase

    init(
        databaseScope: CKDatabase.Scope = .private,
        databaseProvider: @escaping @Sendable (CKDatabase.Scope) throws -> CKDatabase = CloudKitDatabaseProvider.makeDatabase
    ) {
        self.databaseScope = databaseScope
        self.databaseProvider = databaseProvider
    }

    func createRoom(_ room: RoomRecord) async throws {
        let database = try databaseProvider(databaseScope)
        let ckRecord = room.toCKRecord()
        try await database.save(ckRecord)
    }

    func fetchRoom(byInviteCode code: String) async throws -> RoomRecord? {
        let database = try databaseProvider(databaseScope)
        let predicate = NSPredicate(format: "inviteCode == %@", code)
        let query = CKQuery(recordType: RoomRecord.recordType, predicate: predicate)
        let (results, _) = try await database.records(matching: query, desiredKeys: nil)
        return results.compactMap { _, result in
            try? result.get()
        }.compactMap(RoomRecord.init(ckRecord:)).first
    }

    func fetchRoom(roomID: String) async throws -> RoomRecord? {
        let database = try databaseProvider(databaseScope)
        let recordID = CKRecord.ID(recordName: roomID)
        do {
            let ckRecord = try await database.record(for: recordID)
            return RoomRecord(ckRecord: ckRecord)
        } catch let error as CKError where error.code == .unknownItem {
            return nil
        }
    }

    func fetchRooms() async throws -> [RoomRecord] {
        let database = try databaseProvider(databaseScope)
        let query = CKQuery(recordType: RoomRecord.recordType, predicate: NSPredicate(value: true))
        let (results, _) = try await database.records(matching: query, desiredKeys: nil)
        return results.compactMap { _, result in
            try? result.get()
        }.compactMap(RoomRecord.init(ckRecord:))
    }

    func updateRoom(_ room: RoomRecord) async throws {
        let database = try databaseProvider(databaseScope)
        let ckRecord = room.toCKRecord()
        try await database.save(ckRecord)
    }

    func upsertMember(_ member: RoomMemberRecord) async throws {
        let database = try databaseProvider(databaseScope)
        let ckRecord = member.toCKRecord()
        try await database.save(ckRecord)
    }

    func fetchMembers(roomID: String) async throws -> [RoomMemberRecord] {
        let database = try databaseProvider(databaseScope)
        let predicate = NSPredicate(format: "roomID == %@", roomID)
        let query = CKQuery(recordType: RoomMemberRecord.recordType, predicate: predicate)
        let (results, _) = try await database.records(matching: query, desiredKeys: nil)
        return results.compactMap { _, result in
            try? result.get()
        }.compactMap(RoomMemberRecord.init(ckRecord:))
    }
}

final class StubRoomRepository: RoomRepositoryProtocol, @unchecked Sendable {
    var rooms: [String: RoomRecord] = [:]
    var members: [String: [RoomMemberRecord]] = [:]

    func createRoom(_ room: RoomRecord) async throws {
        rooms[room.roomID] = room
    }

    func fetchRoom(byInviteCode code: String) async throws -> RoomRecord? {
        rooms.values.first { $0.inviteCode == code }
    }

    func fetchRoom(roomID: String) async throws -> RoomRecord? {
        rooms[roomID]
    }

    func fetchRooms() async throws -> [RoomRecord] {
        Array(rooms.values)
    }

    func updateRoom(_ room: RoomRecord) async throws {
        rooms[room.roomID] = room
    }

    func upsertMember(_ member: RoomMemberRecord) async throws {
        var roomMembers = members[member.roomID] ?? []
        if let idx = roomMembers.firstIndex(where: { $0.userID == member.userID }) {
            roomMembers[idx] = member
        } else {
            roomMembers.append(member)
        }
        members[member.roomID] = roomMembers
    }

    func fetchMembers(roomID: String) async throws -> [RoomMemberRecord] {
        members[roomID] ?? []
    }
}
