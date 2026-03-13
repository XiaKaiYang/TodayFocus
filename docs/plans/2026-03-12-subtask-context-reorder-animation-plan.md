# Subtask Context Reorder Animation Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make subtask left/right moves triggered from the context menu animate with the same spring-driven horizontal swap motion as drag reorder.

**Architecture:** Keep the reorder persistence logic in `PlanViewModel`, and centralize the SwiftUI spring animation in `PlanDashboardView` so both drag completion and context-menu swaps use one animation helper. This preserves the current responsibilities while making both interaction paths visually consistent.

**Tech Stack:** SwiftUI, XCTest source assertions, focused `xcodebuild` test runs.

---

### Task 1: Lock in animated context-menu reorder wiring with a failing test

**Files:**
- Modify: `/Users/xiakaiyang/Documents/New project/Tests/FocusSessionAppTests/PlanDashboardViewSourceTests.swift`

**Step 1: Write the failing test**

Add a source assertion proving the context-menu `Move Left` and `Move Right` actions use a shared animated reorder helper instead of directly calling `viewModel.moveSubtaskLeft` or `viewModel.moveSubtaskRight`.

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -project FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/PlanDashboardViewSourceTests`
Expected: FAIL because the context-menu actions currently call the view model directly.

### Task 2: Implement the shared spring animation helper with minimal code

**Files:**
- Modify: `/Users/xiakaiyang/Documents/New project/Apps/FocusSessionApp/UI/Plan/PlanDashboardView.swift`

**Step 1: Write minimal implementation**

Add a small helper that wraps a reorder action in the existing spring animation, use it for drag-end reorder, and call it from the context-menu `Move Left` and `Move Right` actions.

**Step 2: Run focused tests to verify they pass**

Run: `xcodebuild test -project FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/PlanViewModelTests -only-testing:FocusSessionAppTests/PlanDashboardViewSourceTests`
Expected: PASS.
