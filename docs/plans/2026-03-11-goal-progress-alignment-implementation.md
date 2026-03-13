# Goal Progress Alignment Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Remove excessive subtask indentation and let the overall progress bar span the full goal card content width.

**Architecture:** Refactor `goalRow` so the metadata/actions sit in a top row and the progress summary sits beneath it as a full-width section. Update the subtask expansion panel to use leading alignment across the available width while preserving the `.topTrailing` animation anchor. Lock the structure with a source test before touching production code.

**Tech Stack:** SwiftUI, XCTest

---

### Task 1: Add the failing alignment regression test

**Files:**
- Modify: `Tests/FocusSessionAppTests/PlanDashboardViewSourceTests.swift`

**Step 1: Write the failing test**

Require a `goalPrimaryDetails` helper in the goal row, require a leading-aligned full-width expansion panel, and reject the old narrow trailing panel constraints.

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -project FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/PlanDashboardViewSourceTests`

Expected: FAIL because the current goal row still keeps progress inside the left metadata column and the subtask panel still uses the old trailing layout.

### Task 2: Implement the goal row layout refactor

**Files:**
- Modify: `Apps/FocusSessionApp/UI/Plan/PlanDashboardView.swift`

**Step 1: Write minimal implementation**

Extract the primary goal text content into a helper, move `goalProgressSummary` below the top row in a full-width content stack, and update `goalSubtasksExpansionPanel` to use full-width leading alignment instead of a narrow trailing frame.

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
