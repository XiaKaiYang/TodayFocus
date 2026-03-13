# FocusSession macOS Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a local-first macOS focus app that closely matches Session’s desktop experience, including focus/break workflows, projects/categories, menu bar controls, analytics, calendar integration, local automation, and app/website blocking.

**Architecture:** Use a native multi-target macOS app built with SwiftUI and AppKit, with shared business logic inside a local Swift package. Persist primary user data locally, sync lightweight runtime snapshots through an App Group, and implement blocking through provider-based app and browser integrations so the product remains usable even without Network Extension entitlement approval.

**Tech Stack:** Swift 6.2, SwiftUI, AppKit, SwiftData, App Intents, WidgetKit, EventKit, UserNotifications, ServiceManagement (`SMAppService`), Safari Web Extension, XcodeGen, XCTest, XCUITest

---

### Task 1: Bootstrap the reproducible project scaffold

**Files:**
- Create: `project.yml`
- Create: `FocusSession.xcodeproj` (generated)
- Create: `Config/Development.xcconfig`
- Create: `Config/Shared.xcconfig`
- Create: `Config/Entitlements/FocusSessionApp.entitlements`
- Create: `Config/Entitlements/FocusSessionHelper.entitlements`
- Create: `Config/Entitlements/FocusSessionWidget.entitlements`
- Create: `Config/Entitlements/FocusSessionIntents.entitlements`
- Create: `Config/Entitlements/FocusSessionSafari.entitlements`
- Create: `Apps/FocusSessionApp/FocusSessionApp.swift`
- Create: `Apps/FocusSessionHelper/FocusSessionHelperApp.swift`
- Create: `Extensions/FocusSessionWidget/FocusSessionWidgetBundle.swift`
- Create: `Extensions/FocusSessionIntents/FocusSessionIntents.swift`
- Create: `Extensions/FocusSessionSafari/SafariWebExtensionHandler.swift`

**Step 1: Install `xcodegen` if it is missing**

Run:

```bash
brew list xcodegen >/dev/null 2>&1 || brew install xcodegen
```

Expected: `xcodegen` is available in `PATH`.

**Step 2: Write the project generator config**

Add the targets, build settings, bundle identifiers, App Group, and entitlements to `project.yml`.

```yaml
name: FocusSession
options:
  minimumXcodeGenVersion: 2.40.0
configs:
  Debug: debug
  Release: release
targets:
  FocusSessionApp:
    type: application
    platform: macOS
    deploymentTarget: "15.0"
    sources:
      - Apps/FocusSessionApp
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.example.FocusSession
```

**Step 3: Generate the Xcode project**

Run:

```bash
xcodegen generate
```

Expected: `FocusSession.xcodeproj` is created and includes all targets.

**Step 4: Verify the empty shell builds**

Run:

```bash
xcodebuild -project FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' build
```

Expected: BUILD SUCCEEDED.

**Step 5: Commit**

```bash
git add project.yml Config Apps Extensions FocusSession.xcodeproj
git commit -m "chore: scaffold FocusSession macOS targets"
```

### Task 2: Create the shared core package and domain models

**Files:**
- Create: `Packages/FocusSessionCore/Package.swift`
- Create: `Packages/FocusSessionCore/Sources/FocusSessionCore/Models/Project.swift`
- Create: `Packages/FocusSessionCore/Sources/FocusSessionCore/Models/Category.swift`
- Create: `Packages/FocusSessionCore/Sources/FocusSessionCore/Models/SessionProfile.swift`
- Create: `Packages/FocusSessionCore/Sources/FocusSessionCore/Models/BlockingRule.swift`
- Create: `Packages/FocusSessionCore/Sources/FocusSessionCore/Models/FocusSessionRecord.swift`
- Create: `Packages/FocusSessionCore/Sources/FocusSessionCore/Models/BreakRecord.swift`
- Create: `Packages/FocusSessionCore/Sources/FocusSessionCore/Models/ReflectionRecord.swift`
- Create: `Packages/FocusSessionCore/Sources/FocusSessionCore/Models/DistractionEvent.swift`
- Create: `Packages/FocusSessionCore/Tests/FocusSessionCoreTests/DomainModelTests.swift`

**Step 1: Write the failing test**

```swift
func testFocusSessionRecordDurationUsesEndMinusStart() throws {
    let start = Date(timeIntervalSince1970: 0)
    let end = Date(timeIntervalSince1970: 1500)
    let record = FocusSessionRecord(startedAt: start, endedAt: end)
    XCTAssertEqual(record.durationSeconds, 1500)
}
```

**Step 2: Run the test to confirm failure**

Run:

```bash
swift test --package-path Packages/FocusSessionCore
```

Expected: FAIL because the package and model types do not exist yet.

**Step 3: Add the package and model types**

Define plain, testable models and enums first; keep persistence annotations out of the initial model layer.

```swift
public struct FocusSessionRecord: Codable, Equatable, Sendable {
    public var startedAt: Date
    public var endedAt: Date

    public var durationSeconds: Int {
        Int(endedAt.timeIntervalSince(startedAt))
    }
}
```

**Step 4: Run the package tests again**

Run:

```bash
swift test --package-path Packages/FocusSessionCore
```

Expected: PASS for the first model tests.

**Step 5: Commit**

```bash
git add Packages/FocusSessionCore
git commit -m "feat: add shared focus session domain models"
```

### Task 3: Implement the focus/break state machine

**Files:**
- Create: `Packages/FocusSessionCore/Sources/FocusSessionCore/SessionEngine/SessionState.swift`
- Create: `Packages/FocusSessionCore/Sources/FocusSessionCore/SessionEngine/SessionEvent.swift`
- Create: `Packages/FocusSessionCore/Sources/FocusSessionCore/SessionEngine/SessionReducer.swift`
- Create: `Packages/FocusSessionCore/Sources/FocusSessionCore/SessionEngine/ActiveSessionSnapshot.swift`
- Create: `Packages/FocusSessionCore/Tests/FocusSessionCoreTests/SessionReducerTests.swift`

**Step 1: Write the failing reducer tests**

```swift
func testStartSessionMovesIdleToFocusing() throws {
    var state = SessionState.idle
    let next = try SessionReducer.reduce(state: &state, event: .startSession(durationSeconds: 1500))
    XCTAssertEqual(state.phase, .focusing)
    XCTAssertTrue(next.effects.contains(.activateBlocker))
}
```

**Step 2: Run the tests**

Run:

```bash
swift test --package-path Packages/FocusSessionCore --filter SessionReducerTests
```

Expected: FAIL because the reducer does not exist.

**Step 3: Implement a pure reducer with explicit side effects**

```swift
public enum SessionSideEffect: Equatable {
    case activateBlocker
    case deactivateBlocker
    case refreshMenubar
    case scheduleNotification(NotificationKind)
    case persistSnapshot
}
```

**Step 4: Run the tests again**

Run:

```bash
swift test --package-path Packages/FocusSessionCore --filter SessionReducerTests
```

Expected: PASS for start, pause, resume, finish, and abandon transitions.

**Step 5: Commit**

```bash
git add Packages/FocusSessionCore
git commit -m "feat: add focus session state machine"
```

### Task 4: Add persistence and shared runtime snapshots

**Files:**
- Create: `Apps/FocusSessionApp/Data/FocusSessionModelContainer.swift`
- Create: `Apps/FocusSessionApp/Data/SwiftDataProject.swift`
- Create: `Apps/FocusSessionApp/Data/SwiftDataCategory.swift`
- Create: `Apps/FocusSessionApp/Data/SwiftDataSessionProfile.swift`
- Create: `Apps/FocusSessionApp/Data/SwiftDataSessionRecord.swift`
- Create: `Apps/FocusSessionApp/Data/Repositories/ProjectRepository.swift`
- Create: `Apps/FocusSessionApp/Data/Repositories/SessionRepository.swift`
- Create: `Apps/FocusSessionApp/SharedSnapshot/RuntimeSnapshotStore.swift`
- Create: `Apps/FocusSessionApp/SharedSnapshot/RuntimeSnapshotWriter.swift`
- Create: `Tests/FocusSessionAppTests/RuntimeSnapshotStoreTests.swift`

**Step 1: Write the failing snapshot round-trip test**

```swift
func testRuntimeSnapshotRoundTripsThroughAppGroupJSON() throws {
    let store = RuntimeSnapshotStore(containerURL: temporaryDirectoryURL)
    let snapshot = ActiveSessionSnapshot.preview
    try store.write(snapshot)
    XCTAssertEqual(try store.read(), snapshot)
}
```

**Step 2: Run the app tests**

Run:

```bash
xcodebuild test -project FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/RuntimeSnapshotStoreTests
```

Expected: FAIL because the store does not exist.

**Step 3: Implement the SwiftData container and JSON snapshot store**

```swift
struct RuntimeSnapshotStore {
    let containerURL: URL

    func write(_ snapshot: ActiveSessionSnapshot) throws {
        let data = try JSONEncoder().encode(snapshot)
        try data.write(to: containerURL.appendingPathComponent("active-session.json"), options: .atomic)
    }
}
```

**Step 4: Re-run the targeted tests**

Run:

```bash
xcodebuild test -project FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/RuntimeSnapshotStoreTests
```

Expected: PASS.

**Step 5: Commit**

```bash
git add Apps/FocusSessionApp Tests/FocusSessionAppTests
git commit -m "feat: add local persistence and runtime snapshots"
```

### Task 5: Build the main app shell and current session screen

**Files:**
- Create: `Apps/FocusSessionApp/UI/Shell/RootSplitView.swift`
- Create: `Apps/FocusSessionApp/UI/Shell/AppNavigation.swift`
- Create: `Apps/FocusSessionApp/UI/CurrentSession/CurrentSessionView.swift`
- Create: `Apps/FocusSessionApp/UI/CurrentSession/StartSessionForm.swift`
- Create: `Apps/FocusSessionApp/UI/CurrentSession/SessionTimerRing.swift`
- Create: `Apps/FocusSessionApp/UI/CurrentSession/SessionControlsView.swift`
- Create: `Apps/FocusSessionApp/ViewModels/CurrentSessionViewModel.swift`
- Create: `Tests/FocusSessionAppUITests/CurrentSessionFlowUITests.swift`

**Step 1: Write the failing UI smoke test**

```swift
func testStartSessionFlowShowsPauseButton() {
    let app = XCUIApplication()
    app.launch()
    app.textFields["Intention"].click()
    app.typeText("Write design doc")
    app.buttons["Start Session"].click()
    XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout: 2))
}
```

**Step 2: Run the UI test**

Run:

```bash
xcodebuild test -project FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppUITests/CurrentSessionFlowUITests
```

Expected: FAIL because the screen and accessibility identifiers do not exist.

**Step 3: Implement the root shell and current session view**

```swift
NavigationSplitView {
    SidebarView(selection: $navigation)
} content: {
    CurrentSessionView(viewModel: currentSessionViewModel)
} detail: {
    SessionContextPanel(viewModel: currentSessionViewModel)
}
```

**Step 4: Re-run the UI test**

Run:

```bash
xcodebuild test -project FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppUITests/CurrentSessionFlowUITests
```

Expected: PASS for launch, start, and pause visibility.

**Step 5: Commit**

```bash
git add Apps/FocusSessionApp Tests/FocusSessionAppUITests
git commit -m "feat: add FocusSession app shell and timer screen"
```

### Task 6: Add menu bar, notifications, and sound orchestration

**Files:**
- Create: `Apps/FocusSessionApp/Menubar/MenubarController.swift`
- Create: `Apps/FocusSessionApp/Menubar/MenubarMenuView.swift`
- Create: `Apps/FocusSessionApp/Notifications/NotificationScheduler.swift`
- Create: `Apps/FocusSessionApp/Audio/SoundLibrary.swift`
- Create: `Apps/FocusSessionApp/Audio/BackgroundNoisePlayer.swift`
- Create: `Apps/FocusSessionApp/Orchestration/SessionEffectRunner.swift`
- Create: `Tests/FocusSessionAppTests/SessionEffectRunnerTests.swift`

**Step 1: Write the failing side-effect runner test**

```swift
func testActivateBlockerAndRefreshMenubarEffectsAreForwarded() async throws {
    let runner = SessionEffectRunner(blocker: blockerSpy, menubar: menubarSpy, notifications: notificationSpy)
    try await runner.run([.activateBlocker, .refreshMenubar])
    XCTAssertEqual(blockerSpy.activateCalls, 1)
    XCTAssertEqual(menubarSpy.refreshCalls, 1)
}
```

**Step 2: Run the tests**

Run:

```bash
xcodebuild test -project FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/SessionEffectRunnerTests
```

Expected: FAIL because the runner does not exist.

**Step 3: Implement the orchestrator and wire a menu bar extra**

```swift
final class SessionEffectRunner {
    func run(_ effects: [SessionSideEffect]) async throws {
        for effect in effects {
            switch effect {
            case .activateBlocker: try await blocker.activateCurrentProfile()
            case .refreshMenubar: await menubar.refresh()
            default: break
            }
        }
    }
}
```

**Step 4: Verify tests and build**

Run:

```bash
xcodebuild test -project FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/SessionEffectRunnerTests
xcodebuild -project FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' build
```

Expected: PASS and BUILD SUCCEEDED.

**Step 5: Commit**

```bash
git add Apps/FocusSessionApp Tests/FocusSessionAppTests
git commit -m "feat: add menubar and session side-effect orchestration"
```

### Task 7: Implement local app blocking and the helper process

**Files:**
- Create: `Packages/FocusSessionCore/Sources/FocusSessionCore/Blocking/BlockDecision.swift`
- Create: `Packages/FocusSessionCore/Sources/FocusSessionCore/Blocking/BlockerProfileSnapshot.swift`
- Create: `Apps/FocusSessionApp/Blocking/AppBlockProvider.swift`
- Create: `Apps/FocusSessionApp/Blocking/BlockerCoordinator.swift`
- Create: `Apps/FocusSessionHelper/HelperEntry.swift`
- Create: `Apps/FocusSessionHelper/ForegroundAppWatcher.swift`
- Create: `Apps/FocusSessionHelper/BlockedAppResponder.swift`
- Create: `Tests/FocusSessionAppTests/AppBlockProviderTests.swift`

**Step 1: Write the failing rule-match test**

```swift
func testBlockedApplicationNameReturnsBlockDecision() throws {
    let provider = AppBlockProvider(rules: [.app(name: "Safari")])
    let decision = provider.decision(forFrontmostAppName: "Safari")
    XCTAssertEqual(decision, .block(reason: .denyList))
}
```

**Step 2: Run the focused test**

Run:

```bash
xcodebuild test -project FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/AppBlockProviderTests
```

Expected: FAIL because the provider does not exist.

**Step 3: Implement the provider, helper watcher, and coordinator**

```swift
final class ForegroundAppWatcher {
    func start(onChange: @escaping (NSRunningApplication?) -> Void) {
        NotificationCenter.default.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { note in
            onChange(note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication)
        }
    }
}
```

**Step 4: Run tests and a build for both app and helper**

Run:

```bash
xcodebuild test -project FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/AppBlockProviderTests
xcodebuild -project FocusSession.xcodeproj -scheme FocusSessionHelper -destination 'platform=macOS' build
```

Expected: PASS and BUILD SUCCEEDED.

**Step 5: Commit**

```bash
git add Packages/FocusSessionCore Apps/FocusSessionApp Apps/FocusSessionHelper Tests/FocusSessionAppTests
git commit -m "feat: add local app blocking helper"
```

### Task 8: Add Safari website blocking and shared rule syncing

**Files:**
- Create: `Extensions/FocusSessionSafari/Resources/blocked.html`
- Create: `Extensions/FocusSessionSafari/Resources/blocked.css`
- Create: `Extensions/FocusSessionSafari/Resources/blocked.js`
- Create: `Extensions/FocusSessionSafari/Resources/manifest.json`
- Create: `Extensions/FocusSessionSafari/Resources/background.js`
- Create: `Extensions/FocusSessionSafari/Resources/content.js`
- Create: `Apps/FocusSessionApp/Blocking/WebsiteRuleExporter.swift`
- Create: `Apps/FocusSessionApp/UI/Blocker/BlockerSettingsView.swift`
- Create: `Tests/FocusSessionAppTests/WebsiteRuleExporterTests.swift`

**Step 1: Write the failing exporter test**

```swift
func testWebsiteRuleExporterWritesDenyListDomains() throws {
    let exporter = WebsiteRuleExporter(containerURL: temporaryDirectoryURL)
    try exporter.export(domains: ["youtube.com", "reddit.com"])
    let data = try Data(contentsOf: temporaryDirectoryURL.appendingPathComponent("blocked-domains.json"))
    XCTAssertTrue(String(decoding: data, as: UTF8.self).contains("youtube.com"))
}
```

**Step 2: Run the targeted test**

Run:

```bash
xcodebuild test -project FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/WebsiteRuleExporterTests
```

Expected: FAIL because the exporter does not exist.

**Step 3: Implement the exporter and Safari extension resource contract**

```swift
struct WebsiteRuleExporter {
    let containerURL: URL

    func export(domains: [String]) throws {
        let payload = ["domains": domains]
        let data = try JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted])
        try data.write(to: containerURL.appendingPathComponent("blocked-domains.json"), options: .atomic)
    }
}
```

**Step 4: Run the exporter test and build the extension target**

Run:

```bash
xcodebuild test -project FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/WebsiteRuleExporterTests
xcodebuild -project FocusSession.xcodeproj -scheme FocusSessionSafari -destination 'platform=macOS' build
```

Expected: PASS and BUILD SUCCEEDED.

**Step 5: Commit**

```bash
git add Apps/FocusSessionApp Extensions/FocusSessionSafari Tests/FocusSessionAppTests
git commit -m "feat: add Safari website blocking integration"
```

### Task 9: Build projects, categories, analytics, and export

**Files:**
- Create: `Apps/FocusSessionApp/UI/Projects/ProjectsView.swift`
- Create: `Apps/FocusSessionApp/UI/Projects/EditProjectSheet.swift`
- Create: `Apps/FocusSessionApp/UI/Analytics/AnalyticsOverviewView.swift`
- Create: `Apps/FocusSessionApp/UI/Analytics/AnalyticsCharts.swift`
- Create: `Packages/FocusSessionCore/Sources/FocusSessionCore/Analytics/AnalyticsCalculator.swift`
- Create: `Apps/FocusSessionApp/Export/CSVExporter.swift`
- Create: `Apps/FocusSessionApp/Export/JSONExporter.swift`
- Create: `Tests/FocusSessionAppTests/AnalyticsCalculatorTests.swift`

**Step 1: Write the failing analytics aggregation test**

```swift
func testWeeklyFocusTotalAggregatesSessionRecords() throws {
    let total = AnalyticsCalculator.weeklyTotalSeconds(records: sampleRecords)
    XCTAssertEqual(total, 7200)
}
```

**Step 2: Run the targeted test**

Run:

```bash
xcodebuild test -project FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/AnalyticsCalculatorTests
```

Expected: FAIL because the calculator does not exist.

**Step 3: Implement analytics calculation and the first analytics screens**

```swift
enum AnalyticsCalculator {
    static func weeklyTotalSeconds(records: [FocusSessionRecord]) -> Int {
        records.reduce(0) { $0 + $1.durationSeconds }
    }
}
```

**Step 4: Run tests and verify the app builds**

Run:

```bash
xcodebuild test -project FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/AnalyticsCalculatorTests
xcodebuild -project FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' build
```

Expected: PASS and BUILD SUCCEEDED.

**Step 5: Commit**

```bash
git add Apps/FocusSessionApp Packages/FocusSessionCore Tests/FocusSessionAppTests
git commit -m "feat: add projects analytics and export views"
```

### Task 10: Add calendar integration, reflection, and automation settings

**Files:**
- Create: `Apps/FocusSessionApp/Calendar/CalendarPermissionController.swift`
- Create: `Apps/FocusSessionApp/Calendar/CalendarSyncService.swift`
- Create: `Apps/FocusSessionApp/UI/Calendar/CalendarView.swift`
- Create: `Apps/FocusSessionApp/UI/Reflection/ReflectionSheet.swift`
- Create: `Apps/FocusSessionApp/UI/Automation/AutomationSettingsView.swift`
- Create: `Apps/FocusSessionApp/Automation/AutomationRuleRunner.swift`
- Create: `Tests/FocusSessionAppTests/AutomationRuleRunnerTests.swift`

**Step 1: Write the failing automation action test**

```swift
func testOnSessionStartRuleProducesExpectedActions() throws {
    let runner = AutomationRuleRunner(rules: [.playSound("light"), .enableDoNotDisturb])
    XCTAssertEqual(runner.actions(for: .sessionStarted).count, 2)
}
```

**Step 2: Run the targeted test**

Run:

```bash
xcodebuild test -project FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/AutomationRuleRunnerTests
```

Expected: FAIL because the runner does not exist.

**Step 3: Implement calendar services, reflection capture, and automation rules**

```swift
struct AutomationRuleRunner {
    let rules: [AutomationRule]

    func actions(for event: AutomationEvent) -> [AutomationAction] {
        rules.filter { $0.trigger == event }.map(\.action)
    }
}
```

**Step 4: Run tests and build**

Run:

```bash
xcodebuild test -project FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/AutomationRuleRunnerTests
xcodebuild -project FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' build
```

Expected: PASS and BUILD SUCCEEDED.

**Step 5: Commit**

```bash
git add Apps/FocusSessionApp Tests/FocusSessionAppTests
git commit -m "feat: add calendar reflection and automation settings"
```

### Task 11: Add App Intents, widgets, and companion snapshots

**Files:**
- Create: `Extensions/FocusSessionIntents/AppIntents/StartSessionIntent.swift`
- Create: `Extensions/FocusSessionIntents/AppIntents/TogglePauseIntent.swift`
- Create: `Extensions/FocusSessionIntents/AppIntents/TotalFocusTimeIntent.swift`
- Create: `Extensions/FocusSessionWidget/CurrentSessionWidget.swift`
- Create: `Extensions/FocusSessionWidget/QuickStartWidget.swift`
- Create: `Extensions/FocusSessionWidget/Providers/CurrentSessionTimelineProvider.swift`
- Create: `Tests/FocusSessionAppTests/AppIntentSnapshotTests.swift`

**Step 1: Write the failing snapshot consumption test**

```swift
func testCurrentSessionTimelineProviderReadsSharedSnapshot() throws {
    let provider = CurrentSessionTimelineProvider(snapshotStore: snapshotStore)
    let entry = try provider.snapshotEntry()
    XCTAssertEqual(entry.title, "Write design doc")
}
```

**Step 2: Run the targeted test**

Run:

```bash
xcodebuild test -project FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/AppIntentSnapshotTests
```

Expected: FAIL because the provider does not exist.

**Step 3: Implement App Intents and WidgetKit providers**

```swift
struct StartSessionIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Session"

    @Parameter(title: "Intention")
    var intention: String
}
```

**Step 4: Run tests and build app, intents, and widget targets**

Run:

```bash
xcodebuild test -project FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppTests/AppIntentSnapshotTests
xcodebuild -project FocusSession.xcodeproj -scheme FocusSessionIntents -destination 'platform=macOS' build
xcodebuild -project FocusSession.xcodeproj -scheme FocusSessionWidget -destination 'platform=macOS' build
```

Expected: PASS and all builds succeed.

**Step 5: Commit**

```bash
git add Extensions/FocusSessionIntents Extensions/FocusSessionWidget Tests/FocusSessionAppTests
git commit -m "feat: add app intents and widgets"
```

### Task 12: Finish settings polish, QA checklist, and release packaging

**Files:**
- Create: `Apps/FocusSessionApp/UI/Settings/SettingsRootView.swift`
- Create: `Apps/FocusSessionApp/UI/Settings/TimerSettingsView.swift`
- Create: `Apps/FocusSessionApp/UI/Settings/BlockingSettingsView.swift`
- Create: `Apps/FocusSessionApp/UI/Settings/SoundSettingsView.swift`
- Create: `Apps/FocusSessionApp/UI/Settings/CalendarSettingsView.swift`
- Create: `Apps/FocusSessionApp/UI/Settings/MenubarSettingsView.swift`
- Create: `docs/qa/focussession-manual-checklist.md`
- Create: `docs/release/focussession-local-release.md`

**Step 1: Write a failing UI smoke test for settings navigation**

```swift
func testSettingsShowsBlockingAndSoundSections() {
    let app = XCUIApplication()
    app.launchArguments.append("--open-settings")
    app.launch()
    XCTAssertTrue(app.staticTexts["Blocking"].waitForExistence(timeout: 2))
    XCTAssertTrue(app.staticTexts["Sound"].exists)
}
```

**Step 2: Run the UI smoke test**

Run:

```bash
xcodebuild test -project FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS' -only-testing:FocusSessionAppUITests/testSettingsShowsBlockingAndSoundSections
```

Expected: FAIL because the settings root does not exist.

**Step 3: Implement the grouped settings UI and write QA docs**

```swift
TabView {
    TimerSettingsView().tabItem { Text("Timer") }
    BlockingSettingsView().tabItem { Text("Blocking") }
    SoundSettingsView().tabItem { Text("Sound") }
}
```

**Step 4: Run full verification**

Run:

```bash
swift test --package-path Packages/FocusSessionCore
xcodebuild test -project FocusSession.xcodeproj -scheme FocusSessionApp -destination 'platform=macOS'
```

Expected: all unit tests and UI tests pass.

**Step 5: Commit**

```bash
git add Apps/FocusSessionApp docs/qa docs/release Tests/FocusSessionAppUITests
git commit -m "feat: add settings polish and release checklist"
```
