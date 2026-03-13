# Goal Subtask Two Column Grid Design

## Goal

Make expanded goal subtasks use a denser two-column layout so two subtasks can sit on the same row, while preserving the full-width overall progress bar and the narrower secondary subtask bars.

## Root Cause

The current subtask expansion panel is still a single vertical `VStack`, so every subtask consumes a full row even though each subtask bar is intentionally narrower than the main goal progress bar. That creates unnecessary vertical whitespace in the goals list.

## Chosen Approach

Replace the single-column subtask `VStack` with a two-column `LazyVGrid`. Each subtask keeps the same internal layout and width cap, but the panel now flows items in pairs across the available width. Odd counts will naturally wrap onto the next row with the final item left-aligned.

## Why This Approach

This directly matches the intended visual hierarchy: the main goal progress stays dominant and spans the whole card, while subtasks use their narrower bars more efficiently by sharing rows. It is also a minimal view-layer change that avoids touching the data model or expand/collapse behavior.

## Verification

Add a source regression test that requires a dedicated two-column grid helper and a `LazyVGrid` for `goalSubtasksExpansionPanel`, then run the focused plan test suite to confirm the layout change does not affect goal state or timeline presentation.
