# Goal Subtask Expansion Anchor Design

## Goal

Make the goal subtask expansion feel like it opens from the chevron control on the right side of the progress summary instead of dropping down from the full `Overall Progress` block.

## Root Cause

The current `subtasks` stack is inserted directly under the full progress summary `VStack` and uses `.move(edge: .top)` during transition. That structure makes the reveal animation read as a top-down extension of the whole summary area, even though the user initiates the action from the chevron at the far right.

## Chosen Approach

Keep the static summary content in place, but move the expanded subtask content into a dedicated trailing-aligned panel. The panel will sit under the summary row inside a full-width container with trailing alignment so its visible edge matches the chevron side. Its insertion and removal transition will use an opacity-plus-scale animation anchored at `.topTrailing` to make the panel appear to open from the chevron's horizontal position.

## Why This Approach

This is the smallest fix that changes the perceived animation origin without redesigning the goal card. It preserves the current per-goal expand state, the compact chevron control, and the existing subtask summary rows while making the motion line up with where the user clicks.

## Verification

Add a source-level regression assertion that the goal subtask expansion uses a dedicated panel helper, a trailing-aligned container, and a `.topTrailing` animation anchor, while removing the old `.move(edge: .top)` transition. Then run the focused plan tests to confirm the layout change does not disturb goal progress or timeline behavior.
