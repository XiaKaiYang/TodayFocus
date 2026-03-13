# Goal Progress Fill Surface Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make subtask cards and gantt bars share a transparent status-colored track with progress-based fill.

**Architecture:** Keep the current compact card layout and the existing chart structure, but split both surfaces into a low-opacity base and a stronger fill layer. First lock the new card and timeline helpers with a failing source test, then make the minimum SwiftUI changes in `PlanDashboardView` so both surfaces follow the same tint and fill direction.

**Tech Stack:** SwiftUI, Charts, XCTest

---

### Task 1: Add the failing progress-surface regression test

**Files:**
- Modify: `Tests/FocusSessionAppTests/PlanDashboardViewSourceTests.swift`

**Step 1: Write the failing test**

Require the source to use a dedicated subtask card progress surface helper and a dedicated timeline fill-end helper. Remove assertions that require the previous off-white-only surface values.

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -project FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/PlanDashboardViewSourceTests`

Expected: FAIL because the source still uses the off-white card surface and single-layer gantt bar rendering.

### Task 2: Implement the shared progress-fill surfaces

**Files:**
- Modify: `Apps/FocusSessionApp/UI/Plan/PlanDashboardView.swift`

**Step 1: Write minimal implementation**

Add a low-opacity base and progress fill layer for subtask cards using the status tint. Add a timeline fill-end helper and overlay fill `RectangleMark` so goal bars also show progress against a transparent track.

**Step 2: Run test to verify it passes**

Run: `xcodebuild test -project FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/PlanDashboardViewSourceTests`

Expected: PASS

### Task 3: Run focused regression verification

**Files:**
- Test: `Tests/FocusSessionAppTests/PlanDashboardViewSourceTests.swift`
- Test: `Tests/FocusSessionAppTests/PlanViewModelTests.swift`

**Step 1: Run focused regression tests**

Run: `xcodebuild test -project FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/PlanDashboardViewSourceTests -only-testing:FocusSessionAppTests/PlanViewModelTests`

Expected: PASS
