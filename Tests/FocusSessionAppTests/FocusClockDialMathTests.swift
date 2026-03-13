import XCTest
@testable import FocusSession

final class FocusClockDialMathTests: XCTestCase {
    func testNormalizedValueStartsAtTopAndMovesClockwise() {
        let size = CGSize(width: 200, height: 200)

        XCTAssertEqual(
            FocusClockDialMath.normalizedValue(
                for: CGPoint(x: 100, y: 0),
                in: size
            ),
            0,
            accuracy: 0.001
        )
        XCTAssertEqual(
            FocusClockDialMath.normalizedValue(
                for: CGPoint(x: 200, y: 100),
                in: size
            ),
            0.25,
            accuracy: 0.001
        )
        XCTAssertEqual(
            FocusClockDialMath.normalizedValue(
                for: CGPoint(x: 100, y: 200),
                in: size
            ),
            0.5,
            accuracy: 0.001
        )
        XCTAssertEqual(
            FocusClockDialMath.normalizedValue(
                for: CGPoint(x: 0, y: 100),
                in: size
            ),
            0.75,
            accuracy: 0.001
        )
    }

    func testMinutesUseOneMinutePrecisionAndClampToRange() {
        XCTAssertEqual(FocusClockDialMath.minutes(for: -0.2), 0)
        XCTAssertEqual(FocusClockDialMath.minutes(for: 0.0), 0)
        XCTAssertEqual(FocusClockDialMath.minutes(for: 1.0 / 60.0), 1)
        XCTAssertEqual(FocusClockDialMath.minutes(for: 29.0 / 60.0), 29)
        XCTAssertEqual(FocusClockDialMath.minutes(for: 0.5), 30)
        XCTAssertEqual(FocusClockDialMath.minutes(for: 59.6 / 60.0), 60)
        XCTAssertEqual(FocusClockDialMath.minutes(for: 1.2), 60)
    }

    func testNormalizedValueForMinutesMatchesDialRange() {
        XCTAssertEqual(FocusClockDialMath.normalizedValue(forMinutes: 0), 0, accuracy: 0.001)
        XCTAssertEqual(FocusClockDialMath.normalizedValue(forMinutes: 1), 1.0 / 60.0, accuracy: 0.001)
        XCTAssertEqual(FocusClockDialMath.normalizedValue(forMinutes: 30), 0.5, accuracy: 0.001)
        XCTAssertGreaterThan(FocusClockDialMath.normalizedValue(forMinutes: 60), 0.98)
        XCTAssertLessThan(FocusClockDialMath.normalizedValue(forMinutes: 60), 1)
    }

    func testThirtyMinutesFallsStraightBelowDialCenter() {
        let size = CGSize(width: 200, height: 200)
        let point = FocusClockDialMath.point(
            for: FocusClockDialMath.normalizedValue(forMinutes: 30),
            in: size
        )

        XCTAssertEqual(point.x, 100, accuracy: 0.001)
        XCTAssertGreaterThan(point.y, 100)
    }
}
