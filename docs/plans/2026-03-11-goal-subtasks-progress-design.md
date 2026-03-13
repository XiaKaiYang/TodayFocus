# Goal Subtasks Progress Design

## Goal

Extend the Plan dashboard so each goal can contain child subtasks, each subtask can track its own progress, and the goal shows an automatically derived total progress based on those subtasks.

## Recommended Approach

We will keep goal editing centralized in the existing create/edit sheet and keep the goals list focused on scanning status. Subtasks will be edited inside the goal sheet, while the list row will surface the computed overall progress and a compact summary of the child subtasks.

This keeps the interaction model close to what the app already does well: the list is for reading and acting on a goal, and the sheet is for structured editing. It also avoids cluttering the main Goals section with many inline controls.

## Data Model

`PlanGoal` will gain a `subtasks` collection made of lightweight `PlanGoalSubtask` values. Each subtask stores:

- `id`
- `title`
- `progressPercent`

`PlanGoal` will also expose computed helpers:

- `progressPercent`: rounded average of all subtask percentages
- `completedSubtaskCount`: number of subtasks at `100`
- `hasSubtasks`: whether any subtasks exist

If a goal has no subtasks, total progress is treated as unavailable rather than guessed. That lets older goals remain valid without inventing fake completion numbers.

## Persistence

The existing SwiftData goal record will stay as a single stored model. Instead of introducing a new relationship table, `StoredPlanGoal` will persist subtasks as encoded JSON data. The repository will decode that field back into `[PlanGoalSubtask]`.

This is the smallest change that still supports durable subtasks, and it matches current usage: the app reads and writes whole goals, not individual subtasks.

Old goals already in the store will decode as an empty subtask list.

## View Model

`PlanViewModel` will gain composer state for editable subtasks and helper methods to:

- add a blank subtask row
- remove a subtask row
- update a subtask title
- clamp and save subtask progress
- load existing subtasks into the editor when editing

Saving a goal will round-trip the subtask collection together with the existing fields. Goal status will remain a manual field and will not auto-flip based on progress.

## UI

The Goals list row will add a progress block under the date and notes area:

- a goal-level progress label and bar
- `completed / total subtasks`
- up to a few child subtask summaries with small progress bars

The create/edit goal sheet will add a `Subtasks` section below the existing status and date controls. That section will support:

- adding a new subtask
- editing each subtask title
- changing each subtask progress with a slider
- deleting a subtask
- showing the computed overall progress as read-only feedback

## Validation Rules

- Goal title is still required.
- End time must still be later than start time.
- Blank subtask titles will be trimmed; completely empty subtask rows will be dropped before save.
- Subtask progress will be clamped to `0...100`.

## Testing

We will use TDD for the feature:

1. Add failing `PlanViewModelTests` for subtask persistence through create/edit flows and computed total progress.
2. Add failing `PlanGoalsRepositoryTests` for repository round-trip of stored subtasks.
3. Add or extend source-level UI tests so the Plan dashboard keeps the progress summary and subtask editing affordances wired in.
4. Implement the minimum production changes to make those tests pass.
5. Run focused macOS tests covering Plan view model, repository, source wiring, and timeline presentation regressions.
