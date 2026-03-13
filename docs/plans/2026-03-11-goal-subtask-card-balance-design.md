# Goal Subtask Card Balance Design

## Goal

Make the expanded goal subtask cards feel proportionate to the surrounding goal row and align their color treatment with the app's softer glass surface system.

## Root Cause

The current compact-card redesign improved density, but the cards still use a relatively tall minimum height, generous padding, and a saturated orange gradient for in-progress subtasks. Inside the larger goal row, that combination makes each subtask card read louder and heavier than the rest of the dashboard.

## Chosen Approach

Keep the current compact card structure, but shrink the card geometry one step and replace the saturated gradient fill with a lighter glass-like surface that carries only a subtle status tint. The title, metric, and action affordances stay in the same places so interaction cost does not increase.

## Why This Approach

This is the smallest change that directly addresses both pieces of feedback. Reducing height, padding, corner radius, and control sizes restores proportion, while lowering saturation and increasing translucency keeps the subtask area visually related to the existing goal cards instead of competing with them.

## Verification

Add a source-level regression test that requires the smaller card dimensions and the new muted surface helper, then run the focused Plan dashboard and view model tests to confirm the visual refactor does not disturb goal progress behavior.
