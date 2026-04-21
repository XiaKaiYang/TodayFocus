# TodayFocus PK AI Supervision Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a macOS-only first release of TodayFocus supervised room PK with `Sign in with Apple`, CloudKit-backed room and leaderboard records, local camera and activity supervision, and violation evidence upload on confirmed violations.

**Architecture:** Keep the existing local focus-session flow as the primary session engine, add a dedicated account/PK CloudKit layer beside the current SwiftData productivity layer, and run supervision entirely on-device until a violation is confirmed. Public profile, room, session, leaderboard, and evidence records live in explicit CloudKit repositories while the existing SwiftData models keep private productivity data separate.

**Tech Stack:** SwiftUI, SwiftData, CloudKit, AuthenticationServices, AVFoundation, AppKit, ScreenCaptureKit, XCTest

---

### Task 1: Account Surface and Public Profile Bootstrap

**Files:**
- Create: `Apps/FocusSessionApp/Account/AccountIdentity.swift`
- Create: `Apps/FocusSessionApp/Account/AccountService.swift`
- Create: `Apps/FocusSessionApp/Cloud/Records/UserPublicProfileRecord.swift`
- Create: `Apps/FocusSessionApp/Cloud/Repositories/UserPublicProfileRepository.swift`
- Create: `Apps/FocusSessionApp/ViewModels/AccountViewModel.swift`
- Create: `Apps/FocusSessionApp/UI/Account/AccountDashboardView.swift`
- Modify: `Apps/FocusSessionApp/UI/AppShell/AppSection.swift`
- Modify: `Apps/FocusSessionApp/UI/AppShell/AppShellView.swift`
- Modify: `Apps/FocusSessionApp/ViewModels/SettingsViewModel.swift`
- Test: `Tests/FocusSessionAppTests/AccountViewModelTests.swift`
- Test: `Tests/FocusSessionAppTests/UserPublicProfileRepositoryTests.swift`

**Step 1: Write the failing account-state tests**

Add tests that assert:
- signed-out state shows account entry UI
- signed-in state exposes display name
- missing public profile triggers bootstrap save

**Step 2: Run account tests to verify failure**

Run: `xcodebuild test -scheme FocusSessionApp -only-testing:FocusSessionAppTests/AccountViewModelTests`

Expected: FAIL because account view model and repository do not exist.

**Step 3: Add minimal account identity and repository types**

Create `AccountIdentity`, `UserPublicProfileRecord`, and `UserPublicProfileRepository` with the smallest surface needed for tests.

**Step 4: Add `AccountService` and `AccountViewModel`**

Implement a thin service wrapper around `Sign in with Apple` and a view model that publishes:
- sign-in state
- profile bootstrap state
- error state

**Step 5: Add the account screen and shell entry**

Expose a new account/settings-adjacent entry in the shell so the user can sign in before entering supervised PK.

**Step 6: Run the account tests again**

Run: `xcodebuild test -scheme FocusSessionApp -only-testing:FocusSessionAppTests/AccountViewModelTests -only-testing:FocusSessionAppTests/UserPublicProfileRepositoryTests`

Expected: PASS.

**Step 7: Commit**

```bash
git add Apps/FocusSessionApp/Account Apps/FocusSessionApp/Cloud/Records/UserPublicProfileRecord.swift Apps/FocusSessionApp/Cloud/Repositories/UserPublicProfileRepository.swift Apps/FocusSessionApp/ViewModels/AccountViewModel.swift Apps/FocusSessionApp/UI/Account/AccountDashboardView.swift Apps/FocusSessionApp/UI/AppShell/AppSection.swift Apps/FocusSessionApp/UI/AppShell/AppShellView.swift Tests/FocusSessionAppTests/AccountViewModelTests.swift Tests/FocusSessionAppTests/UserPublicProfileRepositoryTests.swift
git commit -m "feat: add account bootstrap and public profile"
```

### Task 2: Room and Membership Cloud Models

**Files:**
- Create: `Apps/FocusSessionApp/Cloud/Records/RoomRecord.swift`
- Create: `Apps/FocusSessionApp/Cloud/Records/RoomMemberRecord.swift`
- Create: `Apps/FocusSessionApp/Cloud/Records/PKSessionRecord.swift`
- Create: `Apps/FocusSessionApp/Cloud/Repositories/RoomRepository.swift`
- Create: `Apps/FocusSessionApp/Cloud/Repositories/PKSessionRepository.swift`
- Create: `Apps/FocusSessionApp/PK/RoomModels.swift`
- Test: `Tests/FocusSessionAppTests/RoomRepositoryTests.swift`
- Test: `Tests/FocusSessionAppTests/PKSessionRepositoryTests.swift`

**Step 1: Write repository tests for room lifecycle**

Cover:
- create room
- join by invite code
- set member ready state
- start room session

**Step 2: Run the new room tests**

Run: `xcodebuild test -scheme FocusSessionApp -only-testing:FocusSessionAppTests/RoomRepositoryTests -only-testing:FocusSessionAppTests/PKSessionRepositoryTests`

Expected: FAIL because room record models and repositories are missing.

**Step 3: Implement CloudKit record mappers**

Create the room, member, and session record definitions with explicit field mapping and record-type constants.

**Step 4: Implement the repositories**

Add the minimal CRUD and lookup operations required by the tests:
- create room
- load room by invite code
- upsert member
- create current PK session

**Step 5: Re-run room tests**

Run the same `xcodebuild test` command.

Expected: PASS.

**Step 6: Commit**

```bash
git add Apps/FocusSessionApp/Cloud/Records/RoomRecord.swift Apps/FocusSessionApp/Cloud/Records/RoomMemberRecord.swift Apps/FocusSessionApp/Cloud/Records/PKSessionRecord.swift Apps/FocusSessionApp/Cloud/Repositories/RoomRepository.swift Apps/FocusSessionApp/Cloud/Repositories/PKSessionRepository.swift Apps/FocusSessionApp/PK/RoomModels.swift Tests/FocusSessionAppTests/RoomRepositoryTests.swift Tests/FocusSessionAppTests/PKSessionRepositoryTests.swift
git commit -m "feat: add room and pk session cloud models"
```

### Task 3: Room Lobby UI and View Model

**Files:**
- Create: `Apps/FocusSessionApp/ViewModels/RoomLobbyViewModel.swift`
- Create: `Apps/FocusSessionApp/UI/PK/RoomLobbyView.swift`
- Create: `Apps/FocusSessionApp/UI/PK/JoinRoomSheet.swift`
- Modify: `Apps/FocusSessionApp/UI/AppShell/AppSection.swift`
- Modify: `Apps/FocusSessionApp/UI/AppShell/AppShellView.swift`
- Test: `Tests/FocusSessionAppTests/RoomLobbyViewModelTests.swift`
- Test: `Tests/FocusSessionAppTests/RoomLobbyViewSourceTests.swift`

**Step 1: Write failing lobby tests**

Cover:
- owner can create room
- member can join by code
- ready state updates appear in the room model
- start button only enables for owner when everyone is ready

**Step 2: Run lobby tests to confirm failure**

Run: `xcodebuild test -scheme FocusSessionApp -only-testing:FocusSessionAppTests/RoomLobbyViewModelTests -only-testing:FocusSessionAppTests/RoomLobbyViewSourceTests`

Expected: FAIL because the lobby screen and view model do not exist.

**Step 3: Implement `RoomLobbyViewModel`**

Add published state for:
- current room
- current user membership
- invite code
- loading and error state

**Step 4: Build the SwiftUI lobby**

Add:
- create room action
- join room action
- room member list
- ready toggle
- owner start button

**Step 5: Re-run lobby tests**

Expected: PASS.

**Step 6: Commit**

```bash
git add Apps/FocusSessionApp/ViewModels/RoomLobbyViewModel.swift Apps/FocusSessionApp/UI/PK/RoomLobbyView.swift Apps/FocusSessionApp/UI/PK/JoinRoomSheet.swift Apps/FocusSessionApp/UI/AppShell/AppSection.swift Apps/FocusSessionApp/UI/AppShell/AppShellView.swift Tests/FocusSessionAppTests/RoomLobbyViewModelTests.swift Tests/FocusSessionAppTests/RoomLobbyViewSourceTests.swift
git commit -m "feat: add room lobby flow"
```

### Task 4: PK Session Binding to Existing Focus Flow

**Files:**
- Create: `Apps/FocusSessionApp/PK/PKSessionCoordinator.swift`
- Modify: `Apps/FocusSessionApp/ViewModels/CurrentSessionViewModel.swift`
- Modify: `Apps/FocusSessionApp/ViewModels/RoomLobbyViewModel.swift`
- Modify: `Apps/FocusSessionApp/UI/CurrentSession/CurrentSessionView.swift`
- Test: `Tests/FocusSessionAppTests/PKSessionCoordinatorTests.swift`
- Test: `Tests/FocusSessionAppTests/CurrentSessionViewModelPKTests.swift`

**Step 1: Write failing integration tests**

Cover:
- room start creates a bound PK session
- local focus start updates PK session state
- finish and abandon paths mark the PK session correctly

**Step 2: Run PK integration tests**

Run: `xcodebuild test -scheme FocusSessionApp -only-testing:FocusSessionAppTests/PKSessionCoordinatorTests -only-testing:FocusSessionAppTests/CurrentSessionViewModelPKTests`

Expected: FAIL because PK coordination does not exist.

**Step 3: Add `PKSessionCoordinator`**

Implement a small coordinator that translates local focus-session lifecycle changes into PK session updates.

**Step 4: Inject PK coordination into `CurrentSessionViewModel`**

Do not rewrite the local session engine. Add hooks so the existing focus flow remains the source of truth for session timing.

**Step 5: Re-run PK integration tests**

Expected: PASS.

**Step 6: Commit**

```bash
git add Apps/FocusSessionApp/PK/PKSessionCoordinator.swift Apps/FocusSessionApp/ViewModels/CurrentSessionViewModel.swift Apps/FocusSessionApp/ViewModels/RoomLobbyViewModel.swift Apps/FocusSessionApp/UI/CurrentSession/CurrentSessionView.swift Tests/FocusSessionAppTests/PKSessionCoordinatorTests.swift Tests/FocusSessionAppTests/CurrentSessionViewModelPKTests.swift
git commit -m "feat: bind pk session to focus flow"
```

### Task 5: Supervision Permission Gate and Runtime State Machine

**Files:**
- Create: `Apps/FocusSessionApp/Supervision/SupervisionPermissionState.swift`
- Create: `Apps/FocusSessionApp/Supervision/SupervisionCoordinator.swift`
- Create: `Apps/FocusSessionApp/Supervision/SupervisionStateSnapshot.swift`
- Modify: `Apps/FocusSessionApp/ViewModels/RoomLobbyViewModel.swift`
- Modify: `Apps/FocusSessionApp/UI/PK/RoomLobbyView.swift`
- Test: `Tests/FocusSessionAppTests/SupervisionCoordinatorTests.swift`

**Step 1: Write failing supervision-gate tests**

Cover:
- supervised PK requires account login
- supervised PK requires camera permission
- supervised PK requires screen-recording permission
- missing permission downgrades the room mode

**Step 2: Run tests to verify failure**

Run: `xcodebuild test -scheme FocusSessionApp -only-testing:FocusSessionAppTests/SupervisionCoordinatorTests`

Expected: FAIL because supervision coordination is missing.

**Step 3: Implement permission-state types**

Create enums and snapshots for:
- account requirement
- camera permission
- screen-recording permission
- supervised eligibility

**Step 4: Implement `SupervisionCoordinator`**

Add a state machine that:
- checks permissions
- starts or blocks supervision mode
- exposes downgrade reasons

**Step 5: Re-run supervision tests**

Expected: PASS.

**Step 6: Commit**

```bash
git add Apps/FocusSessionApp/Supervision/SupervisionPermissionState.swift Apps/FocusSessionApp/Supervision/SupervisionCoordinator.swift Apps/FocusSessionApp/Supervision/SupervisionStateSnapshot.swift Apps/FocusSessionApp/ViewModels/RoomLobbyViewModel.swift Apps/FocusSessionApp/UI/PK/RoomLobbyView.swift Tests/FocusSessionAppTests/SupervisionCoordinatorTests.swift
git commit -m "feat: add supervision gating"
```

### Task 6: Camera-Based Seat Monitor

**Files:**
- Create: `Apps/FocusSessionApp/Supervision/SeatMonitor.swift`
- Create: `Apps/FocusSessionApp/Supervision/SeatMonitorFramePipeline.swift`
- Modify: `Apps/FocusSessionApp/Supervision/SupervisionCoordinator.swift`
- Test: `Tests/FocusSessionAppTests/SeatMonitorTests.swift`

**Step 1: Write failing seat monitor tests**

Cover:
- monitor starts when camera is available
- repeated no-person frames transition to `away`
- person-present frames transition back to `present`

**Step 2: Run seat monitor tests**

Run: `xcodebuild test -scheme FocusSessionApp -only-testing:FocusSessionAppTests/SeatMonitorTests`

Expected: FAIL because seat monitor does not exist.

**Step 3: Implement a minimal frame pipeline abstraction**

Do not tie business rules directly to `AVCaptureSession`. Create a testable adapter layer that emits person-present / person-missing observations.

**Step 4: Implement `SeatMonitor` threshold logic**

Add time-based smoothing so one bad frame does not create a violation.

**Step 5: Re-run seat tests**

Expected: PASS.

**Step 6: Commit**

```bash
git add Apps/FocusSessionApp/Supervision/SeatMonitor.swift Apps/FocusSessionApp/Supervision/SeatMonitorFramePipeline.swift Apps/FocusSessionApp/Supervision/SupervisionCoordinator.swift Tests/FocusSessionAppTests/SeatMonitorTests.swift
git commit -m "feat: add camera seat monitor"
```

### Task 7: Screen Activity Monitor

**Files:**
- Create: `Apps/FocusSessionApp/Supervision/ActivityMonitor.swift`
- Create: `Apps/FocusSessionApp/Supervision/ScreenCapturePermissionService.swift`
- Modify: `Apps/FocusSessionApp/Supervision/SupervisionCoordinator.swift`
- Test: `Tests/FocusSessionAppTests/ActivityMonitorTests.swift`

**Step 1: Write failing activity tests**

Cover:
- user interaction resets inactivity timer
- inactivity threshold transitions to `inactive`
- fresh interaction returns state to `active`

**Step 2: Run activity tests**

Run: `xcodebuild test -scheme FocusSessionApp -only-testing:FocusSessionAppTests/ActivityMonitorTests`

Expected: FAIL because activity monitor types do not exist.

**Step 3: Implement the permission service**

Wrap the screen-recording permission checks in a small, mockable service.

**Step 4: Implement `ActivityMonitor`**

Track:
- last user interaction
- last active timestamp
- current activity state

Use ScreenCaptureKit only where needed for permission flow and future evidence capture, not for every state transition.

**Step 5: Re-run activity tests**

Expected: PASS.

**Step 6: Commit**

```bash
git add Apps/FocusSessionApp/Supervision/ActivityMonitor.swift Apps/FocusSessionApp/Supervision/ScreenCapturePermissionService.swift Apps/FocusSessionApp/Supervision/SupervisionCoordinator.swift Tests/FocusSessionAppTests/ActivityMonitorTests.swift
git commit -m "feat: add activity monitor"
```

### Task 8: Violation Events and Evidence Upload

**Files:**
- Create: `Apps/FocusSessionApp/Cloud/Records/SupervisionStateRecord.swift`
- Create: `Apps/FocusSessionApp/Cloud/Records/ViolationEventRecord.swift`
- Create: `Apps/FocusSessionApp/Cloud/Records/ViolationEvidenceRecord.swift`
- Create: `Apps/FocusSessionApp/Cloud/Repositories/SupervisionRepository.swift`
- Create: `Apps/FocusSessionApp/Supervision/EvidenceCaptureService.swift`
- Modify: `Apps/FocusSessionApp/Supervision/SupervisionCoordinator.swift`
- Test: `Tests/FocusSessionAppTests/SupervisionRepositoryTests.swift`
- Test: `Tests/FocusSessionAppTests/EvidenceCaptureServiceTests.swift`

**Step 1: Write failing repository and evidence tests**

Cover:
- state heartbeat upserts current supervision snapshot
- confirmed away event creates `ViolationEvent`
- confirmed violation captures both evidence types
- evidence records carry expiry metadata

**Step 2: Run tests**

Run: `xcodebuild test -scheme FocusSessionApp -only-testing:FocusSessionAppTests/SupervisionRepositoryTests -only-testing:FocusSessionAppTests/EvidenceCaptureServiceTests`

Expected: FAIL because record models and evidence service do not exist.

**Step 3: Implement supervision and violation record types**

Map all required fields explicitly and keep asset uploads isolated in the repository layer.

**Step 4: Implement `EvidenceCaptureService`**

Add:
- screen snapshot capture
- camera frame capture
- local watermarking metadata
- placeholder redaction hooks

**Step 5: Wire confirmed violations through `SupervisionCoordinator`**

Only capture evidence after the violation threshold is satisfied.

**Step 6: Re-run tests**

Expected: PASS.

**Step 7: Commit**

```bash
git add Apps/FocusSessionApp/Cloud/Records/SupervisionStateRecord.swift Apps/FocusSessionApp/Cloud/Records/ViolationEventRecord.swift Apps/FocusSessionApp/Cloud/Records/ViolationEvidenceRecord.swift Apps/FocusSessionApp/Cloud/Repositories/SupervisionRepository.swift Apps/FocusSessionApp/Supervision/EvidenceCaptureService.swift Apps/FocusSessionApp/Supervision/SupervisionCoordinator.swift Tests/FocusSessionAppTests/SupervisionRepositoryTests.swift Tests/FocusSessionAppTests/EvidenceCaptureServiceTests.swift
git commit -m "feat: add violation events and evidence upload"
```

### Task 9: Leaderboard Aggregation and Display

**Files:**
- Create: `Apps/FocusSessionApp/Cloud/Records/LeaderboardBucketRecord.swift`
- Create: `Apps/FocusSessionApp/Cloud/Repositories/LeaderboardRepository.swift`
- Create: `Apps/FocusSessionApp/ViewModels/LeaderboardViewModel.swift`
- Create: `Apps/FocusSessionApp/UI/PK/LeaderboardView.swift`
- Modify: `Apps/FocusSessionApp/UI/AppShell/AppSection.swift`
- Modify: `Apps/FocusSessionApp/UI/AppShell/AppShellView.swift`
- Test: `Tests/FocusSessionAppTests/LeaderboardRepositoryTests.swift`
- Test: `Tests/FocusSessionAppTests/LeaderboardViewModelTests.swift`

**Step 1: Write failing leaderboard tests**

Cover:
- session result updates day bucket
- session result updates week bucket
- higher score sorts first
- penalties reduce effective score

**Step 2: Run leaderboard tests**

Run: `xcodebuild test -scheme FocusSessionApp -only-testing:FocusSessionAppTests/LeaderboardRepositoryTests -only-testing:FocusSessionAppTests/LeaderboardViewModelTests`

Expected: FAIL because leaderboard types do not exist.

**Step 3: Implement the bucket record and repository**

Keep the score formula simple and explicit:

`score = verified_focus_minutes - penalty_weight * penalty_count`

**Step 4: Implement the SwiftUI leaderboard screen**

Include:
- day/week switch
- rank
- display name
- verified minutes
- wins
- penalties

**Step 5: Re-run leaderboard tests**

Expected: PASS.

**Step 6: Commit**

```bash
git add Apps/FocusSessionApp/Cloud/Records/LeaderboardBucketRecord.swift Apps/FocusSessionApp/Cloud/Repositories/LeaderboardRepository.swift Apps/FocusSessionApp/ViewModels/LeaderboardViewModel.swift Apps/FocusSessionApp/UI/PK/LeaderboardView.swift Apps/FocusSessionApp/UI/AppShell/AppSection.swift Apps/FocusSessionApp/UI/AppShell/AppShellView.swift Tests/FocusSessionAppTests/LeaderboardRepositoryTests.swift Tests/FocusSessionAppTests/LeaderboardViewModelTests.swift
git commit -m "feat: add leaderboard flow"
```

### Task 10: Hardening, Privacy Rules, and Regression Coverage

**Files:**
- Modify: `Apps/FocusSessionApp/UI/Settings/SettingsDashboardView.swift`
- Modify: `Apps/FocusSessionApp/ViewModels/SettingsViewModel.swift`
- Create: `Apps/FocusSessionApp/UI/PK/SupervisionPrivacySheet.swift`
- Test: `Tests/FocusSessionAppTests/PermissionDowngradeFlowTests.swift`
- Test: `Tests/FocusSessionAppTests/SettingsViewModelSupervisionTests.swift`
- Test: `Tests/FocusSessionAppTests/LeaderboardRegressionTests.swift`

**Step 1: Write failing hardening tests**

Cover:
- missing permission downgrades supervised PK
- evidence is owner/user scoped
- expired evidence is hidden
- settings surface explains supervision limits clearly

**Step 2: Run hardening tests**

Run: `xcodebuild test -scheme FocusSessionApp -only-testing:FocusSessionAppTests/PermissionDowngradeFlowTests -only-testing:FocusSessionAppTests/SettingsViewModelSupervisionTests -only-testing:FocusSessionAppTests/LeaderboardRegressionTests`

Expected: FAIL because these downgrade and privacy paths are not implemented.

**Step 3: Add privacy and downgrade UI**

Expose:
- permission explanations
- supervised PK eligibility summary
- evidence retention copy
- downgrade fallback behavior

**Step 4: Re-run hardening tests**

Expected: PASS.

**Step 5: Run the focused end-to-end regression suite**

Run:

```bash
xcodebuild test -scheme FocusSessionApp \
  -only-testing:FocusSessionAppTests/AccountViewModelTests \
  -only-testing:FocusSessionAppTests/RoomLobbyViewModelTests \
  -only-testing:FocusSessionAppTests/CurrentSessionViewModelPKTests \
  -only-testing:FocusSessionAppTests/SupervisionCoordinatorTests \
  -only-testing:FocusSessionAppTests/LeaderboardViewModelTests
```

Expected: PASS.

**Step 6: Commit**

```bash
git add Apps/FocusSessionApp/UI/Settings/SettingsDashboardView.swift Apps/FocusSessionApp/ViewModels/SettingsViewModel.swift Apps/FocusSessionApp/UI/PK/SupervisionPrivacySheet.swift Tests/FocusSessionAppTests/PermissionDowngradeFlowTests.swift Tests/FocusSessionAppTests/SettingsViewModelSupervisionTests.swift Tests/FocusSessionAppTests/LeaderboardRegressionTests.swift
git commit -m "feat: harden supervised pk flows"
```

## Notes for Execution

- Do not rewrite the existing SwiftData productivity stack.
- Do not move tasks, goals, or blocker logic into PK repositories.
- Keep supervision logic testable by isolating hardware and CloudKit edges behind small adapters.
- Keep score calculation explainable and stable in one place.
- Prefer local-first runtime behavior with delayed sync over blocking the session on network operations.
- Preserve the current macOS focus flow and treat PK as an attached layer.
