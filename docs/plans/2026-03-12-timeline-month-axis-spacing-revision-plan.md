# Timeline Month Axis Spacing Revision Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Increase the separation between the lowest pink timeline bar and the month labels without changing bar height.

**Architecture:** Keep the fix localized to `PlanDashboardView` and revise only the chart layout constants. Update the source test first so it requires a larger y-scale `endPadding` and rejects the temporary plot-bottom/month-label padding tweak, then implement that minimal chart-range correction.

**Tech Stack:** SwiftUI Charts, XCTest source assertions, focused `xcodebuild` test runs.

---

### Task 1: Lock in the corrected bar-lift behavior with a failing test

**Files:**
- Modify: `/Users/xiakaiyang/Documents/New project/Tests/FocusSessionAppTests/PlanDashboardViewSourceTests.swift`

**Step 1: Write the failing test**

Change the source assertions so the chart must use a larger `.chartYScale(range: .plotDimension(startPadding: 20, endPadding: 64))`, and reject the previous `.padding(.bottom, 34)` plus `.padding(.top, 10)` axis-spacing workaround.

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -project FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/PlanDashboardViewSourceTests`
Expected: FAIL because the chart still uses `endPadding: 36` and the previous axis-spacing workaround.

### Task 2: Implement the y-scale bottom reserve with minimal code

**Files:**
- Modify: `/Users/xiakaiyang/Documents/New project/Apps/FocusSessionApp/UI/Plan/PlanDashboardView.swift`

**Step 1: Write minimal implementation**

Set `chartYScale` bottom `endPadding` to `64`, restore plot bottom padding to `14`, and remove the extra month-label top padding.

**Step 2: Run focused tests to verify they pass**

Run: `xcodebuild test -project FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/PlanViewModelTests -only-testing:FocusSessionAppTests/PlanDashboardViewSourceTests`
Expected: PASS.
