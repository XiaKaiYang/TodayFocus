# 2026-03-12 Subtask Plus Optical Centering Design

## Summary

The `+` glyph inside the plan dashboard's subtask add buttons appears visually too high even though the button frames themselves are centered. Adjust the glyph with a small shared optical-centering helper so both plus-button variants look centered without changing their size or surrounding circle treatment.

## Chosen Approach

Replace the two inline `Image(systemName: "plus")` definitions with a shared helper that applies the existing font and tint plus a tiny downward offset. This keeps the button chrome unchanged while making the symbol visually centered in both the large add card and the subtask-card action button.

## Alternatives Considered

1. Add separate manual offsets at each call site. Rejected because the two buttons can drift apart again as styles evolve.

2. Resize the circles or the symbol instead of offsetting it. Rejected because the problem is optical centering, not scale.

## Data Flow

This is a view-only polish change. No model data, persistence, or interaction logic changes.

## Testing

Add a source test that requires a shared centered-plus helper and verifies both button call sites use it. Re-run the focused dashboard source and view-model test suite after the implementation.
