# Timeline Zoom Scroll Detail Design

## Goal

When the user zooms into the gantt timeline, the chart should expose a horizontal scrollbar so the zoomed window can be inspected in detail, and the time axis should show denser intermediate ticks between month labels.

## Root Cause

The current zoom interaction only shrinks `visibleWindow`. The chart itself always renders at the card width, so zooming changes the date range but does not increase on-screen detail density. Because the chart width never exceeds the viewport, macOS never shows a horizontal scrollbar. At the same time, the x-axis still renders only month-level marks, so the user cannot read finer temporal structure after zooming in.

## Chosen Approach

Keep the existing month-span zoom model in `PlanViewModel`, but render the chart inside a horizontal `ScrollView` whose content width grows as the visible month span gets smaller. Use deterministic width multipliers so zoomed timelines become physically wider than the card and therefore expose a bottom scrollbar. Keep the current `visibleWindow` domain as the source of truth for dates; scrolling will inspect the already-zoomed window rather than pan into dates outside the current window.

## Zoom And Scroll Behavior

Use these width multipliers for the chart content:

- `12` months: `1.0x` viewport width
- `6` months: `1.6x` viewport width
- `3` months: `2.2x` viewport width
- `1` month: `3.2x` viewport width

The horizontal `ScrollView` should always exist around the chart, but the scrollbar will only appear once the computed content width exceeds the viewport. The chart card surface and clipping should stay on the outer container so the scrollbar remains visually attached to the gantt card. The existing vertical wheel zoom gate should stay intact, but horizontal-dominant wheel gestures must pass through to the scroll view instead of being swallowed by the zoom overlay.

## Axis Detail Levels

Keep the existing month labels as the primary axis marks at every zoom level. Add conditional secondary marks:

- `6` months and `3` months: weekly gridlines with no labels
- `1` month: weekly gridlines plus a lighter every-3-days gridline layer with no labels

This keeps the month labels readable while giving the user finer temporal reference points when the chart is zoomed in. The denser marks should only add gridlines and ticks, not extra text labels.

## Why This Approach

This preserves the current zoom mental model, avoids introducing a second timeline-panning data model, and gives the user the native macOS scrollbar behavior they asked for. It also keeps the interaction incremental: wheel zoom changes time scale, while the horizontal scrollbar inspects detail inside the resulting scale.

## Verification

Add unit tests for the new timeline width multiplier and axis-detail helpers, plus source-level assertions that the dashboard now wraps the chart in a horizontal scroll view and uses the new helpers. Run the focused plan dashboard, zoom gate, timeline presentation, and plan view-model tests after implementation.
