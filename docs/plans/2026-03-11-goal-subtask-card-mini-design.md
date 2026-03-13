# Goal Subtask Card Mini Design

## Goal

Make the expanded goal subtask cards feel substantially smaller and switch their background to a clear off-white surface so they stop competing with the surrounding goal card.

## Root Cause

Even after the previous reduction, the subtask cards still occupy too much area in the expanded section because their adaptive width and minimum height remain generous. In addition, the current warm-tinted surface still reads as a colored card instead of a neutral support surface.

## Chosen Approach

Reduce the adaptive card width range, cut the card minimum height roughly in half, and shrink the internal text and control sizing one more step. Keep the current layout structure and interactions, but change the card background to a near-uniform beige off-white fill with only minimal border and accent tinting.

## Why This Approach

This directly matches the latest feedback without reworking the interaction model. The cards remain scannable and tappable, but their visual weight drops enough that the goal row remains primary and the subtask area becomes secondary detail.

## Verification

Add a source-level regression test that requires the smaller card geometry and the off-white fill values, then run the focused Plan dashboard and view model tests to confirm the visual change does not affect subtask progress behavior.
