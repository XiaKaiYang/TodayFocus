# Analytics Pie Charts Design

## Goal

Replace the analytics bar/list presentation with pie charts for both the seven-day trend card and the task breakdown card, and show concrete numeric details when the user hovers a slice.

## Current Problem

The analytics dashboard currently mixes a custom vertical bar chart for `Last 7 Days` with a text-only `Top Tasks` ranking. This makes the two cards feel visually inconsistent, and neither card provides a direct hover inspection workflow for exact values.

## Chosen Approach

Use two pie charts with distinct meanings. The left card becomes a seven-day share chart where each slice represents one day of the recent focus total. The right card becomes a task share chart where each slice represents one task's share of completed focus time. Hovering a slice updates an adjacent detail panel with the item name, total duration, and percentage. The task chart also shows the completed session count for the hovered task.

## Component Design

Keep the existing `AnalyticsViewModel` data sources unchanged: `dailyPoints` still drives the left chart and `focusRows` still drives the right chart. In the UI layer, add a small reusable pie-slice shape and a reusable pie graphic that manages hover selection. Build two thin wrapper views around that graphic so each card can format its own labels and detail content without duplicating slice drawing logic.

## Interaction Design

When there is no hovered slice, each card shows a summary state: total focus time for the seven-day chart and total tracked time across the listed top tasks for the task chart. When the pointer enters a slice, that slice gets a stronger outline and the detail panel switches to the hovered item. When the pointer leaves the slice set, the detail panel returns to the summary state.

## Verification

Add regression assertions that the analytics dashboard now uses pie-chart views and that the chart implementation wires hover handling. Then run the analytics-focused test suite to confirm the dashboard source wiring and analytics data shaping still behave as expected.
