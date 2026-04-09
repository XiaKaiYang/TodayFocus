import XCTest
@testable import FocusSessionCore

final class SessionReducerTests: XCTestCase {
    func testStartSessionMovesIdleToFocusing() throws {
        var state = SessionState.idle

        let transition = try SessionReducer.reduce(
            state: &state,
            event: .startSession(
                intention: "Write implementation plan",
                durationSeconds: 1500
            )
        )

        XCTAssertEqual(state.phase, .focusing)
        XCTAssertEqual(state.snapshot?.intention, "Write implementation plan")
        XCTAssertEqual(state.snapshot?.plannedDurationSeconds, 1500)
        XCTAssertEqual(
            transition.effects,
            [.persistSnapshot, .activateBlocker, .refreshMenubar]
        )
    }

    func testPauseMovesFocusingToFocusPaused() throws {
        var state = SessionState(
            phase: .focusing,
            snapshot: ActiveSessionSnapshot(
                intention: "Deep work",
                plannedDurationSeconds: 1500
            )
        )

        let transition = try SessionReducer.reduce(state: &state, event: .pause)

        XCTAssertEqual(state.phase, .focusPaused)
        XCTAssertEqual(transition.effects, [.refreshMenubar, .persistSnapshot])
    }

    func testResumeMovesFocusPausedBackToFocusing() throws {
        var state = SessionState(
            phase: .focusPaused,
            snapshot: ActiveSessionSnapshot(
                intention: "Deep work",
                plannedDurationSeconds: 1500
            )
        )

        let transition = try SessionReducer.reduce(state: &state, event: .resume)

        XCTAssertEqual(state.phase, .focusing)
        XCTAssertEqual(transition.effects, [.refreshMenubar, .persistSnapshot])
    }

    func testExtendAddsMinutesToPlannedDuration() throws {
        var state = SessionState(
            phase: .focusing,
            snapshot: ActiveSessionSnapshot(
                intention: "Deep work",
                plannedDurationSeconds: 1500
            )
        )

        let transition = try SessionReducer.reduce(state: &state, event: .extend(minutes: 5))

        XCTAssertEqual(state.snapshot?.plannedDurationSeconds, 1800)
        XCTAssertEqual(transition.effects, [.persistSnapshot, .refreshMenubar])
    }

    func testFinishFocusMovesFocusingToReflectingAndClearsSnapshot() throws {
        var state = SessionState(
            phase: .focusing,
            snapshot: ActiveSessionSnapshot(
                intention: "Deep work",
                plannedDurationSeconds: 1500
            )
        )

        let transition = try SessionReducer.reduce(state: &state, event: .finishFocus)

        XCTAssertEqual(state.phase, .reflecting)
        XCTAssertNil(state.snapshot)
        XCTAssertEqual(
            transition.effects,
            [.deactivateBlocker, .refreshMenubar, .persistSnapshot]
        )
    }

    func testSubmitReflectionMovesReflectingToCompleted() throws {
        var state = SessionState(phase: .reflecting, snapshot: nil)

        let transition = try SessionReducer.reduce(state: &state, event: .submitReflection)

        XCTAssertEqual(state.phase, .completed)
        XCTAssertNil(state.snapshot)
        XCTAssertEqual(
            transition.effects,
            [.refreshMenubar, .persistSnapshot]
        )
    }

    func testAbandonDeactivatesBlockerFromPausedFocus() throws {
        var state = SessionState(
            phase: .focusPaused,
            snapshot: ActiveSessionSnapshot(
                intention: "Deep work",
                plannedDurationSeconds: 1500
            )
        )

        let transition = try SessionReducer.reduce(state: &state, event: .abandon)

        XCTAssertEqual(state.phase, .abandoned)
        XCTAssertNil(state.snapshot)
        XCTAssertEqual(
            transition.effects,
            [.deactivateBlocker, .refreshMenubar, .persistSnapshot]
        )
    }
}
