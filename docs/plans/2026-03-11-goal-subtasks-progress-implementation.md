# Goal Subtasks Progress Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add editable goal subtasks with per-subtask progress and an automatically computed goal-level progress summary in the Plan dashboard.

**Architecture:** Extend the existing `PlanGoal` aggregate with lightweight subtask values, persist the subtask list as encoded data inside `StoredPlanGoal`, and surface computed progress in both the goal editor sheet and the goals list. Keep goal status manual so timeline semantics stay unchanged while progress is derived only from subtasks.

**Tech Stack:** SwiftUI, SwiftData, XCTest, macOS app target

---

### Task 1: Add model and repository coverage

**Files:**
- Modify: `/Users/xiakaiyang/Documents/New project/Tests/FocusSessionAppTests/PlanViewModelTests.swift`
- Modify: `/Users/xiakaiyang/Documents/New project/Tests/FocusSessionAppTests/PlanGoalsRepositoryTests.swift`

**Step 1: Write the failing test**

Add tests that create goals with subtasks, assert the computed progress value, and verify the repository round-trips subtask titles and percentages.

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -project 'FocusSession.xcodeproj' -scheme 'FocusSessionApp' -destination 'platform=macOS' -only-testing:FocusSessionAppTests/PlanViewModelTests -only-testing:FocusSessionAppTests/PlanGoalsRepositoryTests`

Expected: FAIL because `PlanGoal` and persistence do not yet support subtasks.

**Step 3: Write minimal implementation**

Add a `PlanGoalSubtask` value type, extend `PlanGoal`, and update stored-model encode/decode behavior.

**Step 4: Run test to verify it passes**

Run the same command and expect those new tests to pass.

### Task 2: Add composer state and save logic

**Files:**
- Modify: `/Users/xiakaiyang/Documents/New project/Apps/FocusSessionApp/ViewModels/PlanViewModel.swift`
- Modify: `/Users/xiakaiyang/Documents/New project/Apps/FocusSessionApp/Plan/PlanGoal.swift`

**Step 1: Write the failing test**

Add a view-model test that edits a goal, changes subtask progress, saves, and asserts that the saved goal reflects the updated computed progress and cleaned subtask rows.

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -project 'FocusSession.xcodeproj' -scheme 'FocusSessionApp' -destination 'platform=macOS' -only-testing:FocusSessionAppTests/PlanViewModelTests`

Expected: FAIL because the composer has no editable subtask state or helper methods.

**Step 3: Write minimal implementation**

Add `newGoalSubtasks` state plus helper methods to add, remove, sanitize, and save subtasks.

**Step 4: Run test to verify it passes**

Run the same command and expect the view-model suite to pass.

### Task 3: Wire the Plan UI

**Files:**
- Modify: `/Users/xiakaiyang/Documents/New project/Apps/FocusSessionApp/UI/Plan/PlanDashboardView.swift`
- Modify: `/Users/xiakaiyang/Documents/New project/Tests/FocusSessionAppTests/PlanDashboardViewSourceTests.swift`

**Step 1: Write the failing test**

Add source assertions for goal progress labels, progress bars, and the subtask editor section in the goal sheet.

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -project 'FocusSession.xcodeproj' -scheme 'FocusSessionApp' -destination 'platform=macOS' -only-testing:FocusSessionAppTests/PlanDashboardViewSourceTests`

Expected: FAIL because the current Plan dashboard does not mention subtasks or progress UI.

**Step 3: Write minimal implementation**

Render the computed goal progress in each goal row and add the editable subtask section to the goal sheet.

**Step 4: Run test to verify it passes**

Run the same command and expect the source test to pass.

### Task 4: Run focused regression verification

**Files:**
- Verify only

**Step 1: Run focused regression suite**

Run: `xcodebuild test -project 'FocusSession.xcodeproj' -scheme 'FocusSessionApp' -destination 'platform=macOS' -only-testing:FocusSessionAppTests/PlanViewModelTests -only-testing:FocusSessionAppTests/PlanGoalsRepositoryTests -only-testing:FocusSessionAppTests/PlanDashboardViewSourceTests -only-testing:FocusSessionAppTests/PlanTimelinePresentationTests`

Expected: PASS with the usual local CoreSimulator warning but successful macOS tests.

**Step 2: Open the app for manual review**

Run: `open ~/Library/Developer/Xcode/DerivedData/FocusSession-asuyqtyrwrlfddeglbiduexevyme/Build/Products/Debug/TodayFocus.app`

Expected: The app launches and the Plan sheet shows editable subtasks with goal progress reflected in the list.
