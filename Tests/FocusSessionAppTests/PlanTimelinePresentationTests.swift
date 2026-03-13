import XCTest
@testable import FocusSession

final class PlanTimelinePresentationTests: XCTestCase {
    func testMonthAxisLabelUsesChineseMonthText() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let date = calendar.date(from: DateComponents(year: 2026, month: 3, day: 1))!
        XCTAssertEqual(PlanTimelinePresentation.monthAxisLabel(for: date, calendar: calendar), "3月")
    }

    func testChartHeightUsesCompactMinimumForLowDensityTimelines() {
        XCTAssertEqual(PlanTimelinePresentation.chartHeight(forGoalCount: 0), 208)
        XCTAssertEqual(PlanTimelinePresentation.chartHeight(forGoalCount: 1), 208)
        XCTAssertEqual(PlanTimelinePresentation.chartHeight(forGoalCount: 2), 208)
    }

    func testMonthAxisSpacingUsesStrongerSeparationValues() {
        XCTAssertEqual(PlanTimelinePresentation.monthAxisLabelTopPadding, 45)
        XCTAssertEqual(PlanTimelinePresentation.timelineCardTopPadding, 18)
        XCTAssertEqual(PlanTimelinePresentation.timelineCardBottomPadding, 2)
    }

    func testChartContentWidthMultiplierScalesWithZoomedMonthSpan() {
        XCTAssertEqual(
            PlanTimelinePresentation.chartContentWidthMultiplier(forVisibleMonthSpan: 12),
            1.0
        )
        XCTAssertEqual(
            PlanTimelinePresentation.chartContentWidthMultiplier(forVisibleMonthSpan: 6),
            1.6
        )
        XCTAssertEqual(
            PlanTimelinePresentation.chartContentWidthMultiplier(forVisibleMonthSpan: 3),
            2.2
        )
        XCTAssertEqual(
            PlanTimelinePresentation.chartContentWidthMultiplier(forVisibleMonthSpan: 1),
            3.2
        )
    }

    func testAxisDetailLevelAddsMoreIntermediateTicksAsTimelineZoomsIn() {
        XCTAssertEqual(
            PlanTimelinePresentation.axisDetailLevel(forVisibleMonthSpan: 12),
            .monthsOnly
        )
        XCTAssertEqual(
            PlanTimelinePresentation.axisDetailLevel(forVisibleMonthSpan: 6),
            .monthsAndWeeks
        )
        XCTAssertEqual(
            PlanTimelinePresentation.axisDetailLevel(forVisibleMonthSpan: 3),
            .monthsAndWeeks
        )
        XCTAssertEqual(
            PlanTimelinePresentation.axisDetailLevel(forVisibleMonthSpan: 1),
            .monthsWeeksAndDays
        )
    }

    func testChartHeightPreservesExistingGrowthForDenserTimelines() {
        XCTAssertEqual(PlanTimelinePresentation.chartHeight(forGoalCount: 3), 240)
        XCTAssertEqual(PlanTimelinePresentation.chartHeight(forGoalCount: 4), 276)
        XCTAssertEqual(PlanTimelinePresentation.chartHeight(forGoalCount: 5), 320)
    }

    func testLongBarPlacesTitleInsideTheBar() {
        let window = DateInterval(
            start: Date(timeIntervalSince1970: 0),
            end: Date(timeIntervalSince1970: 365 * 24 * 60 * 60)
        )
        let goal = PlanGoal(
            title: "AI competition",
            startAt: Date(timeIntervalSince1970: 60 * 24 * 60 * 60),
            endAt: Date(timeIntervalSince1970: 180 * 24 * 60 * 60)
        )

        XCTAssertEqual(
            PlanTimelinePresentation.labelPlacement(for: goal, within: window),
            .inside
        )
    }

    func testShortBarNearStartPlacesTitleOnTrailingSide() {
        let window = DateInterval(
            start: Date(timeIntervalSince1970: 0),
            end: Date(timeIntervalSince1970: 365 * 24 * 60 * 60)
        )
        let goal = PlanGoal(
            title: "Dachuang",
            startAt: Date(timeIntervalSince1970: 20 * 24 * 60 * 60),
            endAt: Date(timeIntervalSince1970: 45 * 24 * 60 * 60)
        )

        XCTAssertEqual(
            PlanTimelinePresentation.labelPlacement(for: goal, within: window),
            .trailingOutside
        )
    }

    func testShortBarNearEndPlacesTitleOnLeadingSide() {
        let window = DateInterval(
            start: Date(timeIntervalSince1970: 0),
            end: Date(timeIntervalSince1970: 365 * 24 * 60 * 60)
        )
        let goal = PlanGoal(
            title: "Wrap report",
            startAt: Date(timeIntervalSince1970: 330 * 24 * 60 * 60),
            endAt: Date(timeIntervalSince1970: 350 * 24 * 60 * 60)
        )

        XCTAssertEqual(
            PlanTimelinePresentation.labelPlacement(for: goal, within: window),
            .leadingOutside
        )
    }
}
