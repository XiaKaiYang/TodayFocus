# 2026-03-12 Estimated Subtask Preview Drag Design

## Summary

In the Edit Subtask sheet, make the Automatic Preview progress bar directly draggable only when the subtask tracking mode is Estimated. Dragging updates the same estimated completion draft value that already drives the preview. Quantified mode remains read-only.

## Chosen Approach

Use the existing preview bar location and replace the passive bar with a draggable variant backed by the current estimated progress draft. This keeps the interaction local to the existing sheet and avoids adding duplicate controls.

## Alternatives Considered

1. Keep the bar read-only and add a slider field nearby. Rejected because it adds extra UI and does not match the requested direct manipulation.

2. Make the bar draggable for both Estimated and Quantified. Rejected because Quantified progress is derived from baseline, target, and linked tasks, so dragging would create conflicting sources of truth.

## Data Flow

Dragging computes a clamped 0...100 percentage from the bar width and writes it into the estimated progress draft. The existing preview label, percentage text, and save path continue to use that draft value.

## Testing

Add a view-model test for the new setter that rounds and clamps values. Add a source test confirming the estimated preview path uses a draggable progress bar binding.
