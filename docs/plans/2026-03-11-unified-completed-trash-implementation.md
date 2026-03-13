# Unified Completed Trash Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a unified trash page for completed tasks and goals, move both item types out of Today and Plan, and convert the sidebar footer to icon-only trash/settings controls.

**Architecture:** Keep `TasksViewModel` and `PlanViewModel` as the shared data sources, but expose explicit active/completed collections so active screens can filter cleanly and the new trash dashboard can reuse the same state. Route the new trash section through `AppShellView`, remove Today's inline trash block, and introduce a dedicated `TrashDashboardView` for completed content.

**Tech Stack:** SwiftUI, SwiftData, XCTest

---

### Task 1: Lock the new navigation and archive behavior in tests

**Files:**
- Modify: `/Users/xiakaiyang/Documents/New project/Tests/FocusSessionAppTests/AppShellViewModelTests.swift`
- Modify: `/Users/xiakaiyang/Documents/New project/Tests/FocusSessionAppTests/TasksViewModelTests.swift`
- Modify: `/Users/xiakaiyang/Documents/New project/Tests/FocusSessionAppTests/PlanViewModelTests.swift`
- Create: `/Users/xiakaiyang/Documents/New project/Tests/FocusSessionAppTests/TrashDashboardViewSourceTests.swift`

**Step 1: Write the failing tests**

- Update app-shell source assertions to require a `.trash` section, an icon-only footer area for trash/settings, and routing into `TrashDashboardView`.
- Update task tests to require a `completedTasks` collection instead of Today-owned trash UI semantics.
- Add a plan test that proves completed goals are excluded from active collections and exposed through `completedGoals`.
- Add a source-level test for the new trash dashboard that requires completed task and completed goal sections plus restore/delete affordances.

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -project FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/AppShellViewModelTests -only-testing:FocusSessionAppTests/TasksViewModelTests -only-testing:FocusSessionAppTests/PlanViewModelTests -only-testing:FocusSessionAppTests/TrashDashboardViewSourceTests`

Expected: FAIL because the sidebar still has no trash section, Today still renders inline trash, Plan still exposes completed goals, and the trash dashboard does not exist.

### Task 2: Implement the shared completed-item data projections

**Files:**
- Modify: `/Users/xiakaiyang/Documents/New project/Apps/FocusSessionApp/ViewModels/TasksViewModel.swift`
- Modify: `/Users/xiakaiyang/Documents/New project/Apps/FocusSessionApp/ViewModels/PlanViewModel.swift`
- Test: `/Users/xiakaiyang/Documents/New project/Tests/FocusSessionAppTests/TasksViewModelTests.swift`
- Test: `/Users/xiakaiyang/Documents/New project/Tests/FocusSessionAppTests/PlanViewModelTests.swift`

**Step 1: Write minimal implementation**

- Replace the old completed-task trash projection with an explicit `completedTasks` collection.
- Add `activeGoals` and `completedGoals` projections to `PlanViewModel`.
- Make `timelineGoals` derive only from active goals.

**Step 2: Run tests to verify they pass**

Run: `xcodebuild test -project FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/TasksViewModelTests -only-testing:FocusSessionAppTests/PlanViewModelTests`

Expected: PASS

### Task 3: Implement the sidebar and screen routing changes

**Files:**
- Modify: `/Users/xiakaiyang/Documents/New project/Apps/FocusSessionApp/UI/AppShell/AppSection.swift`
- Modify: `/Users/xiakaiyang/Documents/New project/Apps/FocusSessionApp/UI/AppShell/AppShellView.swift`
- Create: `/Users/xiakaiyang/Documents/New project/Apps/FocusSessionApp/UI/Trash/TrashDashboardView.swift`
- Test: `/Users/xiakaiyang/Documents/New project/Tests/FocusSessionAppTests/AppShellViewModelTests.swift`
- Test: `/Users/xiakaiyang/Documents/New project/Tests/FocusSessionAppTests/TrashDashboardViewSourceTests.swift`

**Step 1: Write minimal implementation**

- Add the `.trash` app section and its symbol/title metadata.
- Split the sidebar into primary navigation and icon-only footer utilities for trash and settings.
- Route `.trash` into a new `TrashDashboardView` that receives the shared tasks and plan view models.

**Step 2: Run tests to verify they pass**

Run: `xcodebuild test -project FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/AppShellViewModelTests -only-testing:FocusSessionAppTests/TrashDashboardViewSourceTests`

Expected: PASS

### Task 4: Remove Today trash and filter Plan to active goals only

**Files:**
- Modify: `/Users/xiakaiyang/Documents/New project/Apps/FocusSessionApp/UI/Tasks/TasksDashboardView.swift`
- Modify: `/Users/xiakaiyang/Documents/New project/Apps/FocusSessionApp/UI/Plan/PlanDashboardView.swift`
- Test: `/Users/xiakaiyang/Documents/New project/Tests/FocusSessionAppTests/TrashDashboardViewSourceTests.swift`
- Test: `/Users/xiakaiyang/Documents/New project/Tests/FocusSessionAppTests/PlanDashboardViewSourceTests.swift`

**Step 1: Write minimal implementation**

- Remove the inline trash section from `TasksDashboardView`.
- Switch `PlanDashboardView` to `activeGoals` for the goal list and active-only timeline copy/empty states.

**Step 2: Run tests to verify they pass**

Run: `xcodebuild test -project FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/TrashDashboardViewSourceTests -only-testing:FocusSessionAppTests/PlanDashboardViewSourceTests`

Expected: PASS

### Task 5: Run focused regression verification

**Files:**
- Test: `/Users/xiakaiyang/Documents/New project/Tests/FocusSessionAppTests/AppShellViewModelTests.swift`
- Test: `/Users/xiakaiyang/Documents/New project/Tests/FocusSessionAppTests/TasksViewModelTests.swift`
- Test: `/Users/xiakaiyang/Documents/New project/Tests/FocusSessionAppTests/PlanViewModelTests.swift`
- Test: `/Users/xiakaiyang/Documents/New project/Tests/FocusSessionAppTests/TrashDashboardViewSourceTests.swift`
- Test: `/Users/xiakaiyang/Documents/New project/Tests/FocusSessionAppTests/PlanDashboardViewSourceTests.swift`

**Step 1: Run the full focused regression suite**

Run: `xcodebuild test -project FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/AppShellViewModelTests -only-testing:FocusSessionAppTests/TasksViewModelTests -only-testing:FocusSessionAppTests/PlanViewModelTests -only-testing:FocusSessionAppTests/TrashDashboardViewSourceTests -only-testing:FocusSessionAppTests/PlanDashboardViewSourceTests`

Expected: PASS

**Step 2: Open the rebuilt app**

Run: `open '/Users/xiakaiyang/Library/Developer/Xcode/DerivedData/FocusSession-asuyqtyrwrlfddeglbiduexevyme/Build/Products/Debug/TodayFocus.app'`

Expected: The sidebar footer shows icon-only trash/settings controls, Today no longer embeds trash, Plan hides completed goals, and the trash page shows both completed sections.
