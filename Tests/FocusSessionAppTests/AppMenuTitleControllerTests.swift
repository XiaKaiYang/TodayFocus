import AppKit
import XCTest
@testable import FocusSession

@MainActor
final class AppMenuTitleControllerTests: XCTestCase {
    func testSynchronizeWritesVisibleAppMenuTitleIntoFirstMenuItem() {
        let menu = NSMenu(title: "Main")
        menu.addItem(withTitle: "TodayFocus", action: nil, keyEquivalent: "")
        menu.addItem(withTitle: "File", action: nil, keyEquivalent: "")

        AppMenuTitleController.synchronize(
            title: "Practice listening",
            highlightsActiveTask: false,
            in: menu
        )

        XCTAssertEqual(menu.items.first?.title, "Practice listening")
        XCTAssertEqual(menu.items.dropFirst().first?.title, "File")
    }

    func testSynchronizeHighlightsActiveTaskTitleInGold() {
        let menu = NSMenu(title: "Main")
        menu.addItem(withTitle: "TodayFocus", action: nil, keyEquivalent: "")

        AppMenuTitleController.synchronize(
            title: "Practice listening",
            highlightsActiveTask: true,
            in: menu
        )

        let attributes = menu.items.first?.attributedTitle?.attributes(
            at: 0,
            effectiveRange: nil as NSRangePointer?
        )

        XCTAssertEqual(menu.items.first?.title, "Practice listening")
        XCTAssertEqual(menu.items.first?.attributedTitle?.string, "Practice listening")
        XCTAssertEqual(
            attributes?[.foregroundColor] as? NSColor,
            AppMenuTitleController.activeTaskTitleColor
        )
    }

    func testSynchronizeClearsGoldHighlightWhenSessionEnds() {
        let menu = NSMenu(title: "Main")
        menu.addItem(withTitle: "TodayFocus", action: nil, keyEquivalent: "")

        AppMenuTitleController.synchronize(
            title: "Practice listening",
            highlightsActiveTask: true,
            in: menu
        )
        AppMenuTitleController.synchronize(
            title: "TodayFocus",
            highlightsActiveTask: false,
            in: menu
        )

        XCTAssertEqual(menu.items.first?.title, "TodayFocus")
        XCTAssertNil(menu.items.first?.attributedTitle)
    }

    func testAppShellInstallsMainMenuTitleSynchronizer() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let fileURL = root.appendingPathComponent("Apps/FocusSessionApp/UI/AppShell/AppShellView.swift")
        let contents = try String(contentsOf: fileURL, encoding: .utf8)

        XCTAssertTrue(
            contents.contains("AppMenuTitleSynchronizer"),
            "The observed shell should install a main-menu title synchronizer so the visible macOS app menu title can switch from TodayFocus to the active task."
        )
        XCTAssertTrue(
            contents.contains("currentSessionViewModel.menuBarTitle"),
            "The synchronizer should be driven by the same observed CurrentSessionViewModel that powers the Session screen."
        )
        XCTAssertTrue(
            contents.contains("currentSessionViewModel.sessionState.phase"),
            "The shell should tell the title synchronizer when an active task is running so the macOS menu title can switch to its highlighted color."
        )
    }

    func testAppUsesCustomStatusItemControllerForRightMenuBarTitle() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let fileURL = root.appendingPathComponent("Apps/FocusSessionApp/FocusSessionApp.swift")
        let contents = try String(contentsOf: fileURL, encoding: .utf8)

        XCTAssertTrue(
            contents.contains("CurrentSessionStatusItemController"),
            "The app should own a custom status-item controller so the right-side macOS menu bar task title can use the requested gold highlight."
        )
        XCTAssertFalse(
            contents.contains("MenuBarExtra"),
            "MenuBarExtra keeps the menu bar title under system styling, so it should be replaced when the task title needs a custom gold color."
        )
    }

    func testStatusItemAttributedTitleHighlightsActiveTaskInGold() {
        let attributedTitle = CurrentSessionStatusItemController.attributedTitle(
            for: "Review English",
            highlightsActiveTask: true
        )

        let attributes = attributedTitle.attributes(
            at: 0,
            effectiveRange: nil as NSRangePointer?
        )

        XCTAssertEqual(attributedTitle.string, "Review English")
        XCTAssertEqual(
            attributes[.foregroundColor] as? NSColor,
            CurrentSessionStatusItemController.activeTaskTitleColor
        )
    }

    func testStatusItemAttributedTitleUsesDefaultLabelColorWhenIdle() {
        let attributedTitle = CurrentSessionStatusItemController.attributedTitle(
            for: "TodayFocus",
            highlightsActiveTask: false
        )

        let attributes = attributedTitle.attributes(
            at: 0,
            effectiveRange: nil as NSRangePointer?
        )

        XCTAssertEqual(
            attributes[.foregroundColor] as? NSColor,
            CurrentSessionStatusItemController.defaultTitleColor
        )
    }

    func testStatusItemControllerUsesLiveCountdownTitleAndSecondTicker() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let fileURL = root.appendingPathComponent("Apps/FocusSessionApp/UI/AppShell/CurrentSessionStatusItemController.swift")
        let contents = try String(contentsOf: fileURL, encoding: .utf8)

        XCTAssertTrue(
            contents.contains("statusItemTitle(at:"),
            "The status item controller should use the session-specific countdown title instead of the static app-menu title."
        )
        XCTAssertTrue(
            contents.contains("Timer.publish(every: 1"),
            "The status item controller should refresh once per second so the remaining time actually moves in the macOS menu bar."
        )
    }

    func testStatusItemTickerAlsoDrivesCountdownCompletion() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let fileURL = root.appendingPathComponent("Apps/FocusSessionApp/UI/AppShell/CurrentSessionStatusItemController.swift")
        let contents = try String(contentsOf: fileURL, encoding: .utf8)

        XCTAssertTrue(
            contents.contains("handleTimelineTick(at: currentDate)"),
            "The always-on status-item ticker should also drive countdown completion so a session still auto-finishes when the Session screen is not the active page."
        )
    }
}
