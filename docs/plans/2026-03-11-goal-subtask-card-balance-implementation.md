# Goal Subtask Card Balance Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make expanded goal subtask cards smaller and visually softer so they fit the surrounding goal layout.

**Architecture:** Keep the current `goalSubtaskCard` structure and interaction model. First lock the intended geometry and muted-surface helper with a failing source test, then make the minimum SwiftUI changes needed in `PlanDashboardView` to reduce card size and switch from a saturated gradient to a subtle glass-tinted fill.

**Tech Stack:** SwiftUI, XCTest

---

### Task 1: Add the failing card-balance regression test

**Files:**
- Modify: `Tests/FocusSessionAppTests/PlanDashboardViewSourceTests.swift`

**Step 1: Write the failing test**

Require the source to use a smaller subtask card height and padding, plus a muted surface helper name such as `subtaskCardSurfaceFill(for: goal.status)`.

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -project FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/PlanDashboardViewSourceTests`

Expected: FAIL because the source still uses the taller card geometry and old gradient helper.

### Task 2: Implement the smaller, softer subtask card

**Files:**
- Modify: `Apps/FocusSessionApp/UI/Plan/PlanDashboardView.swift`

**Step 1: Write minimal implementation**

Reduce the subtask card minimum height, padding, corner radius, and internal control sizes. Replace the saturated gradient fill with a lighter mixed glass fill plus a subtle status tint so the cards blend with the existing dashboard surfaces.

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
