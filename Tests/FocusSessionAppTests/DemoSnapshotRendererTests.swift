import AppKit
import XCTest
@testable import FocusSession

@MainActor
final class DemoSnapshotRendererTests: XCTestCase {
    func testRenderBlockerWritesPNGToRequestedPath() throws {
        let outputURL = outputURL(
            environmentKey: "FOCUSSESSION_SNAPSHOT_OUTPUT_PATH"
        )

        try DemoSnapshotRenderer.renderBlocker(to: outputURL)

        let data = try Data(contentsOf: outputURL)
        XCTAssertFalse(data.isEmpty)
        print("Snapshot written to \(outputURL.path)")
    }

    func testRenderTasksWritesPNGToRequestedPath() throws {
        let outputURL = outputURL(
            environmentKey: "FOCUSSESSION_TASKS_SNAPSHOT_OUTPUT_PATH"
        )

        try DemoSnapshotRenderer.renderTasks(to: outputURL)

        let data = try Data(contentsOf: outputURL)
        XCTAssertFalse(data.isEmpty)
        print("Tasks snapshot written to \(outputURL.path)")
    }

    func testRenderCurrentSessionWritesPNGToRequestedPath() throws {
        let outputURL = outputURL(
            environmentKey: "FOCUSSESSION_CURRENT_SESSION_SNAPSHOT_OUTPUT_PATH"
        )

        try DemoSnapshotRenderer.renderCurrentSession(to: outputURL)

        let data = try Data(contentsOf: outputURL)
        XCTAssertFalse(data.isEmpty)
        print("Current session snapshot written to \(outputURL.path)")
    }

    func testRenderCurrentSessionSetupWritesPNGToRequestedPath() throws {
        let outputURL = outputURL(
            environmentKey: "FOCUSSESSION_CURRENT_SESSION_SETUP_SNAPSHOT_OUTPUT_PATH"
        )

        try DemoSnapshotRenderer.renderCurrentSessionSetup(to: outputURL)

        let data = try Data(contentsOf: outputURL)
        XCTAssertFalse(data.isEmpty)
        print("Current session setup snapshot written to \(outputURL.path)")
    }

    func testRenderCurrentSessionShellSetupWritesPNGToRequestedPath() throws {
        let outputURL = outputURL(
            environmentKey: "FOCUSSESSION_CURRENT_SESSION_SHELL_SETUP_SNAPSHOT_OUTPUT_PATH"
        )

        try DemoSnapshotRenderer.renderCurrentSessionShellSetup(to: outputURL)

        let data = try Data(contentsOf: outputURL)
        XCTAssertFalse(data.isEmpty)
        print("Current session shell setup snapshot written to \(outputURL.path)")
    }

    private func outputURL(environmentKey: String) -> URL {
        if let requestedPath = ProcessInfo.processInfo.environment[environmentKey] {
            return URL(fileURLWithPath: requestedPath)
        }

        return URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("png")
    }
}
