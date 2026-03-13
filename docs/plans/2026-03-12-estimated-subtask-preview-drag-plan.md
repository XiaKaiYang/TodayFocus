# Estimated Subtask Preview Drag Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make the Edit Subtask Automatic Preview bar directly draggable in Estimated mode so dragging updates the current completion percentage draft.

**Architecture:** Keep the interaction inside the existing `PlanDashboardView` subtask composer. Add a small view-model setter for normalized estimated progress updates, then swap the passive preview bar for a draggable bar only in Estimated mode while leaving Quantified mode read-only.

**Tech Stack:** SwiftUI, SwiftData-backed view model tests, XCTest source assertions.

---

### Task 1: Lock in the new Estimated preview behavior with failing tests

**Files:**
- Modify: `/Users/xiakaiyang/Documents/New project/Tests/FocusSessionAppTests/PlanViewModelTests.swift`
- Modify: `/Users/xiakaiyang/Documents/New project/Tests/FocusSessionAppTests/PlanDashboardViewSourceTests.swift`

**Step 1: Write the failing test**

Add a view-model test for a setter that clamps and rounds estimated progress values, plus a source test that checks the Estimated preview path uses a draggable progress bar binding.

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -project FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/PlanViewModelTests -only-testing:FocusSessionAppTests/PlanDashboardViewSourceTests`
Expected: FAIL because the setter and draggable bar wiring do not exist yet.

### Task 2: Implement the draggable Estimated preview bar with minimal code

**Files:**
- Modify: `/Users/xiakaiyang/Documents/New project/Apps/FocusSessionApp/ViewModels/PlanViewModel.swift`
- Modify: `/Users/xiakaiyang/Documents/New project/Apps/FocusSessionApp/UI/Plan/PlanDashboardView.swift`

**Step 1: Write minimal implementation**

Add a view-model method that accepts a raw preview percentage, clamps it into `0...100`, rounds to a whole percent, and stores it in `subtaskDraftEstimatedProgressPercent`. In the sheet, render a draggable bar in Estimated mode that updates through that setter while preserving the existing read-only preview for Quantified mode.

**Step 2: Run tests to verify they pass**

Run: `xcodebuild test -project FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/PlanViewModelTests -only-testing:FocusSessionAppTests/PlanDashboardViewSourceTests`
Expected: PASS.
