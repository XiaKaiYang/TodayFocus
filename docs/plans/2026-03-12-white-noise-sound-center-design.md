# White Noise Sound Center Design

## Goal

Add a dedicated `White Noise` section to the app sidebar, expose a full sound-control dashboard for background and completion sounds, and connect the two requested task-related sound effects: `ending-soon.wav` when a Today task is manually completed from the Today list, and `eventually.wav` when a selected Today-task focus session ends and the submit box appears.

## Current State

The app already has imported audio assets under `Apps/FocusSessionApp/Resources/Audio`, but there is no shared playback service, no persisted sound preferences, and no sidebar section dedicated to sound controls. The Today completion interaction currently ends in `TasksViewModel.markTaskCompleted`, and the focus-complete-to-submit-box transition currently happens in `CurrentSessionViewModel` when `.finishFocus` moves the session state into `.reflecting`.

## Chosen Approach

Introduce a small shared audio layer, `SoundCenter`, owned by `AppShellView`, and pass it into the sections that need playback. Add a new sidebar section, `White Noise`, with a dashboard that mirrors the requested five-card sound page:

- `Background sound`
- `Session sound`
- `Session end sound`
- `Break sound`
- `Break end sound`

Persist all sound choices and volumes in `AppPreferencesStore`. Use the imported Session white-noise assets for looping background sounds and the imported Session and TickTick prompt sounds for one-shot sound effects.

## Sound Model

The sound settings should be stored as preferences, not view-local state. Use this split:

- `backgroundSoundEnabled`: whether looping background sound should be active during supported phases
- `sessionSound`: selected looping sound for the focus phase
- `sessionSoundVolume`
- `sessionEndSound`: selected one-shot sound when a focus session finishes and opens the submit box
- `sessionEndSoundVolume`
- `breakSound`: selected looping sound for break phases
- `breakSoundVolume`
- `breakEndSound`: selected one-shot sound when a break ends
- `breakEndSoundVolume`

Recommended defaults for the first implementation:

- `sessionSound = "Clock Ticking.wav"`
- `sessionEndSound = "eventually.wav"`
- `breakSound = "Ocean Waves.mp3"`
- `breakEndSound = "Gong.mp3"`
- all volumes start at a comfortable mid-range value
- `backgroundSoundEnabled = false`

These defaults align the configurable model with the user’s requested starting behavior.

## Playback Rules

Use a single `SoundCenter` abstraction with two responsibilities:

- loop one background track at a time
- play one-shot effects on demand

Apply these rules:

1. When a Today task is completed by clicking the left checkbox in the Today list, play `ending-soon.wav` after the repository update succeeds.
2. When a focus session tied to a selected Today task transitions into `.reflecting`, play the configured `sessionEndSound`. With the default configuration, this is `eventually.wav`.
3. The submit box should continue to appear through the existing `.reflecting` state. The sound is an accompaniment to that transition, not a replacement for it.

## Sidebar And Page Design

Add a new `AppSection.whiteNoise` entry to the primary sidebar, positioned close to `Session`. The page should visually match the existing card-based dashboards in the app and present the five requested sound controls as dedicated cards instead of burying them in `Settings`.

Each card should show:

- the role label
- the currently selected sound
- a horizontal volume control where applicable

The `Background sound` card should be a top-level toggle and explanatory note. The other four cards should remain configurable even when background sound is off so the user can prepare sound behavior before enabling it.

## Scope Boundary

This iteration does not rebuild the dormant break lifecycle in the session reducer. `Break sound` and `Break end sound` should be fully visible, persisted, and ready for playback, but only the two explicitly requested triggers are guaranteed to fire in this change:

- Today checkbox completion
- focus completion entering the submit box

If the break lifecycle is activated later, the stored selections should already be ready to plug in.

## Error Handling

Playback failures should never block task completion or session transitions. If an audio asset cannot be loaded, the action should still succeed and the app should fail silently or log locally for debugging. The UI should keep using persisted preferences even if the selected file later becomes unavailable.

## Testing

Add focused tests that lock down:

- the new `whiteNoise` sidebar section and view wiring
- persisted sound preferences and defaults
- Today completion triggering the `ending-soon.wav` request
- focus completion entering `.reflecting` triggering the configured session-end sound, with the default resolving to `eventually.wav`
- source-level assertions that the White Noise dashboard exposes the five requested cards
