# Goal Subtask Expansion Anchor Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make goal subtasks expand from the chevron side of the progress summary instead of from the full summary block.

**Architecture:** Keep the goal row structure intact, but extract the expanded subtask content into a trailing-aligned panel helper. Lock the intended animation structure with a source test first, then replace the old top-edge move transition with a `.topTrailing` anchored reveal.

**Tech Stack:** SwiftUI, XCTest

---

### Task 1: Add the failing expansion-anchor regression test

**Files:**
- Modify: `Tests/FocusSessionAppTests/PlanDashboardViewSourceTests.swift`

**Step 1: Write the failing test**

Add source assertions that require a dedicated `goalSubtasksExpansionPanel` helper, a `.frame(maxWidth: .infinity, alignment: .trailing)` container, and an `anchor: .topTrailing` transition, while rejecting the old `.transition(.opacity.combined(with: .move(edge: .top)))` implementation.

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -project FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/PlanDashboardViewSourceTests`

Expected: FAIL because the old expansion still uses the full-width top-edge move transition.

### Task 2: Implement the trailing expansion panel

**Files:**
- Modify: `Apps/FocusSessionApp/UI/Plan/PlanDashboardView.swift`

**Step 1: Write minimal implementation**

Extract the expanded subtask rows into a `goalSubtasksExpansionPanel` helper. Place that helper inside a full-width trailing-aligned container below the progress summary and apply an opacity-plus-scale transition anchored at `.topTrailing`.

**Step 2: Run test to verify it passes**

Run: `xcodebuild test -project FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/PlanDashboardViewSourceTests`

Expected: PASS

### Task 3: Run focused regression verification

**Files:**
- Test: `Tests/FocusSessionAppTests/PlanDashboardViewSourceTests.swift`
- Test: `Tests/FocusSessionAppTests/PlanViewModelTests.swift`
- Test: `Tests/FocusSessionAppTests/PlanGoalsRepositoryTests.swift`
- Test: `Tests/FocusSessionAppTests/PlanTimelinePresentationTests.swift`

**Step 1: Run focused regression tests**

Run: `xcodebuild test -project FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/PlanViewModelTests -only-testing:FocusSessionAppTests/PlanGoalsRepositoryTests -only-testing:FocusSessionAppTests/PlanDashboardViewSourceTests -only-testing:FocusSessionAppTests/PlanTimelinePresentationTests`

Expected: PASS
