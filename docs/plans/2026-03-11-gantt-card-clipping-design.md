# Gantt Card Clipping Design

## Goal

Keep zoomed gantt content inside the visible timeline card so timeline bars and overlays never bleed outside the rounded card boundary.

## Root Cause

The timeline `Chart` currently sits on top of an `AppCardSurface` background, but the composed view is not clipped. When the visible domain shrinks during zoom, chart content can render beyond the intended card edge because the background shape only paints a card and does not constrain descendants.

## Chosen Approach

Clip the entire timeline card to the same rounded rectangle used by the card surface. This keeps the existing layout, zoom behavior, and activation logic intact while ensuring all chart content and overlays stay inside the card bounds.

## Why This Approach

This is the smallest safe fix. It addresses the root cause at the container boundary instead of trying to compensate with extra padding or custom chart math. It also keeps the interaction overlay aligned with what the user actually sees.

## Verification

Add a regression assertion that the timeline card applies a rounded clip shape, then run the focused plan timeline test suite to confirm the new clipping does not break existing zoom and presentation behavior.
