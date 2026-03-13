# Unified Completed Trash Design

## Goal

Move completed tasks and completed goals out of the `Today` and `Plan` home screens and gather them into one dedicated trash destination in the app sidebar.

## Sidebar Layout

Keep the main sidebar focused on active work surfaces. Add a new trash destination to the bottom utility area, and render both trash and settings as icon-only controls so they read as secondary utilities instead of primary work sections.

## Content Ownership

`Today` should show only incomplete tasks. Its embedded trash subsection should be removed entirely. `Plan` should show only goals whose status is not `completed`, including the main goals list and the timeline. Completed goals move into the new trash page.

## Trash Page

Create one dedicated page that shows two sections: completed tasks and completed goals. Each section should handle empty states cleanly and keep restore actions available so completion acts like archive, not irreversible deletion. Permanent delete actions should remain available there as well.

## Data Flow

Tasks already have a completion flag, so the trash page can read from a dedicated completed-task collection in `TasksViewModel`. Goals should gain parallel `activeGoals` and `completedGoals` projections in `PlanViewModel`, while the existing stored `goals` array remains the shared source of truth for editing, deleting, and restoring.

## Verification

Add failing tests first for the new sidebar structure, the removal of Today's inline trash area, and the active-versus-completed goal split. Then implement the minimal UI and view-model changes needed to make those tests pass, followed by focused regression runs for app shell, tasks, and plan behavior.
