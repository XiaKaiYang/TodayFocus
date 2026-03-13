# Goal Subtask Bar Width Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Keep the overall goal progress bar full width while making subtask progress bars narrower.

**Architecture:** Keep the full-width `goalProgressSummary` structure introduced in the previous layout refactor. Add a local maximum width to `goalSubtaskSummaryRow`, then lock the intended structure with a source assertion before running the focused plan regression suite.

**Tech Stack:** SwiftUI, XCTest

---

### Task 1: Add the failing bar-width regression test

**Files:**
- Modify: `Tests/FocusSessionAppTests/PlanDashboardViewSourceTests.swift`

**Step 1: Write the failing test**

Require the source to include a narrower `goalSubtaskSummaryRow` width constraint, such as `.frame(maxWidth: 360, alignment: .leading)`.

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -project FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/PlanDashboardViewSourceTests`

Expected: FAIL because subtask rows still expand to the full available width.

### Task 2: Implement the subtask row width constraint

**Files:**
- Modify: `Apps/FocusSessionApp/UI/Plan/PlanDashboardView.swift`

**Step 1: Write minimal implementation**

Apply a leading-aligned maximum width constraint directly to `goalSubtaskSummaryRow` so subtask bars stop at a compact width while the overall progress bar remains full width.

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
