import XCTest
@testable import FocusSession

@MainActor
final class ActivityMonitorTests: XCTestCase {
    func testStartsInUnknownState() {
        let monitor = ActivityMonitor(inactivityThreshold: 60)
        XCTAssertEqual(monitor.activityState, .unknown)
    }

    func testStartTransitionsToActive() {
        let monitor = ActivityMonitor(inactivityThreshold: 60)
        monitor.start()
        XCTAssertEqual(monitor.activityState, .active)
        monitor.stop()
    }

    func testUserInteractionResetsToActive() {
        let monitor = ActivityMonitor(inactivityThreshold: 60)
        monitor.start()
        monitor.recordUserInteraction()
        XCTAssertEqual(monitor.activityState, .active)
        monitor.stop()
    }

    func testStopClearsState() {
        let monitor = ActivityMonitor(inactivityThreshold: 60)
        monitor.start()
        monitor.stop()
        XCTAssertEqual(monitor.activityState, .unknown)
    }

    func testStubCanSimulateInactivity() {
        let stub = StubActivityMonitor()
        stub.start()
        stub.simulateInactivity()
        XCTAssertEqual(stub.activityState, .inactive)
    }

    func testStubRecordsInteractions() {
        let stub = StubActivityMonitor()
        stub.recordUserInteraction()
        stub.recordUserInteraction()
        XCTAssertEqual(stub.interactionCount, 2)
        XCTAssertEqual(stub.activityState, .active)
    }
}
