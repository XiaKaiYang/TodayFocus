import CoreGraphics
import XCTest
@testable import FocusSession

final class TimelineZoomInteractionGateTests: XCTestCase {
    func testVerticalDominantScrollRoutesToZoomWhenGateIsActive() {
        XCTAssertEqual(
            TimelineZoomScrollRouting.route(deltaX: 2, deltaY: 12, isZoomActive: true),
            .zoom
        )
    }

    func testHorizontalDominantScrollPassesThroughWhenGateIsActive() {
        XCTAssertEqual(
            TimelineZoomScrollRouting.route(deltaX: 14, deltaY: 3, isZoomActive: true),
            .passThrough
        )
    }

    func testInactiveGateAlwaysPassesThroughScrolling() {
        XCTAssertEqual(
            TimelineZoomScrollRouting.route(deltaX: 0, deltaY: 12, isZoomActive: false),
            .passThrough
        )
    }

    func testZeroScrollPassesThrough() {
        XCTAssertEqual(
            TimelineZoomScrollRouting.route(deltaX: 0, deltaY: 0, isZoomActive: true),
            .passThrough
        )
    }

    func testGateStartsInactive() {
        let gate = TimelineZoomInteractionGate()

        XCTAssertFalse(gate.isActive)
    }

    func testActivateEnablesZoomHandling() {
        var gate = TimelineZoomInteractionGate()

        gate.activate()

        XCTAssertTrue(gate.isActive)
    }

    func testOutsideClickDeactivatesGate() {
        var gate = TimelineZoomInteractionGate()
        gate.activate()

        gate.deactivateIfNeeded(
            for: CGPoint(x: 180, y: 40),
            in: CGRect(x: 0, y: 0, width: 120, height: 80)
        )

        XCTAssertFalse(gate.isActive)
    }

    func testInsideClickKeepsGateActive() {
        var gate = TimelineZoomInteractionGate()
        gate.activate()

        gate.deactivateIfNeeded(
            for: CGPoint(x: 60, y: 40),
            in: CGRect(x: 0, y: 0, width: 120, height: 80)
        )

        XCTAssertTrue(gate.isActive)
    }
}
