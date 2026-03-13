# Task Plan: Recreate a macOS focus app inspired by Session

## Goal
Design and build a legally safe macOS app that recreates the core Session experience without copying proprietary code or bundled assets.

## Current Phase
Phase 4

## Phases
### Phase 1: Requirements & Discovery
- [x] Inspect the current project workspace
- [x] Inspect the installed `Session.app` bundle structure
- [x] Confirm the target scope with the user
- [x] Confirm backend and account expectations
- [x] Confirm whether system-level blocking is required in the first full local version
- [x] Capture findings in `findings.md`
- **Status:** complete

### Phase 2: Product & Technical Design
- [x] Propose implementation approaches
- [x] Recommend an implementation scope
- [x] Write the approved design doc
- **Status:** complete

### Phase 3: Implementation Planning
- [x] Create a concrete implementation plan
- [x] Decide the initial project structure
- [x] Sequence the first build milestones
- **Status:** complete

### Phase 4: Implementation
- [ ] Build the approved MVP
- [ ] Verify the key user flows
- [ ] Iterate on polish
- **Status:** in_progress
- Current completed slices:
  - Interactive `Current Session` flow
  - Runtime snapshot persistence
  - App shell navigation
  - Task list and task-to-focus launch flow
  - Analytics dashboard
  - Notes-backed current session workspace with recent session history
  - Shared light-surface visual system applied across the shell and major product pages
  - Transparent idle current-session stage and hub-based dial redesign
- Next likely slices:
  - Blocker configuration and event logging
  - Settings replacement and preferences wiring
  - Visual polish pass on the remaining current-session edge cases
  - Continue interaction polish now that white-text regressions are blocked by theme tokens and source audit
  - Continue form readability polish now that guarded Create/Blocker fields use custom prompt and label rendering

### Phase 5: Delivery
- [ ] Summarize what was built
- [ ] Call out remaining gaps versus the original app
- [ ] Hand off next-step options
- **Status:** pending

## Key Questions
1. Does the user want an MVP of the core experience or a broader, near-complete reimplementation?
2. Should the recreated app include accounts, sync, and cloud-backed features, or remain fully local-first?
3. Must the first local version include system-level website and app blocking?

## Decisions Made
| Decision | Rationale |
|----------|-----------|
| Use a design-first workflow before implementation | The requested app is large enough that an unscoped build would likely waste time. |
| Treat this as a clean-room reimplementation | We can recreate functionality and interaction patterns without copying proprietary code or assets. |
| Aim for a near-complete product experience rather than a narrow MVP | User explicitly asked to get as close to the original app as practical. |
| Use a native macOS architecture built with SwiftUI plus AppKit integration | This best matches the desired product feel and supports menu bar, intents, widgets, notifications, and blocker integrations cleanly. |
| Use layered delivery while preserving the full-product architecture from day one | This keeps the system extensible without turning the first build into a dead-end prototype. |
| Target macOS 15.0+ and Swift 6.2 for the first implementation pass | This simplifies SwiftUI, WidgetKit, App Intents, and modern data-flow adoption on the current machine. |
| Use XcodeGen for reproducible multi-target project generation | Homebrew is available, `xcodegen` is missing, and generated projects are safer than hand-editing `.pbxproj`. |
| Disable code signing during the initial local scaffold phase | This avoids local signing blockers while the project structure and targets are still being stabilized. |

## Errors Encountered
| Error | Attempt | Resolution |
|-------|---------|------------|
| `git status` failed because the workspace is not a git repository | 1 | Continue without git assumptions and track work through planning files. |
| `FocusSessionIntents` failed with unsupported target type `app-extension.intents-service` on macOS | 1 | Switched the target to a generic `app-extension` and configured the intents service via `NSExtensionPointIdentifier`. |
| `FocusSessionSafari` initially had no generated scheme | 1 | Added an explicit `schemes` entry for `FocusSessionSafari` in `project.yml`. |

## Notes
- Re-read this plan before major decisions.
- Keep scope disciplined so the first build is shippable.
