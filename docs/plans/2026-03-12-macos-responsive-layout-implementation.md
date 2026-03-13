# macOS Responsive Layout Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make the macOS app adapt cleanly across smaller and larger screen sizes by removing the most restrictive fixed widths and introducing shared width-tier layout behavior.

**Architecture:** Add one lightweight responsive-width helper that classifies available width into compact, regular, and expanded tiers. Thread that helper through the app shell and the highest-impact pages so each view can choose between stacked and side-by-side layouts without inventing separate UI systems.

**Tech Stack:** SwiftUI, AppKit, XCTest

---

### Task 1: Lock the responsive model in tests

**Files:**
- Modify: `Tests/FocusSessionAppTests/CurrentSessionLayoutTests.swift`
- Create: `Tests/FocusSessionAppTests/ResponsiveLayoutTests.swift`
- Reference: `Apps/FocusSessionApp/UI/CurrentSession/CurrentSessionLayoutMetrics.swift`

**Step 1: Write the failing test**

- Add tests for the shared width-tier helper.
- Add a `CurrentSessionLayoutMetrics` test that proves compact widths tighten hero width and note-editor width compared with regular widths.

**Step 2: Run test to verify it fails**

Run:

```bash
xcodebuild test -project FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' \
  -only-testing:FocusSessionAppTests/CurrentSessionLayoutTests \
  -only-testing:FocusSessionAppTests/ResponsiveLayoutTests
```

Expected: FAIL because the width-tier helper and width-aware metrics do not exist yet.

**Step 3: Write minimal implementation**

- Add the shared responsive-width helper.
- Update `CurrentSessionLayoutMetrics` to accept width-tier input and return narrower values for compact widths.

**Step 4: Run test to verify it passes**

Run the same focused test command and confirm green.

### Task 2: Adapt the shell and window constraints

**Files:**
- Modify: `Apps/FocusSessionApp/FocusSessionApp.swift`
- Modify: `Apps/FocusSessionApp/UI/AppShell/AppShellView.swift`
- Reference: `Apps/FocusSessionApp/UI/AppShell/AppSection.swift`

**Step 1: Write the failing test**

- Add a source-backed test asserting the app minimum window size is reduced from the current `1100x720`.
- Add a source-backed test asserting the shell uses the new responsive helper instead of a single fixed sidebar width.

**Step 2: Run test to verify it fails**

Run:

```bash
xcodebuild test -project FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' \
  -only-testing:FocusSessionAppTests/ResponsiveLayoutTests
```

Expected: FAIL because the app and shell still use fixed window and sidebar constraints.

**Step 3: Write minimal implementation**

- Lower the app minimum window size.
- Make the shell derive sidebar width and detail padding from available width.

**Step 4: Run test to verify it passes**

Run the same focused test command and confirm green.

### Task 3: Make the core detail pages responsive

**Files:**
- Modify: `Apps/FocusSessionApp/UI/CurrentSession/CurrentSessionView.swift`
- Modify: `Apps/FocusSessionApp/UI/CurrentSession/CurrentSessionLayoutMetrics.swift`
- Modify: `Apps/FocusSessionApp/UI/Notes/NotesLibraryView.swift`
- Modify: `Apps/FocusSessionApp/UI/Tasks/TasksDashboardView.swift`
- Modify: `Apps/FocusSessionApp/UI/Plan/PlanDashboardView.swift`
- Modify: `Apps/FocusSessionApp/UI/Analytics/AnalyticsDashboardView.swift`

**Step 1: Write the failing test**

- Add source-backed tests for the most important structural shifts:
  - `Notes` uses a width-aware stacked layout path.
  - `Analytics` conditionally stacks the trend and top-task cards.
  - `Tasks` and `Plan` no longer rely on the key hard-coded composer/card widths.

**Step 2: Run test to verify it fails**

Run:

```bash
xcodebuild test -project FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' \
  -only-testing:FocusSessionAppTests/ResponsiveLayoutTests \
  -only-testing:FocusSessionAppTests/CurrentSessionLayoutTests
```

Expected: FAIL because the current views still use hard-coded widths and fixed split arrangements.

**Step 3: Write minimal implementation**

- Update `CurrentSessionView` so the runtime note composer and reflection overlay width clamp to available space.
- Update `NotesLibraryView` to switch between vertical and horizontal arrangements.
- Update `TasksDashboardView`, `PlanDashboardView`, and `AnalyticsDashboardView` to remove the most brittle fixed widths and allow card wrapping.

**Step 4: Run test to verify it passes**

Run the same focused test command and confirm green.

### Task 4: Final verification

**Files:**
- No additional production files unless test results require a fix.

**Step 1: Run focused suites**

Run:

```bash
xcodebuild test -project FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' \
  -only-testing:FocusSessionAppTests/CurrentSessionLayoutTests \
  -only-testing:FocusSessionAppTests/ResponsiveLayoutTests
```

**Step 2: Run the full suite**

Run:

```bash
xcodebuild test -project FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS'
```

**Step 3: Open the rebuilt app**

Run:

```bash
open '/Users/xiakaiyang/Library/Developer/Xcode/DerivedData/FocusSession-asuyqtyrwrlfddeglbiduexevyme/Build/Products/Debug/TodayFocus.app'
```
