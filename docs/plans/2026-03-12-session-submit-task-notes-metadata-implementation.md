# Session Submit Task Completion And Notes Metadata Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make reflection submission complete the selected task and enrich Notes entries with session time plus mood emoji.

**Architecture:** Keep the submit-driven behavior inside `CurrentSessionViewModel`, because it already owns the selected task identity and the task repository. Extend `NotesLibraryEntry` with derived presentation fields so the Notes UI stays declarative and the new metadata is easy to assert in tests.

**Tech Stack:** SwiftUI, SwiftData, XCTest

---

### Task 1: Lock submit-driven task completion in tests

**Files:**
- Modify: `Tests/FocusSessionAppTests/CurrentSessionViewModelTests.swift`
- Reference: `Apps/FocusSessionApp/ViewModels/CurrentSessionViewModel.swift`

**Step 1: Write the failing test**

- Add one test proving `submitReflection()` marks the selected task completed.
- Add one test proving taskless sessions still do not complete any task.
- Reuse in-memory `FocusSessionModelContainer` plus `TasksRepository`.

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -project FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/CurrentSessionViewModelTests`

Expected: FAIL because reflection submit does not yet update tasks.

**Step 3: Write minimal implementation**

- Update `CurrentSessionViewModel` so successful reflection submission completes only the currently selected task.
- Preserve existing recurring-task successor behavior.
- Refresh local available tasks after completion.

**Step 4: Run test to verify it passes**

Run the same focused test command and confirm green.

### Task 2: Lock notes metadata in tests

**Files:**
- Modify: `Tests/FocusSessionAppTests/NotesLibraryViewModelTests.swift`
- Reference: `Apps/FocusSessionApp/ViewModels/NotesLibraryViewModel.swift`

**Step 1: Write the failing test**

- Add expectations for absolute ended-time text and mood emoji on note entries.
- Cover one note with mood and one note without mood.

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -project FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/NotesLibraryViewModelTests`

Expected: FAIL because the note entry model does not yet expose the new metadata.

**Step 3: Write minimal implementation**

- Extend `NotesLibraryEntry` with derived ended-time and mood emoji fields.
- Keep formatting centralized in the view model.

**Step 4: Run test to verify it passes**

Run the same focused test command and confirm green.

### Task 3: Render the new note metadata

**Files:**
- Modify: `Apps/FocusSessionApp/UI/Notes/NotesLibraryView.swift`
- Reference: `Apps/FocusSessionApp/ViewModels/NotesLibraryViewModel.swift`

**Step 1: Add the UI wiring**

- Show the mood emoji in the list row metadata and detail header when present.
- Show the absolute ended-time text next to the existing relative text and duration.

**Step 2: Verify manually and with source-backed tests if needed**

- Reuse `NotesLibraryViewModelTests` for data correctness.
- If the UI needs a source guard, add a lightweight source test instead of snapshot churn.

### Task 4: Final verification

**Files:**
- No additional production files unless fixes are required by test results.

**Step 1: Run targeted suites**

Run:

```bash
xcodebuild test -project FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' \
  -only-testing:FocusSessionAppTests/CurrentSessionViewModelTests \
  -only-testing:FocusSessionAppTests/NotesLibraryViewModelTests
```

**Step 2: Run full suite**

Run:

```bash
xcodebuild test -project FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS'
```

**Step 3: Open the rebuilt app**

Run:

```bash
open '/Users/xiakaiyang/Library/Developer/Xcode/DerivedData/FocusSession-asuyqtyrwrlfddeglbiduexevyme/Build/Products/Debug/TodayFocus.app'
```
