import XCTest
@testable import FocusSessionCore

final class GoalProgressWidgetStoreTests: XCTestCase {
    func testSnapshotRoundTripsThroughJSONStore() throws {
        let containerURL = makeTemporaryDirectory()
        let store = GoalProgressWidgetStore(containerURL: containerURL)
        let snapshot = GoalProgressWidgetSnapshot(
            items: [
                GoalProgressWidgetItem(
                    id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!,
                    title: "Reading Influence",
                    progressPercent: 40,
                    progressLabel: "40%",
                    tintToken: .lilac
                ),
                GoalProgressWidgetItem(
                    id: UUID(uuidString: "11111111-2222-3333-4444-555555555555")!,
                    title: "Weekly Exercise",
                    progressPercent: 25,
                    progressLabel: "25%",
                    tintToken: .peach
                )
            ],
            updatedAt: Date(timeIntervalSince1970: 1_000)
        )

        try store.write(snapshot)

        XCTAssertEqual(try store.read(), snapshot)
    }

    func testReadThrowsWhenSnapshotDoesNotExist() {
        let containerURL = makeTemporaryDirectory()
        let store = GoalProgressWidgetStore(containerURL: containerURL)

        XCTAssertThrowsError(try store.read())
    }

    func testClearRemovesPersistedSnapshot() throws {
        let containerURL = makeTemporaryDirectory()
        let store = GoalProgressWidgetStore(containerURL: containerURL)
        let snapshot = GoalProgressWidgetSnapshot(
            items: [
                GoalProgressWidgetItem(
                    id: UUID(),
                    title: "Cycling",
                    progressPercent: 67,
                    progressLabel: "67%",
                    tintToken: .mint
                )
            ],
            updatedAt: Date(timeIntervalSince1970: 2_000)
        )

        try store.write(snapshot)
        try store.clear()

        XCTAssertThrowsError(try store.read())
    }

    private func makeTemporaryDirectory() -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.removeItem(at: url)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
