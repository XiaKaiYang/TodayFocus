# Goal Progress Fill Surface Design

## Goal

Make the expanded subtask cards and the goal timeline bars share the same visual language: a lightly transparent status-colored surface with progress filled from left to right.

## Root Cause

The current subtask cards and the gantt-style goal bars no longer speak the same visual language. The cards use a neutral off-white surface, while the timeline bars use a single solid status rectangle. That breaks the connection between progress feedback in the card list and progress feedback in the timeline.

## Chosen Approach

Use the goal status color as the common tint for both surfaces. Each subtask card will render a low-opacity full-width status track with a stronger filled region proportional to the subtask progress. Each timeline bar will render the full scheduled duration as a low-opacity track and overlay a stronger filled segment whose width follows the computed goal progress.

## Why This Approach

This directly matches the requested reference behavior. The cards and the timeline retain transparency, but they now communicate progress in the same left-to-right filled form, making the dashboard feel more coherent and easier to scan.

## Verification

Add a source-level regression test that requires the new card progress surface helper and the timeline fill-end helper, and removes the off-white-only surface assertions. Then run the focused Plan dashboard and view model tests to confirm the visual refactor does not affect goal progress calculations.
