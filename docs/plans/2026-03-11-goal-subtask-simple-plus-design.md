# Goal Subtask Simple Plus Design

## Goal

Reduce visual noise in the add-subtask affordance and keep only a clean, attractive plus symbol.

## Chosen Approach

Replace the current decorative add tile with a small circular plus button. Keep it status-tinted so it still belongs to the goal card, but remove the stacked-card icon, dashed outline, and large tile surface.

## Placement

Inside the expanded subtask area, keep the add action at the trailing end of the row by rendering it as the final lightweight grid item. In the empty state, reuse the same plus button at the right side of the helper row.

## Verification

Update the source-level regression test to require the simple add button helper and the circular plus styling, and to forbid the stacked-card icon treatment. Then run the focused dashboard and view model tests.
