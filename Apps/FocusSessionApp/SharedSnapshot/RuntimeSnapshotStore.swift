import Foundation
import FocusSessionCore

struct RuntimeSnapshotStore {
    private let containerURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(containerURL: URL) {
        self.containerURL = containerURL
    }

    func write(_ snapshot: ActiveSessionSnapshot) throws {
        try FileManager.default.createDirectory(at: containerURL, withIntermediateDirectories: true)
        let data = try encoder.encode(snapshot)
        try data.write(to: snapshotURL, options: .atomic)
    }

    func read() throws -> ActiveSessionSnapshot {
        let data = try Data(contentsOf: snapshotURL)
        return try decoder.decode(ActiveSessionSnapshot.self, from: data)
    }

    func clear() throws {
        guard FileManager.default.fileExists(atPath: snapshotURL.path) else {
            return
        }
        try FileManager.default.removeItem(at: snapshotURL)
    }

    static func defaultLocal() -> RuntimeSnapshotStore? {
        guard let baseURL = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            return nil
        }

        let containerURL = baseURL
            .appendingPathComponent("FocusSession", isDirectory: true)
            .appendingPathComponent("SharedRuntimeSnapshot", isDirectory: true)
        return RuntimeSnapshotStore(containerURL: containerURL)
    }

    private var snapshotURL: URL {
        containerURL.appendingPathComponent("active-session.json")
    }
}
