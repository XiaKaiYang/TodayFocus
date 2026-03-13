# Plan Dashboard Polish Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Polish linked-task actions, add subtask left/right context-menu movement, and separate the timeline bars from month labels.

**Architecture:** Keep all changes inside the existing plan dashboard surface. Add focused source and view-model tests first, then implement the new button label helper, adjacent subtask move methods, and chart spacing adjustment with minimal surface-area changes.

**Tech Stack:** SwiftUI, Swift Charts, SwiftData repositories, XCTest.

---

### Task 1: Lock the new dashboard polish behavior with failing tests

**Files:**
- Modify: `/Users/xiakaiyang/Documents/New project/Tests/FocusSessionAppTests/PlanDashboardViewSourceTests.swift`
- Modify: `/Users/xiakaiyang/Documents/New project/Tests/FocusSessionAppTests/PlanViewModelTests.swift`

**Step 1: Write the failing test**

Add source assertions for a custom linked-task action label helper, new context-menu entries `Move Left` and `Move Right`, and extra chart bottom padding. Add view-model tests that verify adjacent subtask swaps when moving left and right.

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -project FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/PlanViewModelTests -only-testing:FocusSessionAppTests/PlanDashboardViewSourceTests`

Expected: FAIL because the source tokens and adjacent move helpers do not exist yet.

### Task 2: Implement the three UI improvements with minimal code

**Files:**
- Modify: `/Users/xiakaiyang/Documents/New project/Apps/FocusSessionApp/UI/Plan/PlanDashboardView.swift`
- Modify: `/Users/xiakaiyang/Documents/New project/Apps/FocusSessionApp/ViewModels/PlanViewModel.swift`

**Step 1: Write minimal implementation**

Add adjacent subtask move helpers to the view model. Extend the card context menu to show `Move Left` and `Move Right` only when a neighboring card exists. Replace the plain linked-task button labels with a richer helper label view that keeps `NewT` and `LinkT` but adds stronger visual hierarchy. Increase the chart plot bottom spacing to open up the gap above month labels.

**Step 2: Run tests to verify they pass**

Run: `xcodebuild test -project FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/PlanViewModelTests -only-testing:FocusSessionAppTests/PlanDashboardViewSourceTests`

Expected: PASS.
