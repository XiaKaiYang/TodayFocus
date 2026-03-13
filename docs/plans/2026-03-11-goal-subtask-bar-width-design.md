# Goal Subtask Bar Width Design

## Goal

Keep the overall goal progress bar full width across the goal card content area, while letting each subtask progress bar use a narrower reading width instead of stretching across the whole card.

## Root Cause

After moving the goal progress summary to a full-width section, both the overall progress bar and the subtask rows inherited the same available width. That fixed the overall bar but also made each subtask bar stretch farther than needed for a compact secondary detail view.

## Chosen Approach

Leave the overall progress summary layout unchanged. Add a local maximum width constraint to each subtask summary row so the rows remain left-aligned under `Overall Progress` but their bars stop at a narrower content width.

## Why This Approach

This is the smallest change that matches the requested visual hierarchy. The primary progress bar keeps the emphasis by spanning the whole card, while subtasks stay readable and visually subordinate without reintroducing the earlier right indentation problem.

## Verification

Add a source-level regression assertion that the subtask summary row now applies a narrower maximum width, then run the focused plan tests to confirm the UI change does not affect goal state or timeline behavior.
