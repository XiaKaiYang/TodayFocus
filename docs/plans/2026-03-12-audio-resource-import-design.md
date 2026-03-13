# Audio Resource Import Design

## Goal

Import all owned prompt sounds and white-noise assets from `Session.app` and `TickTick.app` into this project so the repository contains the complete audio set needed for future playback and settings work.

## Source Inventory

The source apps contain `39` audio files in total. `Session.app` ships `6` prompt sounds, `9` white-noise tracks, and a duplicate copy of the same `6` prompt sounds inside `Assets/Audio`. `TickTick.app` ships `18` prompt sounds. Hash comparison shows the duplicated `Session` prompt sounds are byte-identical, so the unique import set is `33` files.

## Chosen Approach

Import all unique files into a structured resource tree inside the app source directory:

- `Apps/FocusSessionApp/Resources/Audio/Session/SoundEffects`
- `Apps/FocusSessionApp/Resources/Audio/Session/WhiteNoise`
- `Apps/FocusSessionApp/Resources/Audio/TickTick/SoundEffects`

Preserve original filenames so later product work can reference familiar asset names. Record each imported file in a manifest that includes the source app and original bundle path. Add the top-level `Audio` directory to the Xcode project as a folder reference and include it in the app target resources so the full subtree is copied into the built bundle without hand-maintaining `33` individual file references.

## Why This Approach

This satisfies the user's request to import everything while keeping the repository organized and avoiding obvious duplicate storage. Using a folder reference keeps the Xcode wiring minimal and lowers future maintenance cost when new audio files are added. A manifest makes provenance explicit, which is useful because the resources originate from two separate owned apps.

## Non-Goals

This task does not yet add playback UI, preference pickers, or runtime asset-selection logic. It only imports the assets, preserves structure, and ensures they ship in the app bundle.

## Verification

Add focused tests that assert the workspace contains the expected audio directories and manifest, and that the Xcode project includes the `Audio` folder reference in the resources build phase. After implementation, run the focused resource tests and a macOS build to verify the imported audio tree appears inside the built app bundle.
