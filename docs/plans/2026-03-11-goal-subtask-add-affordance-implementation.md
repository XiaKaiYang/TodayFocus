# Goal Subtask Add Affordance Implementation Plan

**Goal:** Replace the plain add-subtask button with a card-aligned symbolic affordance.

## Task 1: Lock the new affordance in tests

- Modify `Tests/FocusSessionAppTests/PlanDashboardViewSourceTests.swift`.
- Require a dedicated add-subtask helper in the dashboard source.
- Require the stacked-card icon plus plus-badge composition.
- Forbid the old `+ Add Subtask` label.
- Run the focused source test and confirm it fails first.

## Task 2: Implement the add affordance

- Modify `Apps/FocusSessionApp/UI/Plan/PlanDashboardView.swift`.
- Replace the bottom button in the expanded subtask panel with an add tile appended to the grid.
- Reuse the same affordance in the no-subtask helper row.
- Keep the add action wired to `viewModel.presentCreateSubtaskSheet(for: goal)`.

## Task 3: Verify

- Run `PlanDashboardViewSourceTests`.
- Run `PlanDashboardViewSourceTests + PlanViewModelTests`.
- Open the rebuilt `TodayFocus.app` for visual review.
