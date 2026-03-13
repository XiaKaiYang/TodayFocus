# Gantt Card Clipping Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Prevent zoomed gantt bars from drawing outside the rounded timeline card.

**Architecture:** Keep the fix local to the `chartCard` view. Add a regression test that requires a rounded clip shape on the timeline card, then apply the matching clip to the existing chart container without changing timeline zoom logic.

**Tech Stack:** SwiftUI, Charts, XCTest

---

### Task 1: Add the failing clipping regression test

**Files:**
- Modify: `Tests/FocusSessionAppTests/PlanDashboardViewSourceTests.swift`

**Step 1: Write the failing test**

Add a source assertion that requires the timeline card to include `.clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))`.

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -project FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/PlanDashboardViewSourceTests`

Expected: FAIL because the timeline card does not yet clip its content.

### Task 2: Add the minimal card clipping implementation

**Files:**
- Modify: `Apps/FocusSessionApp/UI/Plan/PlanDashboardView.swift`

**Step 1: Write minimal implementation**

Apply the rounded clip shape directly to the timeline card view, matching the existing `AppCardSurface` corner radius.

**Step 2: Run test to verify it passes**

Run: `xcodebuild test -project FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/PlanDashboardViewSourceTests`

Expected: PASS

### Task 3: Run focused regression verification

**Files:**
- Test: `Tests/FocusSessionAppTests/PlanDashboardViewSourceTests.swift`
- Test: `Tests/FocusSessionAppTests/TimelineZoomInteractionGateTests.swift`
- Test: `Tests/FocusSessionAppTests/PlanViewModelTests.swift`
- Test: `Tests/FocusSessionAppTests/PlanTimelinePresentationTests.swift`

**Step 1: Run focused regression tests**

Run: `xcodebuild test -project FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/PlanDashboardViewSourceTests -only-testing:FocusSessionAppTests/TimelineZoomInteractionGateTests -only-testing:FocusSessionAppTests/PlanViewModelTests -only-testing:FocusSessionAppTests/PlanTimelinePresentationTests`

Expected: PASS
