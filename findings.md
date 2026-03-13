# Findings & Decisions

## Requirements
- User wants to recreate the installed macOS focus app `Session`.
- The likely goal is a runnable macOS application, not just a visual mock.
- We should reproduce the experience while avoiding direct reuse of proprietary code and assets.
- The target is to get as close as practical to the original product experience, not just the core timer flow.
- The user prefers a macOS-local full experience rather than account, sync, or cloud-backed features in the first version.

## Research Findings
- The current workspace is minimal and does not already contain an app project.
- `/Applications/Session.app/Contents` shows a native macOS bundle structure.
- The app includes widget and intent extensions, indicating deep platform integration.
- The inspected bundle also includes a login-item helper app, but no separately visible network/system extension in the paths inspected.
- The bundle contains localized resources, audio files, an app icon, storyboard resources, and a Core Data model.
- `Info.plist` references productivity features such as focus sessions, projects, analytics/time tracking, website blocking, Siri intents, and calendar access.
- `Localizable.strings` suggests a large product surface: focus and break timers, session editing, categories/projects, reflections, analytics, calendar sync, background sound, automation, notifications, menu bar behavior, export, and app/website blocking.
- String keys indicate both allow-list and deny-list concepts for blockers, plus separate behavior on session and break.
- `Intents.intentdefinition` confirms system integrations for starting sessions, toggling pause, contextual actions, and querying total focus time.
- Executable symbol strings suggest an architecture built around session state machines, Core Data persistence, menu bar UI, calendar views, analytics containers, project query/command services, background noise, window tracking, and dedicated website/app blocker components.
- Apple documentation confirms `AppIntents` remain the primary way to expose app actions to Shortcuts and Siri, and `WidgetKit` configurable widgets use app intents plus an `AppIntentTimelineProvider`.
- Apple documentation confirms login items are handled through `SMAppService`, which fits a contained helper app approach.
- Apple documentation confirms `NSWorkspace` posts activation notifications for applications, which is suitable for detecting blocked foreground apps locally.
- Apple documentation confirms Safari content blocking can be shipped through a Safari web extension or content blocker extension bundled with the Mac app.
- Apple’s program terms indicate `Network Extension` access requires Apple-granted entitlement approval and may be denied or revoked, so a system-wide website blocker cannot rely on that path alone.
- The current machine has `Xcode 26.2`, `Swift 6.2.3`, and `Homebrew 5.0.16`; `xcodegen` is not installed yet.
- `xcodegen 2.45.2` is now installed and the project scaffold has been generated successfully from `project.yml`.
- The standalone scaffold targets `FocusSessionApp`, `FocusSessionHelper`, `FocusSessionWidget`, `FocusSessionIntents`, and `FocusSessionSafari` all build locally.
- A local Swift package `Packages/FocusSessionCore` now exists and contains the first domain models plus the first reducer/state-machine slice.
- The main app now has an operable `Current Session` vertical slice with start, pause, resume, extend, finish, and abandon interactions backed by reducer-driven state transitions.
- Runtime snapshots now round-trip through JSON storage, support explicit clearing, and are synchronized from `CurrentSessionViewModel` on successful session state changes.
- The app now boots into a real `NavigationSplitView` shell with sidebar destinations for `Current Session`, `Analytics`, `Projects`, `Blocker`, and `Settings`.
- The current `Settings` scene now uses a dedicated placeholder root instead of a bare text node, keeping the window hierarchy aligned with the app shell structure.
- The old `Projects` concept has been removed from the user-facing product in favor of a task-first flow where tasks can directly launch a pomodoro session.
- The `Analytics` section is now a real vertical slice with `Today`, `This Week`, `All Time`, and `Avg Session` summary metrics, a 7-day trend view, project breakdowns, and recent completed sessions.
- The analytics layer currently treats only `wasCompleted == true` focus records as countable productivity data, which keeps abandoned sessions out of dashboard totals.
- App-layer code that touches the domain `Category` type must qualify it as `FocusSessionCore.Category` to avoid collisions with Objective-C runtime symbols imported through the macOS SDK.
- The `Current Session` screen now uses a dark split layout with a left-side focus clock stage and a right-side notes/history workspace, which is materially closer to the visual structure the user referenced.
- Session notes are now persisted into `FocusSessionRecord.notes`, and the right-side `Recent Sessions` panel hydrates from stored focus history on launch and after each finish/abandon action.
- A reusable light-surface theme now exists, with shared canvas, card, border, and text treatments that match the newer `Tasks` direction across the rest of the app.
- The sidebar itself is now part of the same light visual language instead of remaining a separate dark shell.
- The active focus notes workspace still intentionally keeps its dark starfield background because the user explicitly asked for that focused post-start mode earlier.
- The idle current-session stage now drops its outer boxed panel and sits directly on the canvas, which makes the setup page feel lighter and less framed-in.
- The clock no longer uses a center number readout; instead it uses a small hub and a hand-driven dial treatment with a soft platter behind the tick marks.
- The app window chrome now uses a transparent title-bar treatment so the top of the window no longer reads as a separate dark rectangle.

## Technical Decisions
| Decision | Rationale |
|----------|-----------|
| Inspect the installed bundle only for feature discovery, not code extraction | This keeps the effort focused on product understanding rather than copying internals. |
| Delay implementation until scope approval | The feature surface is large enough that we need an explicit MVP boundary. |
| Treat website/app blocking as first-version scope | User explicitly wants the local full experience, including system-level blocking. |
| Build the app natively for macOS with SwiftUI plus targeted AppKit integration | This is the best fit for a local-first Session-like product with deep system integration. |
| Structure the project as a full-product architecture with phased delivery | This balances fidelity to the original experience with practical execution. |
| Design the blocker as a hybrid stack instead of assuming unrestricted Network Extension access | Apple documents that Network Extension requires special entitlement approval, so we need a fallback architecture. |
| Keep the shared domain and session engine in a local Swift package from the start | This gives the app, helper, widgets, and future extensions one source of truth for core behavior. |
| Use unsigned local debug builds during scaffolding | This keeps early verification moving while bundle IDs, entitlements, and target wiring are still evolving. |
| Use a local Application Support-backed runtime snapshot store until App Group wiring is introduced | This preserves the shared-snapshot abstraction now without blocking the current vertical slice on entitlement plumbing. |
| Introduce the app shell as a lightweight navigation layer before building section-specific features | This gives the product a stable desktop information architecture so future slices land in their final home instead of temporary one-off windows. |
| Fully qualify app-layer references to `FocusSessionCore.Project` and `FocusSessionCore.Category` in persistence/view-model code | This avoids Swift name collisions with Objective-C SDK symbols while keeping the domain models unchanged. |
| Keep analytics aggregation in `FocusSessionCore` and let the app layer only join project metadata plus format display rows | This makes the stats logic testable once and reusable across the main app, widgets, and future menu-bar surfaces. |
| Shift from project-first organization to task-first organization for the main productivity flow | The user explicitly asked to remove projects and make tasks the launch point for focus sessions. |
| Treat the current-session screen as a two-pane workspace instead of a single centered card | This better matches the referenced Session-style layout and gives notes/history a first-class place in the main loop. |
| After focus starts, collapse the current-session experience to a notes workspace instead of keeping timer controls on screen | The user wants a calmer writing-first focus mode, so the running scene should leave only the note editor, history notes, and ambient visuals. |
| Introduce a shared `AppSurfaceTheme` for the shell and major product pages | This prevents each page from drifting into its own background and card treatment while preserving one intentional product-wide direction. |
| Keep the active focus workspace dark even after the light-surface unification pass | This preserves the explicitly requested starfield immersion during live focus sessions while aligning the rest of the app to the `Tasks` style. |
| Make the idle current-session stage transparent instead of boxing it inside another card | The user wants the clock page to feel open and visually continuous with the app background rather than nested inside a separate rectangle. |
| Replace the dial’s center text with a physical hub and hand composition | This makes the timer feel more like a manipulated object and removes the crowded center readout the user called out. |
| Configure the macOS window title bar through AppKit instead of relying only on default SwiftUI chrome | This gives us reliable transparent title-bar behavior and removes the dark strip at the top of the app window. |
| Ban readable white text across app pages and avoid system segmented controls on the light UI | The light-surface visual direction breaks immediately when selected system segments or accent buttons render white text, so the shared theme now enforces dark ink and the blocker composer uses a custom segmented control. |
| Replace system prompt and toggle label styling in guarded forms with explicit dark components | The Create sheet and Blocker composer still leaked low-contrast system placeholder and label colors, so they now use custom prompted fields and explicit dark text labels. |

## Issues Encountered
| Issue | Resolution |
|-------|------------|
| No existing app project in the workspace | Plan for greenfield scaffolding after design approval. |
| Workspace is not a git repository | Avoid git-dependent workflow steps for now. |
| Xcode emitted CoreSimulator version mismatch warnings on every `xcodebuild` invocation | Builds still succeed for the `platform=macOS` destination, so continue while treating it as a non-blocking machine warning. |
| `Category` became ambiguous once SwiftData-backed project/category persistence was introduced | Switched app-layer persistence mappings and repository/view-model signatures to explicit `FocusSessionCore` type references. |
| Targeted analytics app tests initially failed with a harness issue instead of the intended missing-production-code failure | Added `try` to in-memory container creation so the red phase isolates the missing analytics implementation cleanly. |
| The first notes-workspace pass still left `+5 / Pause / Finish / Abandon` controls visible after start | Added a red test for the running scene configuration, then removed runtime controls so the active focus view now matches the notes-only requirement. |
| Only the `Tasks` page had been visually updated to the newer light direction, leaving the rest of the app inconsistent | Added a shared theme layer and moved the shell plus major sections onto the same background and card system. |
| The idle clock page still felt boxed in and the dial center was visually heavy | Removed the stage fill, added a soft platter under the dial, and redesigned the center as a small hub with the hand emerging from it. |
| System segmented controls and accent buttons were reintroducing white text on light surfaces | Replaced the blocker composer pickers with a custom segmented control, moved accent-button text to a dark shared token, and added a source-level white-text audit. |
| The Create and Blocker forms still looked invisible in places because system placeholder and toggle label colors were outside the theme | Swapped those forms to `AppPromptedTextField` plus explicit `Toggle(isOn:) { Text(...) }` labels, and added an audit that blocks direct default `TextField("...")` / `Toggle("...")` usage there. |

## Resources
- `/Applications/Session.app/Contents`
- `/Applications/Session.app/Contents/Info.plist`
- `/Applications/Session.app/Contents/Resources/en.lproj/Localizable.strings`
- `/Applications/Session.app/Contents/Resources/Intents.intentdefinition`
- `/Users/xiakaiyang/Documents/New project/docs`
- `/Users/xiakaiyang/Documents/New project/docs/plans/2026-03-08-focussession-design.md`
- `/Users/xiakaiyang/Documents/New project/docs/plans/2026-03-08-focussession-implementation.md`
- `/Users/xiakaiyang/Documents/New project/project.yml`
- `/Users/xiakaiyang/Documents/New project/Packages/FocusSessionCore/Package.swift`
- `https://developer.apple.com/documentation/appintents/app-intents`
- `https://developer.apple.com/documentation/widgetkit/making-a-configurable-widget`
- `https://developer.apple.com/documentation/servicemanagement/smappservice/loginitem(identifier:)`
- `https://developer.apple.com/documentation/safariservices/safari-web-extensions`
- `https://developer.apple.com/documentation/safariservices`
- `https://developer.apple.com/documentation/appkit/nsworkspace/`
- `https://developer.apple.com/system-extensions/`
- `https://developer.apple.com/support/terms/apple-developer-program-license-agreement/`

## Visual/Browser Findings
- No browser inspection yet.
