import XCTest
import SwiftData
import FocusSessionCore
@testable import FocusSession

@MainActor
final class FocusSessionModelContainerSyncTests: XCTestCase {
    func testLegacyImportCopiesContentIntoEmptyDestinationContainer() throws {
        let legacyContainer = try FocusSessionModelContainer.makeInMemory()
        let destinationContainer = try FocusSessionModelContainer.makeInMemory()
        let legacyContext = ModelContext(legacyContainer)

        try FocusSessionRepository(modelContext: legacyContext).save(
            FocusSessionRecord(
                intention: "Review notes",
                startedAt: Date(timeIntervalSince1970: 10),
                endedAt: Date(timeIntervalSince1970: 610),
                notes: "Bellman equation",
                wasCompleted: true
            )
        )
        try TasksRepository(modelContext: legacyContext).save(
            FocusTask(
                title: "Read chapter 4",
                estimatedMinutes: 30,
                subtasks: [TaskSubtask(title: "Section 4.1")]
            )
        )
        try PlanGoalsRepository(modelContext: legacyContext).save(
            PlanGoal(
                title: "Finish RL review",
                startAt: Date(timeIntervalSince1970: 100),
                endAt: Date(timeIntervalSince1970: 200)
            )
        )

        XCTAssertTrue(
            try FocusSessionModelContainer.importLegacyContentIfNeeded(
                from: legacyContainer,
                to: destinationContainer
            )
        )

        XCTAssertEqual(
            try FocusSessionRepository(modelContext: ModelContext(destinationContainer)).fetchAll().count,
            1
        )
        XCTAssertEqual(
            try TasksRepository(modelContext: ModelContext(destinationContainer)).fetchAll().count,
            1
        )
        XCTAssertEqual(
            try PlanGoalsRepository(modelContext: ModelContext(destinationContainer)).fetchAll().count,
            1
        )
    }

    func testLegacyImportSkipsWhenDestinationAlreadyContainsData() throws {
        let legacyContainer = try FocusSessionModelContainer.makeInMemory()
        let destinationContainer = try FocusSessionModelContainer.makeInMemory()
        let legacyContext = ModelContext(legacyContainer)
        let destinationContext = ModelContext(destinationContainer)

        try TasksRepository(modelContext: legacyContext).save(
            FocusTask(title: "Legacy task", estimatedMinutes: 25)
        )
        try TasksRepository(modelContext: destinationContext).save(
            FocusTask(title: "Synced task", estimatedMinutes: 40)
        )

        XCTAssertFalse(
            try FocusSessionModelContainer.importLegacyContentIfNeeded(
                from: legacyContainer,
                to: destinationContainer
            )
        )

        XCTAssertEqual(
            try TasksRepository(modelContext: destinationContext).fetchAll().map(\.title),
            ["Synced task"]
        )
    }

    func testPrepareApplicationSupportDirectoryCreatesMissingDirectory() throws {
        let baseDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Application Support", isDirectory: true)

        XCTAssertFalse(FileManager.default.fileExists(atPath: baseDirectory.path))

        let preparedDirectory = try FocusSessionModelContainer.prepareApplicationSupportDirectory(
            fileManager: .default,
            directoryOverride: baseDirectory
        )

        var isDirectory: ObjCBool = false
        XCTAssertTrue(FileManager.default.fileExists(atPath: preparedDirectory.path, isDirectory: &isDirectory))
        XCTAssertTrue(isDirectory.boolValue)
    }
}
