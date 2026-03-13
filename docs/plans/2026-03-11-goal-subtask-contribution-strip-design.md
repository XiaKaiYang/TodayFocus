# Goal Subtask Contribution Strip Design

## Goal

Show expanded subtasks on a single horizontal line and make their combined visual progress correspond directly to the main goal progress bar above.

## Root Cause

The current two-column subtask layout is denser than the old vertical stack, but it still presents each subtask as an isolated mini-bar. That wastes the additive relationship between subtask progress and the automatically computed overall progress, so the user still has to mentally combine separate pieces.

## Chosen Approach

Replace the grid of subtask mini-bars with a single contribution strip. The expanded area will contain one horizontal labels row with equal-width cells for every subtask, followed by one continuous segmented bar. Each segment occupies an equal share of the full width and fills according to that subtask's progress, so the total filled length across all segments matches the overall progress bar above when the overall progress is the average of subtask percentages.

## Why This Approach

This makes the relationship between subtask progress and overall progress immediately legible. It also reduces vertical clutter while preserving per-subtask detail through titles and percentages in the same horizontal reading flow.

## Verification

Add a source regression test that requires the expansion panel to use dedicated subtask segment label and contribution bar helpers, and removes the previous grid-based layout assertions. Then run the focused plan test suite to confirm the view change does not affect goal data or timeline behavior.
