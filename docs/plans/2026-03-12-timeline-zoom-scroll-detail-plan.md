# Timeline Zoom Scroll Detail Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a horizontal scrollbar for zoomed gantt timelines and show denser intermediate axis ticks when the visible month span is small.

**Architecture:** Keep `PlanViewModel.visibleWindow` as the only source of truth for the active date window, and make the view responsible for rendering that window at a variable physical width. Add presentation helpers for zoom-detail width and tick density, wrap the chart in a horizontal `ScrollView`, and update the AppKit zoom overlay so horizontal-dominant wheel gestures still reach the scroll view.

**Tech Stack:** SwiftUI, Charts, AppKit event monitoring, XCTest source assertions, focused `xcodebuild` test runs.

---

### Task 1: Lock in zoom-detail helpers with failing tests

**Files:**
- Modify: `/Users/xiakaiyang/Documents/New project/Tests/FocusSessionAppTests/PlanTimelinePresentationTests.swift`

**Step 1: Write the failing tests**

Add tests for:
- `PlanTimelinePresentation.chartContentWidthMultiplier(forVisibleMonthSpan:)` returning:
  - `12 -> 1.0`
  - `6 -> 1.6`
  - `3 -> 2.2`
  - `1 -> 3.2`
- `PlanTimelinePresentation.axisDetailLevel(forVisibleMonthSpan:)` returning:
  - `12 -> .monthsOnly`
  - `6 -> .monthsAndWeeks`
  - `3 -> .monthsAndWeeks`
  - `1 -> .monthsWeeksAndDays`

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -project /Users/xiakaiyang/Documents/New\ project/FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/PlanTimelinePresentationTests`

Expected: FAIL because the new helper API and detail-level type do not exist yet.

### Task 2: Lock in view wiring and scroll behavior with failing tests

**Files:**
- Modify: `/Users/xiakaiyang/Documents/New project/Tests/FocusSessionAppTests/PlanDashboardViewSourceTests.swift`
- Modify: `/Users/xiakaiyang/Documents/New project/Tests/FocusSessionAppTests/TimelineZoomInteractionGateTests.swift`

**Step 1: Write the failing source assertions**

Require `PlanDashboardView.swift` to:
- wrap the chart in `ScrollView(.horizontal, showsIndicators: true)`
- compute chart width from a dedicated content-width helper instead of the fixed card width
- use a dedicated axis-detail helper inside `chartXAxis`

**Step 2: Write the failing interaction-routing tests**

Add a small pure helper, such as `TimelineZoomScrollRouting`, and test that:
- vertical-dominant deltas route to zoom
- horizontal-dominant deltas route to scrolling
- zero movement routes to pass-through

**Step 3: Run tests to verify they fail**

Run: `xcodebuild test -project /Users/xiakaiyang/Documents/New\ project/FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/PlanDashboardViewSourceTests -only-testing:FocusSessionAppTests/TimelineZoomInteractionGateTests`

Expected: FAIL because the scroll container, routing helper, and axis-detail wiring are not implemented yet.

### Task 3: Add the minimal presentation helpers

**Files:**
- Modify: `/Users/xiakaiyang/Documents/New project/Apps/FocusSessionApp/Plan/PlanGoal.swift`

**Step 1: Write minimal implementation**

Add:
- `enum PlanTimelineAxisDetailLevel { case monthsOnly, monthsAndWeeks, monthsWeeksAndDays }`
- `static func chartContentWidthMultiplier(forVisibleMonthSpan:) -> CGFloat`
- `static func axisDetailLevel(forVisibleMonthSpan:) -> PlanTimelineAxisDetailLevel`

Use exactly the values from Task 1 and keep the existing month-label and height helpers unchanged.

**Step 2: Run helper tests to verify they pass**

Run: `xcodebuild test -project /Users/xiakaiyang/Documents/New\ project/FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/PlanTimelinePresentationTests`

Expected: PASS

### Task 4: Implement the horizontal scrollable chart container

**Files:**
- Modify: `/Users/xiakaiyang/Documents/New project/Apps/FocusSessionApp/UI/Plan/PlanDashboardView.swift`

**Step 1: Refactor the chart card to measure viewport width**

Wrap the timeline card body in a `GeometryReader` or equivalent local measurement so the visible card width is available.

**Step 2: Wrap the chart in a horizontal scroll view**

Render:
- outer card container
- `ScrollView(.horizontal, showsIndicators: true)`
- inner chart with width `max(viewportWidth, viewportWidth * multiplier)`

Use `PlanTimelinePresentation.chartContentWidthMultiplier(forVisibleMonthSpan: viewModel.visibleMonthSpanForPresentation)` or an equivalent read-only helper from the view model so the width reacts to zoom level.

**Step 3: Preserve the current card appearance**

Keep:
- the rounded card surface
- the clipping
- the vertical sizing rules
- the today rule and existing bar rendering

Only move the background/clipping to the scroll container level so the scrollbar visually belongs to the gantt card.

**Step 4: Run the source test to verify it passes**

Run: `xcodebuild test -project /Users/xiakaiyang/Documents/New\ project/FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/PlanDashboardViewSourceTests`

Expected: PASS

### Task 5: Implement the denser axis gridlines

**Files:**
- Modify: `/Users/xiakaiyang/Documents/New project/Apps/FocusSessionApp/UI/Plan/PlanDashboardView.swift`

**Step 1: Replace the single-axis implementation with conditional layers**

Keep the current month label layer. Add:
- weekly gridline/tick layer when detail level is `.monthsAndWeeks` or `.monthsWeeksAndDays`
- every-3-days gridline/tick layer when detail level is `.monthsWeeksAndDays`

Do not add extra text labels to the new layers. Use lighter opacity than the month gridlines so month marks remain the dominant reference.

**Step 2: Run timeline presentation and source tests**

Run: `xcodebuild test -project /Users/xiakaiyang/Documents/New\ project/FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/PlanTimelinePresentationTests -only-testing:FocusSessionAppTests/PlanDashboardViewSourceTests`

Expected: PASS

### Task 6: Let horizontal wheel gestures pass through the zoom gate

**Files:**
- Modify: `/Users/xiakaiyang/Documents/New project/Apps/FocusSessionApp/UI/Plan/PlanDashboardView.swift`
- Modify: `/Users/xiakaiyang/Documents/New project/Tests/FocusSessionAppTests/TimelineZoomInteractionGateTests.swift`

**Step 1: Add the minimal routing helper**

Create a small pure helper that decides whether a scroll event should:
- trigger zoom
- pass through for normal scrolling

Route to zoom only when the zoom gate is active and `abs(deltaY) > abs(deltaX)`.

**Step 2: Update the AppKit event monitor**

Inside `TimelineZoomTrackingView`, use the routing helper so:
- vertical-dominant wheel input still calls `onScroll`
- horizontal-dominant wheel input returns the original event to the surrounding scroll view

**Step 3: Run the routing tests**

Run: `xcodebuild test -project /Users/xiakaiyang/Documents/New\ project/FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/TimelineZoomInteractionGateTests`

Expected: PASS

### Task 7: Add the smallest view-model read-only hook needed by the view

**Files:**
- Modify: `/Users/xiakaiyang/Documents/New project/Apps/FocusSessionApp/ViewModels/PlanViewModel.swift`
- Modify: `/Users/xiakaiyang/Documents/New project/Tests/FocusSessionAppTests/PlanViewModelTests.swift`

**Step 1: Expose the visible month span for presentation**

Add a read-only property dedicated to the view layer, for example `visibleMonthSpanForPresentation`, that returns the current visible month span without changing zoom behavior.

**Step 2: Keep all existing zoom window behavior unchanged**

Do not change:
- zoom step values
- anchor selection
- shift/jump logic

**Step 3: Run focused view-model tests**

Run: `xcodebuild test -project /Users/xiakaiyang/Documents/New\ project/FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/PlanViewModelTests`

Expected: PASS

### Task 8: Run focused regression verification

**Files:**
- Test: `/Users/xiakaiyang/Documents/New project/Tests/FocusSessionAppTests/PlanDashboardViewSourceTests.swift`
- Test: `/Users/xiakaiyang/Documents/New project/Tests/FocusSessionAppTests/PlanTimelinePresentationTests.swift`
- Test: `/Users/xiakaiyang/Documents/New project/Tests/FocusSessionAppTests/TimelineZoomInteractionGateTests.swift`
- Test: `/Users/xiakaiyang/Documents/New project/Tests/FocusSessionAppTests/PlanViewModelTests.swift`
- Test: `/Users/xiakaiyang/Documents/New project/Tests/FocusSessionAppTests/PlanGoalsRepositoryTests.swift`

**Step 1: Run the full focused suite**

Run: `xcodebuild test -project /Users/xiakaiyang/Documents/New\ project/FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/PlanDashboardViewSourceTests -only-testing:FocusSessionAppTests/PlanTimelinePresentationTests -only-testing:FocusSessionAppTests/TimelineZoomInteractionGateTests -only-testing:FocusSessionAppTests/PlanViewModelTests -only-testing:FocusSessionAppTests/PlanGoalsRepositoryTests`

Expected: PASS

### Assumption

This repository currently has no initial git commit, so the normal worktree setup required by the workflow cannot be created yet. Execute the plan in the current workspace unless the repository is initialized first.
