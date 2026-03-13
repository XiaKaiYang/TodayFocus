# Goal Subtask Add Affordance Design

## Goal

Remove the plain `+ Add Subtask` button and replace it with a more refined add affordance that feels native to the compact subtask card layout.

## Chosen Approach

Use a dedicated add-subtask tile as the last item in the subtask grid. The tile should match the existing compact card footprint, keep the same soft tinted surface language, and center a stacked-card icon with a plus badge so the action reads as "add another subtask" rather than a generic add button.

## Why This Approach

This keeps the add action inside the visual rhythm of the card row instead of dropping a separate glass button below it. It also makes the affordance easier to scan because it behaves like one more card slot rather than a control bar.

## Empty State

When a goal has no subtasks yet, reuse the same add affordance on the right side of the helper row instead of showing a text button. Keep the explanatory sentence, but let the symbol carry the action.

## Verification

Update the source-level regression test to require the add-subtask tile helper and the new icon composition, and to forbid the old `+ Add Subtask` label. Then run the focused dashboard and view model tests.
