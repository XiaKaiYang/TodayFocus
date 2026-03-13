# 2026-03-12 Timeline Month Axis Spacing Revision Design

## Summary

The previous spacing revision addressed the overall axis area instead of the actual visual collision the user called out. The problem is specifically the lowest pink timeline bar sitting too close to the month labels.

## Chosen Approach

Restore the chart-axis spacing to a tighter baseline and increase the chart's vertical plot bottom reserve through `chartYScale(range: .plotDimension(... endPadding: ...))`. This lifts the lowest timeline row upward without shrinking the bar height or pushing the month labels farther away from the card edge.

## Alternatives Considered

1. Increase plot bottom padding and label top padding again. Rejected because it changes the distance between the axis area and the card edge instead of the distance between the pink bar and the month labels.

2. Reduce the bar height. Rejected because it weakens the visual weight of the timeline blocks instead of fixing row placement.

## Data Flow

This remains a view-only chart layout adjustment inside `PlanDashboardView`. Timeline data and x-axis formatting stay unchanged; only the y-axis plot range constants move the rendered rows.

## Testing

Update the source assertions to require the larger `endPadding` and to reject the temporary axis-spacing values from the previous attempt, then rerun the focused dashboard and view-model tests after implementation.
