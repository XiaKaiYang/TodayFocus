# 2026-03-12 Timeline Month Axis Spacing Design

## Summary

The timeline goal bars still feel visually crowded against the month labels. The current chart already adds a small plot bottom padding, but the remaining gap is too tight, so the bars and labels still read as touching.

## Chosen Approach

Keep the existing bar height and month text styling, then increase separation in two places: add more bottom padding to the chart plot area and add a small top padding to the month labels themselves. This preserves the current timeline density while clearly separating bars from axis labels.

## Alternatives Considered

1. Increase only the plot bottom padding. Rejected because it improves spacing somewhat but does not consistently prevent the labels from still feeling visually attached to the bars.

2. Reduce the bar height. Rejected because it weakens the timeline's visual weight and solves the symptom by shrinking the content instead of improving the layout.

## Data Flow

This is a view-only chart layout change inside `PlanDashboardView`. It does not affect the timeline data model, visible window logic, or bar positions.

## Testing

Add source assertions for the increased plot bottom padding and the added month-label top padding. Re-run the focused dashboard and view-model tests after the implementation.
