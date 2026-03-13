# macOS Responsive Layout Design

## Goal

Make the app adapt cleanly across different Mac screen sizes and window sizes without changing the product structure or introducing a second UI system.

## Chosen Approach

Use a lightweight responsive strategy built around width tiers plus existing compact-height handling. The app will stay a macOS `NavigationSplitView` experience, but the root window minimum size, sidebar width, and several detail screens will stop relying on hard-coded widths. Instead, the shell and each high-impact page will derive a compact, regular, or expanded layout from available width.

The first pass will focus on the pages where fixed widths are currently the most visible: `AppShellView`, `CurrentSessionView`, `NotesLibraryView`, `TasksDashboardView`, `PlanDashboardView`, and `AnalyticsDashboardView`. Other pages can keep their current structure unless the shared helpers make them adapt automatically.

## Why This Approach

This keeps the change proportional to the real problem. The app is currently a macOS windowed product, not a cross-platform iPhone/iPad app, so the biggest wins come from making the existing desktop layout resilient to smaller screens and smaller windows. A shared width-tier helper gives the app a consistent adaptation model, while page-local layout decisions keep the implementation simple and avoid a large architectural rewrite.

## Responsive Model

Use three width tiers:

- `compact`: narrow detail area or small-screen Mac window
- `regular`: current baseline desktop experience
- `expanded`: wider desktops with more horizontal breathing room

Use the existing compact-height concept for vertical tightening in `Current Session`, but pair it with width awareness so the runtime stage, note editor, and reflection modal all shrink before clipping.

## Screen-Level Changes

### App Shell

Reduce the root minimum window size so the app can be used on smaller Mac screens. Keep the sidebar, but allow it to narrow in compact widths instead of forcing a large permanent column. The detail area should always get priority over decorative spacing.

### Current Session

Keep the current visual direction, but derive stage width, note editor width, and reflection modal width from the available window size. The big timer, runtime note composer, and reflection overlay should shrink together rather than relying on a mostly fixed hero width.

### Notes

Switch from a permanently split `HStack` to a responsive arrangement. In compact widths, the notes list and note detail should stack vertically. In regular and expanded widths, keep the current two-column experience with a flexible list width instead of a fixed `340`.

### Tasks

Let task action rows wrap or reflow when horizontal space tightens. Remove fixed composer widths so sheets still feel intentional on smaller windows.

### Plan

Replace the most restrictive fixed widths in goal cards and sheets with max-width constraints tied to available width. Keep the existing subtask grid behavior, but let it collapse more naturally in compact widths.

### Analytics

Keep the cards and charts, but let side-by-side sections wrap into a vertical stack in compact widths. Remove the hard `360` width on the top-task card so the analytics page can compress without clipping.

## Verification

Add regression tests that lock the new width-tier behavior and updated layout constants. Add source-backed layout tests for the pages where structure changes are easiest to validate textually, especially `Notes`, `Analytics`, and the root app minimum window size. Run focused layout tests first, then the full suite.
