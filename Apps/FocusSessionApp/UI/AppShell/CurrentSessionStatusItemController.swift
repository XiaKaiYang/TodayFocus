import AppKit
import Combine

@MainActor
final class CurrentSessionStatusItemController: NSObject {
    static let activeTaskTitleColor = NSColor(
        calibratedRed: 0.82,
        green: 0.67,
        blue: 0.21,
        alpha: 1
    )
    static let defaultTitleColor = NSColor.labelColor

    private let currentSessionViewModel: CurrentSessionViewModel
    private let statusItem: NSStatusItem
    private var cancellables = Set<AnyCancellable>()
    private var statusTicker: AnyCancellable?

    init(currentSessionViewModel: CurrentSessionViewModel) {
        self.currentSessionViewModel = currentSessionViewModel
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        configureStatusItem()
        observeSession()
        observeTicker()
        refresh()
    }

    static func attributedTitle(
        for title: String,
        highlightsActiveTask: Bool
    ) -> NSAttributedString {
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: highlightsActiveTask ? activeTaskTitleColor : defaultTitleColor,
            .font: NSFont.systemFont(ofSize: 13, weight: .semibold)
        ]
        return NSAttributedString(string: title, attributes: attributes)
    }

    private var highlightsActiveTask: Bool {
        switch currentSessionViewModel.sessionState.phase {
        case .focusing, .focusPaused, .breakRunning, .breakPaused:
            true
        case .idle, .reflecting, .completed, .abandoned:
            false
        }
    }

    private func configureStatusItem() {
        statusItem.isVisible = true
        statusItem.behavior = .removalAllowed
        statusItem.button?.image = nil
        statusItem.button?.appearsDisabled = false
    }

    private func observeSession() {
        currentSessionViewModel.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }
                DispatchQueue.main.async {
                    self.refresh()
                }
            }
            .store(in: &cancellables)
    }

    private func observeTicker() {
        statusTicker = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] currentDate in
                guard let self, self.highlightsActiveTask else {
                    return
                }
                self.currentSessionViewModel.handleTimelineTick(at: currentDate)
                self.refresh(at: currentDate)
            }
    }

    private func refresh(at currentDate: Date = Date()) {
        updateTitle(at: currentDate)
        rebuildMenu(at: currentDate)
    }

    private func updateTitle(at currentDate: Date) {
        let title = currentSessionViewModel.statusItemTitle(at: currentDate)
        statusItem.button?.title = title
        statusItem.button?.attributedTitle = Self.attributedTitle(
            for: title,
            highlightsActiveTask: highlightsActiveTask
        )
    }

    private func rebuildMenu(at currentDate: Date) {
        let menu = NSMenu()

        let titleItem = NSMenuItem(
            title: currentSessionViewModel.statusItemTitle(at: currentDate),
            action: nil,
            keyEquivalent: ""
        )
        titleItem.isEnabled = false
        titleItem.attributedTitle = Self.attributedTitle(
            for: currentSessionViewModel.statusItemTitle(at: currentDate),
            highlightsActiveTask: highlightsActiveTask
        )
        menu.addItem(titleItem)

        if currentSessionViewModel.phaseText != "Idle" {
            let detailItem = NSMenuItem(
                title: "\(currentSessionViewModel.phaseText) • \(currentSessionViewModel.remainingTimeText(at: currentDate))",
                action: nil,
                keyEquivalent: ""
            )
            detailItem.isEnabled = false
            menu.addItem(detailItem)
        }

        menu.addItem(.separator())

        if currentSessionViewModel.canPauseSession {
            menu.addItem(actionItem("Pause Session", action: #selector(pauseSession)))
        }

        if currentSessionViewModel.canResumeSession {
            menu.addItem(actionItem("Resume Session", action: #selector(resumeSession)))
        }

        if currentSessionViewModel.canFinishSession {
            menu.addItem(actionItem("Finish Session", action: #selector(finishSession)))
        }

        menu.addItem(actionItem("Open TodayFocus", action: #selector(openFocus)))
        statusItem.menu = menu
    }

    private func actionItem(_ title: String, action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        return item
    }

    @objc
    private func pauseSession() {
        currentSessionViewModel.pauseSession()
        refresh()
    }

    @objc
    private func resumeSession() {
        currentSessionViewModel.resumeSession()
        refresh()
    }

    @objc
    private func finishSession() {
        currentSessionViewModel.finishSession()
        refresh()
    }

    @objc
    private func openFocus() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.windows.first(where: \.canBecomeMain)?.makeKeyAndOrderFront(nil)
    }
}
