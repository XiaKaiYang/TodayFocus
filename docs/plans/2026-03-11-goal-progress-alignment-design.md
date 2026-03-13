# Goal Progress Alignment Design

## Goal

Align the expanded goal subtasks with the same left edge as the `Overall Progress` content and let the main overall progress bar span the full usable width of the goal card body.

## Root Cause

The current subtask panel is constrained to a narrow trailing panel, which creates excessive indentation. Separately, the `goalProgressSummary` view still lives inside the left metadata column of the goal row, so its progress bar can only fill that column instead of the whole card body.

## Chosen Approach

Restructure each goal card into two vertical layers inside the main content area. The top layer keeps the title, notes, status, and action buttons. The second layer holds the `goalProgressSummary` as a full-width block. Inside that summary, the expanded subtasks panel will also use the full available width and align to the leading edge while retaining the chevron-anchored reveal animation.

## Why This Approach

This fixes both visual issues at the layout level instead of tuning padding values. The progress summary gets the width it actually needs, and the subtask rows line up naturally with the overall progress label and bar. It also keeps the existing per-goal expand behavior and the improved chevron animation.

## Verification

Add a source regression test that requires the new top-row helper structure, removes the old narrow trailing panel constraints, and keeps the top-trailing transition anchor. Then run the focused plan test suite to confirm the layout refactor does not affect goal persistence or timeline behavior.
