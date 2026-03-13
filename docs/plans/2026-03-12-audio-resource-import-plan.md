# Audio Resource Import Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Import all unique owned audio assets from `Session.app` and `TickTick.app` into the project, track provenance, and ensure Xcode copies them into the app bundle.

**Architecture:** Keep the imported assets under `Apps/FocusSessionApp/Resources/Audio`, store provenance in a manifest file beside the imported resources, and attach the top-level `Audio` directory to the app target as a folder reference in `project.pbxproj`.

**Tech Stack:** Shell file operations for copying owned binary assets, Xcode project file edits, XCTest source/resource assertions, focused `xcodebuild` verification.

---

### Task 1: Lock in the intended resource layout with failing tests

**Files:**
- Add: `/Users/xiakaiyang/Documents/New project/Tests/FocusSessionAppTests/AudioResourceImportSourceTests.swift`

**Step 1: Write the failing tests**

Add tests that require:
- the repository to contain:
  - `Apps/FocusSessionApp/Resources/Audio/Session/SoundEffects`
  - `Apps/FocusSessionApp/Resources/Audio/Session/WhiteNoise`
  - `Apps/FocusSessionApp/Resources/Audio/TickTick/SoundEffects`
- the import manifest file to exist
- representative filenames from each source set to exist in the expected directory

**Step 2: Run the focused test**

Run:

`xcodebuild test -project /Users/xiakaiyang/Documents/New\ project/FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/AudioResourceImportSourceTests`

Expected: FAIL because the resource tree and manifest do not exist yet.

### Task 2: Lock in Xcode resource wiring with a failing source assertion

**Files:**
- Modify: `/Users/xiakaiyang/Documents/New project/Tests/FocusSessionAppTests/AudioResourceImportSourceTests.swift`

**Step 1: Add the failing project assertion**

Require `FocusSession.xcodeproj/project.pbxproj` to:
- declare a folder reference for `Resources/Audio`
- include that folder reference in the app `PBXResourcesBuildPhase`

**Step 2: Re-run the focused test**

Run the same `xcodebuild test` command from Task 1.

Expected: FAIL because the project does not yet reference the imported audio folder.

### Task 3: Import the audio assets and write the manifest

**Files:**
- Add: `/Users/xiakaiyang/Documents/New project/Apps/FocusSessionApp/Resources/Audio/...`
- Add: `/Users/xiakaiyang/Documents/New project/Apps/FocusSessionApp/Resources/Audio/import-manifest.json`

**Step 1: Create the resource tree**

Create the three target directories under `Apps/FocusSessionApp/Resources/Audio`.

**Step 2: Copy all unique assets**

Copy:
- `6` unique prompt sounds from `Session.app`
- `9` white-noise tracks from `Session.app`
- `18` prompt sounds from `TickTick.app`

Do not duplicate the extra `Session.app/Contents/Resources/Assets/Audio` copies because they are byte-identical to the top-level prompt sounds.

**Step 3: Generate the manifest**

Record, for every imported file:
- destination relative path in the repository
- source app
- original absolute bundle path

### Task 4: Wire the imported audio folder into the Xcode project

**Files:**
- Modify: `/Users/xiakaiyang/Documents/New project/FocusSession.xcodeproj/project.pbxproj`

**Step 1: Add the folder reference**

Add a blue-folder-style file reference for `Resources/Audio` under the `FocusSessionApp` group.

**Step 2: Add it to resources**

Add the folder reference to the app `PBXResourcesBuildPhase` so the full directory tree is copied into the app bundle.

### Task 5: Run focused verification

**Files:**
- Test: `/Users/xiakaiyang/Documents/New project/Tests/FocusSessionAppTests/AudioResourceImportSourceTests.swift`

**Step 1: Run the focused resource test**

Run:

`xcodebuild test -project /Users/xiakaiyang/Documents/New\ project/FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/AudioResourceImportSourceTests`

Expected: PASS

**Step 2: Run a macOS build and inspect the built bundle**

Run a focused build:

`xcodebuild build -project /Users/xiakaiyang/Documents/New\ project/FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS'`

Then verify the built app bundle contains the imported `Audio` tree and representative files from:
- `Session/SoundEffects`
- `Session/WhiteNoise`
- `TickTick/SoundEffects`
