import XCTest
@testable import FocusSession

@MainActor
final class SeatMonitorTests: XCTestCase {
    func testStartsInUnknownState() {
        let (monitor, _) = makeMonitor()
        XCTAssertEqual(monitor.seatState, .unknown)
    }
    
    func testSingleMissingFrameDoesNotDeclareAway() {
        let (monitor, pipeline) = makeMonitor(awayThreshold: 3)
        monitor.start()
        pipeline.emit(.missing)
        XCTAssertNotEqual(monitor.seatState, .away)
    }
    
    func testRepeatedMissingFramesTransitionToAway() {
        let (monitor, pipeline) = makeMonitor(awayThreshold: 3)
        monitor.start()
        pipeline.emit(.missing)
        pipeline.emit(.missing)
        pipeline.emit(.missing)
        XCTAssertEqual(monitor.seatState, .away)
    }
    
    func testPersonPresentFrameTransitionsToPresent() {
        let (monitor, pipeline) = makeMonitor()
        monitor.start()
        pipeline.emit(.present)
        XCTAssertEqual(monitor.seatState, .present)
    }
    
    func testPresentFrameResetsAwayCounter() {
        let (monitor, pipeline) = makeMonitor(awayThreshold: 3)
        monitor.start()
        pipeline.emit(.missing)
        pipeline.emit(.missing)
        pipeline.emit(.present)   // resets counter
        pipeline.emit(.missing)
        pipeline.emit(.missing)
        XCTAssertNotEqual(monitor.seatState, .away)  // only 2 missing after reset
    }
    
    func testStopSetsUnknownState() {
        let (monitor, pipeline) = makeMonitor()
        monitor.start()
        pipeline.emit(.present)
        monitor.stop()
        XCTAssertEqual(monitor.seatState, .unknown)
    }
    
    private func makeMonitor(awayThreshold: Int = 3) -> (SeatMonitor, StubSeatMonitorFramePipeline) {
        let pipeline = StubSeatMonitorFramePipeline()
        let monitor = SeatMonitor(pipeline: pipeline, awayThreshold: awayThreshold)
        return (monitor, pipeline)
    }
}
