import XCTest
@testable import FocusSession
import FocusSessionCore

final class RuntimeSnapshotStoreTests: XCTestCase {
    func testRuntimeSnapshotRoundTripsThroughAppGroupJSON() throws {
        let containerURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: containerURL, withIntermediateDirectories: true)

        let store = RuntimeSnapshotStore(containerURL: containerURL)
        let snapshot = ActiveSessionSnapshot(
            intention: "Write tests first",
            plannedDurationSeconds: 1500,
            startedAt: Date(timeIntervalSince1970: 0)
        )

        try store.write(snapshot)

        XCTAssertEqual(try store.read(), snapshot)
    }

    func testClearRemovesPersistedRuntimeSnapshot() throws {
        let containerURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: containerURL, withIntermediateDirectories: true)

        let store = RuntimeSnapshotStore(containerURL: containerURL)
        let snapshot = ActiveSessionSnapshot(
            intention: "Clear me",
            plannedDurationSeconds: 900,
            startedAt: Date(timeIntervalSince1970: 0)
        )

        try store.write(snapshot)
        try store.clear()

        XCTAssertThrowsError(try store.read())
    }
}
