# Goal Subtask Card Mini Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Shrink the expanded goal subtask cards again and change their background to an off-white surface.

**Architecture:** Keep the existing compact-card structure and interactions. First lock the intended smaller geometry and off-white fill values with a failing source test, then make the minimum SwiftUI changes in `PlanDashboardView` to reduce card width, height, padding, and control sizes while replacing the colored surface with a beige off-white fill.

**Tech Stack:** SwiftUI, XCTest

---

### Task 1: Add the failing mini-card regression test

**Files:**
- Modify: `Tests/FocusSessionAppTests/PlanDashboardViewSourceTests.swift`

**Step 1: Write the failing test**

Require the source to use a smaller subtask card minimum height and padding, and require explicit off-white fill values in `subtaskCardSurfaceFill`.

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -project FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/PlanDashboardViewSourceTests`

Expected: FAIL because the source still uses the larger card geometry and the previous tinted fills.

### Task 2: Implement the smaller off-white card

**Files:**
- Modify: `Apps/FocusSessionApp/UI/Plan/PlanDashboardView.swift`

**Step 1: Write minimal implementation**

Reduce the adaptive grid width and card geometry, shrink text and control sizing, and replace the current tinted fill palette with a uniform beige off-white surface.

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
