# Timeline Month Axis Spacing Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Increase the visual separation between timeline goal bars and month labels without changing the bar height or chart density.

**Architecture:** Keep the fix localized to `PlanDashboardView` by adjusting chart layout values only. Increase the plot's bottom padding and give the month axis label text a small top padding so the two layers are separated from both sides.

**Tech Stack:** SwiftUI Charts, XCTest source assertions, focused `xcodebuild` test runs.

---

### Task 1: Lock in the new chart spacing with a failing test

**Files:**
- Modify: `/Users/xiakaiyang/Documents/New project/Tests/FocusSessionAppTests/PlanDashboardViewSourceTests.swift`

**Step 1: Write the failing test**

Add source assertions for a larger chart plot bottom padding and a small top padding applied to the month axis label text.

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -project FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/PlanDashboardViewSourceTests`
Expected: FAIL because the chart still uses the smaller bottom padding and the month labels have no extra top spacing.

### Task 2: Implement the spacing tweak with minimal code

**Files:**
- Modify: `/Users/xiakaiyang/Documents/New project/Apps/FocusSessionApp/UI/Plan/PlanDashboardView.swift`

**Step 1: Write minimal implementation**

Increase the chart plot bottom padding and add a small top padding to the month axis label text while leaving the rest of the timeline presentation unchanged.

**Step 2: Run focused tests to verify they pass**

Run: `xcodebuild test -project FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/PlanViewModelTests -only-testing:FocusSessionAppTests/PlanDashboardViewSourceTests`
Expected: PASS.
