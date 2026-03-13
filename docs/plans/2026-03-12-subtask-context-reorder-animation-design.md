# 2026-03-12 Subtask Context Reorder Animation Design

## Summary

When a subtask is moved left or right from the context menu, animate the reorder with the same spring motion used by drag-based subtask reordering. The goal is to make context-menu moves feel like a visible card swap instead of an instant jump.

## Chosen Approach

Keep the existing context-menu actions and wrap their reorder calls in the same `withAnimation(.spring(response: 0.24, dampingFraction: 0.84))` behavior already used when a drag ends. This keeps drag and menu reorder interactions visually consistent without introducing a second animation system.

## Alternatives Considered

1. Add a separate custom transition just for context-menu moves. Rejected because it would create two different reorder motion styles for the same card list.

2. Move the animation into the view model. Rejected because SwiftUI view animation belongs at the view layer, and the drag path already establishes that pattern.

## Data Flow

The context menu still delegates the actual swap to the existing `moveSubtaskLeft` and `moveSubtaskRight` view-model methods. The only behavior change is that the view now performs those calls inside the same spring animation transaction as drag reorder.

## Testing

Add a source test that proves the context-menu move actions call a shared animated reorder helper instead of invoking the view model directly. Re-run the focused dashboard and view-model test suite after the implementation.
