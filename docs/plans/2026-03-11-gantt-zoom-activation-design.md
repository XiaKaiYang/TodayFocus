# Gantt Zoom Activation Design

## Goal

Prevent accidental gantt zoom while the user is scrolling the goals page. Wheel-based zoom should only work after the user explicitly clicks inside the gantt chart.

## Chosen Approach

Use a gated interaction layer inside the existing chart overlay. The overlay keeps an internal `isZoomActive` state. A click inside the chart activates zoom mode. While zoom mode is inactive, wheel events are passed through so the surrounding page keeps scrolling normally. When zoom mode is active, wheel events are converted into timeline zoom requests exactly as today.

## Activation And Exit Rules

The chart starts inactive. Clicking inside the gantt plot activates zoom. Clicking outside the plot in the same window deactivates zoom. If the window resigns key status, zoom also deactivates. This keeps the feature explicit and reduces sticky accidental activation.

## Implementation Notes

No timeline math changes are needed in `PlanViewModel`. The change stays in the AppKit bridge that already owns wheel handling. Add a small interaction gate type so the activation rules can be tested without synthesizing AppKit events. Keep the chart overlay buttons for goal focusing unchanged.

## Verification

Add unit tests for the interaction gate activation rules and source-level assertions that the dashboard view now wires activation, deactivation, and pass-through scrolling. Then run the targeted test suite for the plan dashboard.
