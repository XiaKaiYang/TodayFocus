# Subtask Plus Optical Centering Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make the `+` symbol inside the subtask add buttons appear visually centered without changing button size or layout.

**Architecture:** Keep the fix inside `PlanDashboardView` by introducing a shared helper that renders the plus symbol with the existing tint and font plus a small optical-centering offset. Reuse that helper for both add-button variants so the styling stays consistent.

**Tech Stack:** SwiftUI, XCTest source assertions, focused `xcodebuild` test runs.

---

### Task 1: Lock in shared centered-plus usage with a failing test

**Files:**
- Modify: `/Users/xiakaiyang/Documents/New project/Tests/FocusSessionAppTests/PlanDashboardViewSourceTests.swift`

**Step 1: Write the failing test**

Add source assertions for a shared centered-plus helper, for the helper's small vertical offset, and for both add-button call sites using that helper.

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -project FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/PlanDashboardViewSourceTests`
Expected: FAIL because the plus symbols are still written inline.

### Task 2: Implement the centered-plus helper with minimal code

**Files:**
- Modify: `/Users/xiakaiyang/Documents/New project/Apps/FocusSessionApp/UI/Plan/PlanDashboardView.swift`

**Step 1: Write minimal implementation**

Add a helper like `opticallyCenteredPlusIcon` and use it in the subtask-card action button and the add-subtask button while keeping the existing frames, backgrounds, and outlines.

**Step 2: Run focused tests to verify they pass**

Run: `xcodebuild test -project FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/PlanViewModelTests -only-testing:FocusSessionAppTests/PlanDashboardViewSourceTests`
Expected: PASS.
