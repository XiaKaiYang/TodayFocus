# White Noise Sound Center Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a White Noise sidebar workspace, persist sound configuration, and wire the requested Today-task and focus-completion sound effects through a shared audio layer.

**Architecture:** Introduce a shared `SoundCenter` service in the app layer, store sound configuration in `AppPreferencesStore`, expose a dedicated `WhiteNoiseDashboardView` as a new `AppSection`, and trigger sound requests from `TasksViewModel` and `CurrentSessionViewModel` without letting playback failures affect the underlying task/session state transitions.

**Tech Stack:** SwiftUI, AVFoundation/AppKit audio playback, `UserDefaults`-backed preferences, XCTest unit tests, source assertions, focused `xcodebuild` runs.

---

### Task 1: Lock down the new sound preferences with failing tests

**Files:**
- Modify: `/Users/xiakaiyang/Documents/New project/Tests/FocusSessionAppTests/AppPreferencesStoreTests.swift`

**Step 1: Write the failing tests**

Add assertions for:
- `AppPreferences` default values:
  - `backgroundSoundEnabled == false`
  - `sessionSound == "Clock Ticking.wav"`
  - `sessionEndSound == "eventually.wav"`
  - `breakSound == "Ocean Waves.mp3"`
  - `breakEndSound == "Gong.mp3"`
- persisted reload behavior for all four sound selections and their volumes

**Step 2: Run the focused test to verify it fails**

Run:

`xcodebuild test -project /Users/xiakaiyang/Documents/New\ project/FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/AppPreferencesStoreTests`

Expected: FAIL because the new sound preference fields and persistence methods do not exist yet.

### Task 2: Lock down sidebar and White Noise page wiring with failing source tests

**Files:**
- Add: `/Users/xiakaiyang/Documents/New project/Tests/FocusSessionAppTests/WhiteNoiseDashboardViewSourceTests.swift`

**Step 1: Write the failing source assertions**

Require the source to contain:
- `AppSection.whiteNoise`
- sidebar title `White Noise`
- symbol `speaker.wave.3`
- `WhiteNoiseDashboardView(viewModel:`
- the five labels:
  - `Background sound`
  - `Session sound`
  - `Session end sound`
  - `Break sound`
  - `Break end sound`

**Step 2: Run the focused test to verify it fails**

Run:

`xcodebuild test -project /Users/xiakaiyang/Documents/New\ project/FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/WhiteNoiseDashboardViewSourceTests`

Expected: FAIL because the new section and dashboard do not exist yet.

### Task 3: Lock down the sound-trigger behavior with failing tests

**Files:**
- Modify: `/Users/xiakaiyang/Documents/New project/Tests/FocusSessionAppTests/CurrentSessionViewModelTests.swift`
- Add: `/Users/xiakaiyang/Documents/New project/Tests/FocusSessionAppTests/TasksViewModelSoundTests.swift`

**Step 1: Write the failing session sound test**

Add a focused test that:
- selects a Today task
- starts a session
- finishes the session
- verifies the session enters `.reflecting`
- verifies a sound request for the configured session-end sound is emitted

**Step 2: Write the failing Today completion sound test**

Add a test that:
- marks a visible Today task as completed
- verifies the task is completed
- verifies a sound request for `ending-soon.wav` is emitted only after success

**Step 3: Run the focused tests to verify they fail**

Run:

`xcodebuild test -project /Users/xiakaiyang/Documents/New\ project/FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/CurrentSessionViewModelTests -only-testing:FocusSessionAppTests/TasksViewModelSoundTests`

Expected: FAIL because there is no sound-request abstraction yet.

### Task 4: Add the minimal sound preference model and settings APIs

**Files:**
- Modify: `/Users/xiakaiyang/Documents/New project/Apps/FocusSessionApp/AppPreferencesStore.swift`
- Modify: `/Users/xiakaiyang/Documents/New project/Apps/FocusSessionApp/ViewModels/SettingsViewModel.swift`
- Modify: `/Users/xiakaiyang/Documents/New project/Tests/FocusSessionAppTests/AppPreferencesStoreTests.swift`

**Step 1: Add preference fields and enums**

Add the minimal typed model needed for:
- looped white-noise choices
- one-shot prompt-sound choices
- per-role volume values
- background-sound enabled state

**Step 2: Add persistence and update methods**

Implement:
- load
- persist
- typed update helpers for each role and volume

**Step 3: Run the focused preferences test**

Run the `AppPreferencesStoreTests` command from Task 1.

Expected: PASS

### Task 5: Add the shared sound abstraction with the smallest testable surface

**Files:**
- Add: `/Users/xiakaiyang/Documents/New project/Apps/FocusSessionApp/Audio/SoundCenter.swift`
- Add: `/Users/xiakaiyang/Documents/New project/Apps/FocusSessionApp/Audio/SoundPlaybackRequest.swift`
- Add: `/Users/xiakaiyang/Documents/New project/Tests/FocusSessionAppTests/SoundCenterTests.swift`

**Step 1: Add a protocol-friendly surface**

Create a small API that supports:
- play one-shot sound by asset name and volume
- start or replace looped background playback by asset name and volume
- stop background playback

**Step 2: Keep the first implementation minimal**

Use AVFoundation/AppKit under the hood, but make tests rely on a lightweight recording spy instead of real audio playback.

**Step 3: Run the focused sound-center test**

Run:

`xcodebuild test -project /Users/xiakaiyang/Documents/New\ project/FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/SoundCenterTests`

Expected: PASS

### Task 6: Add the White Noise sidebar section and dashboard

**Files:**
- Modify: `/Users/xiakaiyang/Documents/New project/Apps/FocusSessionApp/UI/AppShell/AppSection.swift`
- Modify: `/Users/xiakaiyang/Documents/New project/Apps/FocusSessionApp/UI/AppShell/AppShellView.swift`
- Add: `/Users/xiakaiyang/Documents/New project/Apps/FocusSessionApp/UI/WhiteNoise/WhiteNoiseDashboardView.swift`
- Add: `/Users/xiakaiyang/Documents/New project/Apps/FocusSessionApp/ViewModels/WhiteNoiseViewModel.swift`
- Modify: `/Users/xiakaiyang/Documents/New project/Tests/FocusSessionAppTests/WhiteNoiseDashboardViewSourceTests.swift`

**Step 1: Add the new sidebar section**

Add `.whiteNoise` with:
- title `White Noise`
- sidebar title `White Noise`
- symbol `speaker.wave.3`

Place it near `Session` in the primary sidebar ordering.

**Step 2: Add the view model and dashboard**

Build the five-card page with bindings to persisted preferences:
- background toggle
- session sound + volume
- session end sound + volume
- break sound + volume
- break end sound + volume

**Step 3: Wire it into AppShell**

Instantiate the view model once and route `.whiteNoise` to `WhiteNoiseDashboardView`.

**Step 4: Run the focused source test**

Run the `WhiteNoiseDashboardViewSourceTests` command from Task 2.

Expected: PASS

### Task 7: Trigger Today completion sound after successful checkbox completion

**Files:**
- Modify: `/Users/xiakaiyang/Documents/New project/Apps/FocusSessionApp/ViewModels/TasksViewModel.swift`
- Add: `/Users/xiakaiyang/Documents/New project/Tests/FocusSessionAppTests/TasksViewModelSoundTests.swift`

**Step 1: Inject the sound request dependency**

Add the smallest abstraction needed so `TasksViewModel` can request a one-shot sound without depending on concrete playback details.

**Step 2: Play `ending-soon.wav` only after success**

Trigger the one-shot request after `repository.completeTask` succeeds and before returning control to the UI.

**Step 3: Run the focused task sound test**

Run:

`xcodebuild test -project /Users/xiakaiyang/Documents/New\ project/FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/TasksViewModelSoundTests`

Expected: PASS

### Task 8: Trigger focus-complete sound when the submit box appears

**Files:**
- Modify: `/Users/xiakaiyang/Documents/New project/Apps/FocusSessionApp/ViewModels/CurrentSessionViewModel.swift`
- Modify: `/Users/xiakaiyang/Documents/New project/Tests/FocusSessionAppTests/CurrentSessionViewModelTests.swift`

**Step 1: Inject the sound request dependency**

Add the smallest abstraction needed so `CurrentSessionViewModel` can request one-shot playback.

**Step 2: Play the configured session-end sound on `.finishFocus`**

When a selected Today-task session transitions into `.reflecting`, request the configured session-end sound using the stored preference and volume. Keep the reflection flow unchanged so the submit box still appears as before.

**Step 3: Run the focused current-session tests**

Run:

`xcodebuild test -project /Users/xiakaiyang/Documents/New\ project/FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/CurrentSessionViewModelTests`

Expected: PASS

### Task 9: Add background-sound phase syncing in the app shell

**Files:**
- Modify: `/Users/xiakaiyang/Documents/New project/Apps/FocusSessionApp/UI/AppShell/AppShellView.swift`
- Modify: `/Users/xiakaiyang/Documents/New project/Apps/FocusSessionApp/ViewModels/WhiteNoiseViewModel.swift`
- Modify: `/Users/xiakaiyang/Documents/New project/Tests/FocusSessionAppTests/WhiteNoiseDashboardViewSourceTests.swift`

**Step 1: Sync focus-phase background playback**

When `backgroundSoundEnabled` is on:
- focus-like phases should start the configured `sessionSound` loop
- idle-like phases should stop background playback

Do not invent break playback transitions beyond the current lifecycle actually used by the reducer.

**Step 2: Keep the sync resilient**

Missing assets or playback failures must not affect session state or navigation state.

**Step 3: Run the focused White Noise source tests**

Run the `WhiteNoiseDashboardViewSourceTests` command from Task 2.

Expected: PASS

### Task 10: Run focused regression verification

**Files:**
- Test: `/Users/xiakaiyang/Documents/New project/Tests/FocusSessionAppTests/AppPreferencesStoreTests.swift`
- Test: `/Users/xiakaiyang/Documents/New project/Tests/FocusSessionAppTests/WhiteNoiseDashboardViewSourceTests.swift`
- Test: `/Users/xiakaiyang/Documents/New project/Tests/FocusSessionAppTests/TasksViewModelSoundTests.swift`
- Test: `/Users/xiakaiyang/Documents/New project/Tests/FocusSessionAppTests/CurrentSessionViewModelTests.swift`
- Test: `/Users/xiakaiyang/Documents/New project/Tests/FocusSessionAppTests/CurrentSessionViewSourceTests.swift`

**Step 1: Run the focused suite**

Run:

`xcodebuild test -project /Users/xiakaiyang/Documents/New\ project/FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/AppPreferencesStoreTests -only-testing:FocusSessionAppTests/WhiteNoiseDashboardViewSourceTests -only-testing:FocusSessionAppTests/TasksViewModelSoundTests -only-testing:FocusSessionAppTests/CurrentSessionViewModelTests -only-testing:FocusSessionAppTests/CurrentSessionViewSourceTests`

Expected: PASS

**Step 2: Run a macOS build**

Run:

`xcodebuild build -project /Users/xiakaiyang/Documents/New\ project/FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS'`

Expected: PASS
