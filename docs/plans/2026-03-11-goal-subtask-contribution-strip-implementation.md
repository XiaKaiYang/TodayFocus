# Goal Subtask Contribution Strip Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the expanded subtask grid with a single-row contribution strip whose combined fill corresponds to the main overall progress bar.

**Architecture:** Keep the existing overall progress summary and expand/collapse interaction. Refactor the expanded subtask area into a labels row plus a single geometry-driven segmented contribution bar, then verify the new structure with source assertions before running the focused plan regression suite.

**Tech Stack:** SwiftUI, XCTest

---

### Task 1: Add the failing contribution-strip regression test

**Files:**
- Modify: `Tests/FocusSessionAppTests/PlanDashboardViewSourceTests.swift`

**Step 1: Write the failing test**

Require the source to include `goalSubtaskSegmentLabels`, `goalSubtaskContributionBar`, and the segment-width calculation, while rejecting the old grid helper and `LazyVGrid`.

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -project FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/PlanDashboardViewSourceTests`

Expected: FAIL because the panel still uses the older grid-based layout.

### Task 2: Implement the contribution strip

**Files:**
- Modify: `Apps/FocusSessionApp/UI/Plan/PlanDashboardView.swift`

**Step 1: Write minimal implementation**

Refactor the expanded subtask panel into a leading-aligned `VStack` that renders an equal-width labels row and a geometry-based segmented contribution bar. Remove the grid helper and the old per-subtask row layout.

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
