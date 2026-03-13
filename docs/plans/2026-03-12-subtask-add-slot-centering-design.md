# 2026-03-12 Subtask Add Slot Centering Design

## Summary

The large add-subtask placeholder in the subtask grid is still appearing too high even after the plus glyph itself was optically centered. The root cause is that the grid row is top-aligned, so the add button is pinned to the top of a taller row whenever neighboring subtask cards are taller.

## Chosen Approach

Keep the existing add button appearance and center only its slot occupancy. Wrap the add button in a vertically flexible container so the button stays centered within the full grid cell height while neighboring cards continue to align naturally.

## Alternatives Considered

1. Keep adjusting the plus glyph offset. Rejected because the screenshot shows the whole button is too high, not just the symbol.

2. Turn the placeholder into a full-height add card. Rejected because that changes the visual style more than needed for this bug.

## Data Flow

This is a view-only layout fix inside `PlanDashboardView`. It does not affect subtask ordering, persistence, or button actions.

## Testing

Add a source assertion that the add-subtask grid slot uses a vertically flexible wrapper with spacers around `goalAddSubtaskButton(for: goal)`. Re-run the focused dashboard and view-model tests after the implementation.
