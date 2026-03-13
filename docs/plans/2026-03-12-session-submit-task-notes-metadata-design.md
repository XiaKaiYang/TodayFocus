# Session Submit Task Completion And Notes Metadata Design

## Goal

Make `Submit` complete the currently selected session task, and make the `Notes` page show each saved note's session time plus reflection emoji.

## Chosen Approach

Keep the behavior anchored in `CurrentSessionViewModel.submitReflection()`. After the completed reflection record is persisted, the view model will mark only the currently selected task as completed if that task came from the task picker. The same view model will then refresh its local task list so the finished task disappears from the session selector.

For the `Notes` page, extend `NotesLibraryEntry` with presentation-ready metadata derived from `FocusSessionRecord`: one absolute ended-time string and one optional mood emoji string. The notes list row and detail header will render those values directly instead of recomputing formatting in the view.

## Why This Approach

This keeps the completion rule tightly coupled to the moment the user explicitly submits reflection, which is the exact product event being changed. It avoids adding another cross-view-model coordinator just to complete a single selected task. On the notes side, pushing formatted metadata into the view model keeps the SwiftUI view simple and makes the new display requirements easy to test.

## Task Completion Rule

Only the task currently selected in the session picker is auto-completed. Free-typed or taskless sessions do not complete any task. Repeating tasks should keep the existing successor-generation behavior so daily and weekly tasks continue rolling forward correctly.

## Notes Presentation

Each note entry should expose:

- the existing relative ended text
- a new absolute ended-time label for the session
- a new optional mood emoji derived from `focused`, `neutral`, or `distracted`

The list row should show the emoji next to the time metadata, and the detail pane should show the emoji alongside the time and duration summary.

## Verification

Add regression tests that prove `submitReflection()` completes the selected task and leaves unrelated sessions alone. Add note-library tests that prove mood emoji and ended-time strings are produced from stored session records and remain sorted by `endedAt`.
