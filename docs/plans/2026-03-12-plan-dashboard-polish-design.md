# 2026-03-12 Plan Dashboard Polish Design

## Summary

Polish three parts of the plan dashboard. First, restyle the `NewT` and `LinkT` actions in the linked-task area so they feel intentional instead of looking like generic large glass buttons. Second, extend the subtask card context menu with `Move Left` and `Move Right` so users can swap a subtask with its adjacent card without dragging. Third, increase the visual gap between the timeline goal bars and the month labels so the chart reads more cleanly.

## Chosen Approach

Keep all changes inside the existing plan dashboard view and view model. The linked-task actions will stay in the same place and keep the same short labels, but their labels will become richer button surfaces with icons, tint, and secondary text. The subtask move actions will be added to the existing context menu and routed through new view-model helpers that swap with adjacent subtasks. The timeline spacing fix will come from extra bottom space between the plot region and x-axis labels instead of shrinking bars or reducing label size.

## Alternatives Considered

Use plain button-style tweaks only. Rejected because the current problem is not just padding but lack of hierarchy and affordance.

Put subtask movement into a nested `Move` submenu. Rejected because the interaction is simple and should stay one click away.

Reduce the timeline bar height instead of adding vertical separation. Rejected because it weakens legibility and solves the wrong layer of the layout.

## Data Flow

The move-left and move-right actions operate on the goal's current subtask order, compute the adjacent neighbor, and reuse repository persistence so the reordered list remains the source of truth. The button polish is view-only. The timeline spacing change is also view-only and affects chart layout, not timeline data.

## Testing

Add source assertions for the new linked-task button label helper, the context menu move entries, and the new chart bottom padding. Add view-model tests for move-left and move-right so adjacent swapping behavior is verified independently of the UI.
