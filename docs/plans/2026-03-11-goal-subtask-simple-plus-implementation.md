# Goal Subtask Simple Plus Implementation Plan

**Goal:** Simplify the add-subtask affordance to a minimal circular plus button.

## Task 1: Update the source regression test

- Modify `Tests/FocusSessionAppTests/PlanDashboardViewSourceTests.swift`.
- Require the new simple add button helper.
- Require the circular plus styling strings.
- Forbid the previous stacked-card icon strings.
- Run the focused source test and confirm it fails first.

## Task 2: Implement the simple plus affordance

- Modify `Apps/FocusSessionApp/UI/Plan/PlanDashboardView.swift`.
- Replace the decorative add tile with a lightweight circular plus button.
- Reuse the same button in both the expanded subtask area and the empty state.
- Keep the create-subtask action unchanged.

## Task 3: Verify

- Run `PlanDashboardViewSourceTests`.
- Run `PlanDashboardViewSourceTests + PlanViewModelTests`.
- Open the rebuilt `TodayFocus.app`.
