# Subtask Add Slot Centering Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Center the add-subtask placeholder vertically within its grid cell so it no longer sticks to the top of rows with taller neighboring cards.

**Architecture:** Keep the current button styling and interaction intact. Change only the grid-slot wrapper in `PlanDashboardView` so the add button expands to the full cell height and uses vertical spacers to stay centered within that space.

**Tech Stack:** SwiftUI, XCTest source assertions, focused `xcodebuild` test runs.

---

### Task 1: Lock in vertically centered add-slot layout with a failing test

**Files:**
- Modify: `/Users/xiakaiyang/Documents/New project/Tests/FocusSessionAppTests/PlanDashboardViewSourceTests.swift`

**Step 1: Write the failing test**

Add a source assertion that the add-subtask slot wraps `goalAddSubtaskButton(for: goal)` in a `VStack` with top and bottom spacers plus a full-height frame.

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -project FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/PlanDashboardViewSourceTests`
Expected: FAIL because the add button is still inserted directly with a fixed-height frame.

### Task 2: Implement the centered slot wrapper with minimal code

**Files:**
- Modify: `/Users/xiakaiyang/Documents/New project/Apps/FocusSessionApp/UI/Plan/PlanDashboardView.swift`

**Step 1: Write minimal implementation**

Replace the direct add-button grid item with a small vertical wrapper that uses `Spacer(minLength: 0)` above and below the button, expands to the available grid cell height, and preserves the existing minimum height.

**Step 2: Run focused tests to verify they pass**

Run: `xcodebuild test -project FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/PlanViewModelTests -only-testing:FocusSessionAppTests/PlanDashboardViewSourceTests`
Expected: PASS.
