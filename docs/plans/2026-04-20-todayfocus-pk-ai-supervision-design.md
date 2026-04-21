# TodayFocus Account, Room PK, and AI Supervision Design

**Date:** 2026-04-20

**Status:** Approved for planning

**Goal:** Upgrade TodayFocus from a single-device focus app into a macOS-only product with `Sign in with Apple`, room-based focus PK, leaderboard support, and basic AI supervision based on seat presence and screen activity.

## Product Scope

### In Scope

- `macOS only` for the first release
- `Sign in with Apple` as the only account entry point
- room-based focus PK
- public leaderboard support
- local AI supervision
- camera-based seat-presence detection
- screen-activity supervision
- local-first violation detection
- upload evidence only when a violation is confirmed

### Out of Scope

- iPhone support
- email/password accounts
- guest mode for ranked PK
- continuous video upload
- continuous screen upload
- screen-content classification
- social feed, chat, gifting, or complex social graph
- strong anti-cheat guarantees beyond seat presence and activity checks

## Current Codebase Constraints

The existing app already has a CloudKit-backed SwiftData container in [Apps/FocusSessionApp/Data/FocusSessionModelContainer.swift](/Users/xiakaiyang/Documents/New project/Apps/FocusSessionApp/Data/FocusSessionModelContainer.swift:1). The macOS app and iOS app entitlements already include CloudKit capabilities in [Config/Entitlements/FocusSessionApp.entitlements](/Users/xiakaiyang/Documents/New project/Config/Entitlements/FocusSessionApp.entitlements:1) and [Config/Entitlements/FocusSessionMobileApp.entitlements](/Users/xiakaiyang/Documents/New project/Config/Entitlements/FocusSessionMobileApp.entitlements:1). The settings surface already treats iOS data as synced CloudKit-backed data in [Apps/FocusSessionApp/UI/Settings/SettingsDashboardView.swift](/Users/xiakaiyang/Documents/New project/Apps/FocusSessionApp/UI/Settings/SettingsDashboardView.swift:1).

The codebase does not currently expose a dedicated account layer, room PK layer, screen-capture supervision pipeline, camera pipeline, or Vision/OCR supervision logic. That means the first release should extend the current product in layers instead of rewriting the app around social features.

## Recommended Architecture

The recommended direction is an Apple-native MVP:

- authentication with `Sign in with Apple`
- existing personal productivity data continues to use SwiftData + CloudKit
- PK, account profile, room, leaderboard, and violation records use explicit CloudKit records
- supervision runs entirely on macOS locally
- evidence is uploaded only for confirmed violations

This preserves the current app's main focus flow and treats PK as an additional layer rather than a replacement for the existing session engine.

## System Layers

### 1. Personal Productivity Layer

This remains the current SwiftData + CloudKit path. It covers:

- tasks
- goals
- focus history
- blocker rules
- distraction events

This layer continues to serve the user's private workflow and should not become the source of truth for public PK room state.

### 2. PK Cloud Domain

This new layer holds public and shared multiplayer records:

- user public profile
- room metadata
- room membership
- PK session state
- supervision state snapshots
- violation events
- violation evidence
- leaderboard buckets

This layer must be modeled explicitly so that room and leaderboard access patterns stay separate from private productivity sync behavior.

### 3. Local Supervision Layer

This layer runs only on macOS and is responsible for:

- camera permission checks
- screen-recording permission checks
- seat-presence monitoring
- screen-activity monitoring
- violation threshold evaluation
- local evidence capture
- deferred upload once a violation is confirmed

The supervision layer never replaces the local focus session controller. It only publishes supervision state to the PK feature.

## Account Design

The first release uses `Sign in with Apple` only.

Why this is the best fit:

- matches the macOS-only release
- reduces backend complexity
- avoids building a custom password stack
- fits naturally with a CloudKit-based backend

The app stores a stable internal `userID` mapped from the Apple identity and keeps a `UserPublicProfile` record for room and leaderboard display.

## Data Model

### Personal Local/Private Domain

Keep using the current SwiftData-backed models for:

- `StoredFocusSessionRecord`
- `StoredTask`
- `StoredPlanGoal`
- `StoredBlockingRule`
- `StoredDistractionEvent`

### Public Cloud Records

#### `UserPublicProfile`

Fields:

- `userID`
- `appleUserStableIDHash`
- `displayName`
- `avatarAsset`
- `createdAt`
- `totalVerifiedMinutes`
- `totalWins`
- `totalPenaltyCount`
- `lastLeaderboardScore`

#### `LeaderboardBucket`

Fields:

- `bucketType`
- `bucketStartAt`
- `userID`
- `verifiedFocusMinutes`
- `wins`
- `penaltyCount`
- `score`
- `updatedAt`

### Room-Scoped Shared Records

#### `Room`

Fields:

- `roomID`
- `ownerUserID`
- `title`
- `inviteCode`
- `status`
- `plannedMinutes`
- `createdAt`
- `startedAt`
- `endedAt`
- `currentSessionID`

#### `RoomMember`

Fields:

- `roomID`
- `userID`
- `role`
- `joinState`
- `readyState`
- `lastHeartbeatAt`
- `currentSeatState`
- `currentActivityState`
- `sessionScore`

#### `PKSession`

Fields:

- `sessionID`
- `roomID`
- `startAt`
- `plannedMinutes`
- `endAt`
- `status`
- `winnerUserID`
- `scoreVersion`

#### `SupervisionState`

Fields:

- `sessionID`
- `roomID`
- `userID`
- `seatState`
- `activityState`
- `lastSeatChangeAt`
- `lastActiveAt`
- `lastUploadedAt`
- `clientModelVersion`

#### `ViolationEvent`

Fields:

- `eventID`
- `sessionID`
- `roomID`
- `userID`
- `violationType`
- `startedAt`
- `endedAt`
- `durationSeconds`
- `penaltyScore`
- `evidenceStatus`

#### `ViolationEvidence`

Fields:

- `evidenceID`
- `eventID`
- `userID`
- `evidenceType`
- `capturedAt`
- `asset`
- `thumbnailAsset`
- `redactionVersion`
- `expiresAt`

## End-to-End Flow

### Login and Profile

The user signs in with Apple. On success, the app creates or updates a `UserPublicProfile` record and establishes the app-internal user identity for room and leaderboard features.

### Room Creation and Join

The room owner creates a room with a title, duration, and invite code. Other users join through the invite code and become `RoomMember` records. The room lobby shows online state, ready state, and current member summary without streaming raw camera or screen content.

### Session Start

When the owner starts the room, the system creates a `PKSession` and binds it to the existing local focus session flow. The local session engine remains the primary controller for time and focus lifecycle.

### Supervision Runtime

Two local monitors start at the same time:

- `SeatMonitor` for camera-based presence
- `ActivityMonitor` for screen-activity state

These monitors output only state transitions and timestamps under normal conditions.

### Violation Trigger

If the user remains away or inactive beyond configured thresholds, the app creates a `ViolationEvent`. At that moment only, the app captures evidence and uploads a screen snapshot plus a camera frame after local redaction.

### Room Display

Room members see lightweight state information such as:

- focusing
- briefly away
- inactive
- violation count
- effective verified minutes
- score

The first release does not expose live video or full live screen sharing.

### Session End and Ranking

At the end of a session, the app computes a simple and explainable score:

`score = verified_focus_minutes - penalty_weight * penalty_count`

The app writes the winner to `PKSession`, updates `RoomMember.sessionScore`, and updates day/week leaderboard buckets.

## Permissions and Privacy

Formal supervised PK participation requires:

- `Sign in with Apple`
- active iCloud login on macOS
- camera permission
- screen-recording permission

If any of these are missing, the user may enter only a downgraded non-supervised mode.

Privacy rules:

- no continuous camera upload
- no continuous screen upload
- no realtime surveillance stream
- evidence uploaded only for confirmed violations
- evidence visible only to the room owner and the violating user in the first release
- evidence auto-expires after a short retention window, recommended at 7 days

## Anti-Cheat Boundary

This release does not try to prove that the user is doing the correct work. It only measures whether:

- the user remains in front of the device
- the device remains active

This should be presented as supervised PK, not as full cheating detection.

## Failure and Degradation Rules

- if camera permission is denied, supervised PK is unavailable
- if screen-recording permission is denied, supervised PK is unavailable
- if the network drops, local focus and supervision continue, while cloud sync is marked delayed
- queued supervision updates and evidence uploads are retried when connectivity returns
- if CloudKit is unavailable, the app falls back to local focus mode only

## Milestone Order

1. account and public profile
2. room and membership data model
3. room lobby UI
4. PK session binding to local focus flow
5. local supervision permissions and runtime state
6. camera seat monitor
7. activity monitor
8. violation event and evidence pipeline
9. leaderboard aggregation and UI
10. privacy, error handling, and hardening

## Why This Design Was Chosen

This design matches the existing codebase and your first-release goals. The project already has Apple-platform sync foundations, so the fastest end-to-end path is to preserve the current single-user focus core and add account, room PK, and supervision as layered systems around it. That keeps the product coherent, reduces rewrite risk, and gives you a realistic path to a working macOS-only MVP.
