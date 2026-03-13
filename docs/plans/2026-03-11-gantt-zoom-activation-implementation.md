# Gantt Zoom Activation Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Gate gantt wheel zoom behind an explicit click so normal downward scrolling does not accidentally zoom the chart.

**Architecture:** Keep the fix local to the chart overlay AppKit bridge. Add a small testable activation gate, then update the overlay view to activate on click, deactivate on outside click or window blur, and pass wheel events through when inactive.

**Tech Stack:** SwiftUI, AppKit, XCTest

---

### Task 1: Add failing tests for the activation gate

**Files:**
- Create: `Tests/FocusSessionAppTests/TimelineZoomInteractionGateTests.swift`
- Test: `Tests/FocusSessionAppTests/PlanDashboardViewSourceTests.swift`

**Step 1: Write the failing test**

Add tests that require:
- zoom starts inactive
- an explicit activation call enables zoom
- outside clicks deactivate zoom
- inside clicks do not deactivate zoom

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -project FocusSession.xcodeproj -scheme FocusSession -destination 'platform=macOS' -only-testing:FocusSessionAppTests/TimelineZoomInteractionGateTests -only-testing:FocusSessionAppTests/PlanDashboardViewSourceTests`

Expected: FAIL because the interaction gate and new source wiring do not exist yet.

### Task 2: Implement the minimal interaction gate and overlay behavior

**Files:**
- Modify: `Apps/FocusSessionApp/UI/Plan/PlanDashboardView.swift`

**Step 1: Write minimal implementation**

Add a small gate type with activation and deactivation helpers. Update `TimelineZoomTrackingView` to:
- activate on `mouseDown`
- pass scroll events to `super` when inactive
- send zoom callbacks only when active
- install and remove monitors that deactivate on outside clicks and window blur

**Step 2: Run test to verify it passes**

Run: `xcodebuild test -project FocusSession.xcodeproj -scheme FocusSession -destination 'platform=macOS' -only-testing:FocusSessionAppTests/TimelineZoomInteractionGateTests -only-testing:FocusSessionAppTests/PlanDashboardViewSourceTests`

Expected: PASS

### Task 3: Run focused regression verification

**Files:**
- Test: `Tests/FocusSessionAppTests/PlanViewModelTests.swift`
- Test: `Tests/FocusSessionAppTests/PlanTimelinePresentationTests.swift`

**Step 1: Run targeted regression tests**

Run: `xcodebuild test -project FocusSession.xcodeproj -scheme FocusSession -destination 'platform=macOS' -only-testing:FocusSessionAppTests/TimelineZoomInteractionGateTests -only-testing:FocusSessionAppTests/PlanDashboardViewSourceTests -only-testing:FocusSessionAppTests/PlanViewModelTests -only-testing:FocusSessionAppTests/PlanTimelinePresentationTests`

Expected: PASS
