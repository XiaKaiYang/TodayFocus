# Analytics Pie Charts Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace both analytics cards with pie charts and show detailed values when the user hovers a slice.

**Architecture:** Keep the analytics data model stable and implement the change entirely in the analytics UI layer. Add a reusable pie graphic plus two focused wrapper views, then update the dashboard cards to use those views and verify the hover wiring with regression tests.

**Tech Stack:** SwiftUI, XCTest, FocusSessionCore

---

### Task 1: Add failing regression tests for pie-chart wiring

**Files:**
- Modify: `Tests/FocusSessionAppTests/AnalyticsViewModelTests.swift`

**Step 1: Write the failing test**

Add a source-level regression test that requires:
- `AnalyticsDashboardView.swift` uses `DailyFocusPieChartView`
- `AnalyticsDashboardView.swift` uses `TaskBreakdownPieChartView`
- `AnalyticsCharts.swift` contains hover wiring

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -project FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/AnalyticsViewModelTests`

Expected: FAIL because the dashboard still uses the old chart/list views.

### Task 2: Implement the reusable pie chart views

**Files:**
- Modify: `Apps/FocusSessionApp/UI/Analytics/AnalyticsCharts.swift`
- Modify: `Apps/FocusSessionApp/UI/Analytics/AnalyticsDashboardView.swift`

**Step 1: Write minimal implementation**

Replace the existing custom bar chart with:
- a pie-slice shape
- a reusable pie graphic with hover selection
- `DailyFocusPieChartView`
- `TaskBreakdownPieChartView`

Update the analytics dashboard cards to use the new pie-chart views.

**Step 2: Run test to verify it passes**

Run: `xcodebuild test -project FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/AnalyticsViewModelTests`

Expected: PASS

### Task 3: Run focused analytics regression verification

**Files:**
- Test: `Tests/FocusSessionAppTests/AnalyticsViewModelTests.swift`
- Test: `Tests/FocusSessionAppTests/AppShellViewModelTests.swift`

**Step 1: Run focused regression tests**

Run: `xcodebuild test -project FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/AnalyticsViewModelTests -only-testing:FocusSessionAppTests/AppShellViewModelTests`

Expected: PASS
