import AppKit
import Foundation
import FocusSessionCore

protocol ForegroundAppWatching {
    func start(onChange: @escaping @Sendable (NSRunningApplication?) -> Void)
}

protocol BlockedAppIntervening {
    func intervene(for appName: String, runningApplication: NSRunningApplication?)
}

struct DefaultBlockedAppIntervention: BlockedAppIntervening {
    func intervene(for appName: String, runningApplication: NSRunningApplication?) {
        _ = runningApplication?.hide()
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
}

final class WorkspaceForegroundAppWatcher: ForegroundAppWatching {
    private var observer: NSObjectProtocol?

    func start(onChange: @escaping @Sendable (NSRunningApplication?) -> Void) {
        guard observer == nil else {
            return
        }

        observer = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { notification in
            let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
            onChange(app)
        }
    }

    deinit {
        if let observer {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
    }
}

@MainActor
final class BlockerCoordinator: ObservableObject {
    @Published var isBlockingEnabled = false
    @Published private(set) var lastBlockedAppName: String?

    var onEventLogged: (() -> Void)?

    private let rulesRepository: BlockingRuleRepository
    private let distractionEventRepository: DistractionEventRepository
    private let watcher: ForegroundAppWatching
    private let intervention: BlockedAppIntervening
    private let now: () -> Date
    private var snapshot = BlockerProfileSnapshot(rules: [])
    private var hasStartedWatching = false

    init(
        rulesRepository: BlockingRuleRepository,
        distractionEventRepository: DistractionEventRepository,
        watcher: ForegroundAppWatching = WorkspaceForegroundAppWatcher(),
        intervention: BlockedAppIntervening = DefaultBlockedAppIntervention(),
        now: @escaping () -> Date = Date.init
    ) {
        self.rulesRepository = rulesRepository
        self.distractionEventRepository = distractionEventRepository
        self.watcher = watcher
        self.intervention = intervention
        self.now = now
        reloadRules()
    }

    func startWatching() {
        guard !hasStartedWatching else {
            return
        }
        hasStartedWatching = true

        watcher.start { [weak self] appName in
            Task { @MainActor [weak self] in
                try? self?.evaluateApp(
                    named: appName?.localizedName,
                    runningApplication: appName
                )
            }
        }
    }

    func reloadRules() {
        snapshot = BlockerProfileSnapshot(
            rules: (try? rulesRepository.fetchAll()) ?? []
        )
    }

    func evaluateApp(
        named appName: String?,
        runningApplication: NSRunningApplication? = nil
    ) throws {
        guard isBlockingEnabled else {
            return
        }
        guard let appName, !appName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        let provider = AppBlockProvider(rules: snapshot.rules)
        let decision = provider.decision(
            forFrontmostAppName: appName,
            isOnBreak: snapshot.isOnBreak
        )

        if case .block = decision {
            lastBlockedAppName = appName
            intervention.intervene(for: appName, runningApplication: runningApplication)
            try distractionEventRepository.save(
                DistractionEvent(
                    kind: .blockedApp(name: appName),
                    occurredAt: now()
                )
            )
            onEventLogged?()
        }
    }
}
