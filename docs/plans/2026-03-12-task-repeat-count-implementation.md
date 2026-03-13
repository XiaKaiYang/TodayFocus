# Task Repeat Count Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add finite repeat counts to Today tasks so daily and weekly tasks can stop automatically after a user-defined total number of occurrences.

**Architecture:** Extend the task domain model and SwiftData storage with optional repeat count fields, wire the task composer to collect and validate the count, and update recurring successor generation so completion decrements the remaining count until the series ends. Surface the remaining count in Today task rows.

**Tech Stack:** SwiftUI, SwiftData, XCTest

---

### Task 1: Add failing persistence and behavior tests

**Files:**
- Modify: `/Users/xiakaiyang/Documents/New project/Tests/FocusSessionAppTests/TasksRepositoryTests.swift`
- Modify: `/Users/xiakaiyang/Documents/New project/Tests/FocusSessionAppTests/TasksViewModelTests.swift`
- Modify: `/Users/xiakaiyang/Documents/New project/Tests/FocusSessionAppTests/PlanDashboardViewSourceTests.swift` or a task source test file if needed

**Step 1: Write failing tests**

- Add a repository round-trip test for `repeatTotalCount` and `repeatRemainingCount`.
- Add a view model save test for finite repeat counts from the composer.
- Add a completion test asserting the final occurrence does not spawn a successor.
- Add a source/UI regression test asserting Today tasks render repeat count text.

**Step 2: Run the targeted tests to verify they fail**

Run:
```bash
xcodebuild test -project FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/TasksRepositoryTests -only-testing:FocusSessionAppTests/TasksViewModelTests
```

Expected: failures because the new repeat count fields and UI are not implemented yet.

### Task 2: Add repeat count fields to the task model and storage

**Files:**
- Modify: `/Users/xiakaiyang/Documents/New project/Apps/FocusSessionApp/Tasks/FocusTask.swift`
- Modify: `/Users/xiakaiyang/Documents/New project/Apps/FocusSessionApp/Data/StoredTask.swift`

**Step 1: Add optional count fields**

- Add `repeatTotalCount` and `repeatRemainingCount` to `FocusTask`.
- Add matching stored properties to `StoredTask`.
- Update model conversion and mutation methods so old tasks still decode cleanly with `nil` counts.

**Step 2: Run targeted persistence tests**

Run:
```bash
xcodebuild test -project FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/TasksRepositoryTests
```

Expected: the round-trip test passes.

### Task 3: Collect and validate repeat count in the task composer

**Files:**
- Modify: `/Users/xiakaiyang/Documents/New project/Apps/FocusSessionApp/ViewModels/TasksViewModel.swift`
- Modify: `/Users/xiakaiyang/Documents/New project/Apps/FocusSessionApp/UI/Tasks/TasksDashboardView.swift`

**Step 1: Add composer state**

- Add a published string/int-backed draft for the repeat count.
- Reset it in `resetComposer()`, populate it in `presentEditSheet(for:)`, and clear it when repeat mode is `none`.

**Step 2: Validate and save**

- Parse the repeat count only when `repeatRule != .none`.
- Reject non-integer or values below `1`.
- Save `repeatTotalCount` and `repeatRemainingCount` with the same initial value.

**Step 3: Render the input**

- Show a `Repeat count` input below `Repeat` whenever the rule is daily or weekly.

**Step 4: Run targeted composer tests**

Run:
```bash
xcodebuild test -project FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/TasksViewModelTests
```

Expected: composer tests pass.

### Task 4: Stop recurring successors after the last occurrence

**Files:**
- Modify: `/Users/xiakaiyang/Documents/New project/Apps/FocusSessionApp/Data/Repositories/TasksRepository.swift`

**Step 1: Update successor generation**

- Preserve the current infinite-repeat behavior when the count is `nil`.
- For finite repeats, decrement `repeatRemainingCount` on the successor.
- Return `nil` when the current occurrence is the last one.

**Step 2: Verify recurrence behavior**

Run:
```bash
xcodebuild test -project FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/TasksViewModelTests/testCompletingDailyRepeatingTaskCreatesHiddenSuccessorForNextMorning -only-testing:FocusSessionAppTests/TasksViewModelTests/testCompletingWeeklyRepeatingTaskCreatesSuccessorOnSelectedWeekdayMorning
```

Expected: successor tests still pass, plus the new final-occurrence test passes.

### Task 5: Show repeat counts in Today tasks

**Files:**
- Modify: `/Users/xiakaiyang/Documents/New project/Apps/FocusSessionApp/UI/Tasks/TasksDashboardView.swift`
- Modify: `/Users/xiakaiyang/Documents/New project/Tests/FocusSessionAppTests/TextContrastAuditTests.swift` or another source test file

**Step 1: Add display helper**

- Render a secondary metadata line for repeating tasks.
- Show `Daily · N left` or `Weekly · Friday · N left` for finite repeats.
- Show only cadence text for infinite repeats.

**Step 2: Verify UI/source tests**

Run:
```bash
xcodebuild test -project FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/TextContrastAuditTests
```

Expected: the new source assertion passes.

### Task 6: Run the full regression suite

**Files:**
- No source changes required

**Step 1: Run all tests**

Run:
```bash
xcodebuild test -project FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS'
```

Expected: all tests pass.
