# Goal Subtask Two Column Grid Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Show expanded goal subtasks in a two-column grid while keeping the overall progress bar full width.

**Architecture:** Keep the full-width `goalProgressSummary` and the narrowed `goalSubtaskSummaryRow`. Replace the single-column expansion panel with a `LazyVGrid` backed by a dedicated two-column `GridItem` helper, then verify the change with a source test and the focused plan regression suite.

**Tech Stack:** SwiftUI, XCTest

---

### Task 1: Add the failing two-column regression test

**Files:**
- Modify: `Tests/FocusSessionAppTests/PlanDashboardViewSourceTests.swift`

**Step 1: Write the failing test**

Require the source to include `goalSubtaskGridColumns` and `LazyVGrid(columns: goalSubtaskGridColumns` in the subtask expansion panel.

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -project FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/PlanDashboardViewSourceTests`

Expected: FAIL because the panel still uses a single-column `VStack`.

### Task 2: Implement the two-column subtask grid

**Files:**
- Modify: `Apps/FocusSessionApp/UI/Plan/PlanDashboardView.swift`

**Step 1: Write minimal implementation**

Add a `goalSubtaskGridColumns` helper with two flexible columns and swap `goalSubtasksExpansionPanel` to a `LazyVGrid` that renders the existing `goalSubtaskSummaryRow`.

**Step 2: Run test to verify it passes**

Run: `xcodebuild test -project FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/PlanDashboardViewSourceTests`

Expected: PASS

### Task 3: Run focused regression verification

**Files:**
- Test: `Tests/FocusSessionAppTests/PlanViewModelTests.swift`
- Test: `Tests/FocusSessionAppTests/PlanGoalsRepositoryTests.swift`
- Test: `Tests/FocusSessionAppTests/PlanDashboardViewSourceTests.swift`
- Test: `Tests/FocusSessionAppTests/PlanTimelinePresentationTests.swift`

**Step 1: Run focused regression tests**

Run: `xcodebuild test -project FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/PlanViewModelTests -only-testing:FocusSessionAppTests/PlanGoalsRepositoryTests -only-testing:FocusSessionAppTests/PlanDashboardViewSourceTests -only-testing:FocusSessionAppTests/PlanTimelinePresentationTests`

Expected: PASS
