import AppKit
import Foundation
import SwiftData
import FocusSessionCore

enum BlockerTargetKind: String, CaseIterable, Identifiable, Hashable {
    case app
    case domain

    var id: String { rawValue }

    var title: String {
        switch self {
        case .app:
            "App"
        case .domain:
            "Website"
        }
    }
}

private struct NoopForegroundAppWatcher: ForegroundAppWatching {
    func start(onChange: @escaping @Sendable (NSRunningApplication?) -> Void) {}
}

private struct BlockerDemoContent {
    let rules: [BlockingRule]
    let events: [DistractionEvent]
    let isBlockingEnabled: Bool

    static let blocker = BlockerDemoContent(
        rules: [
            BlockingRule(
                mode: .deny,
                target: .app(name: "Discord"),
                activeDuringFocus: true,
                activeDuringBreak: false
            ),
            BlockingRule(
                mode: .allow,
                target: .app(name: "Xcode"),
                activeDuringFocus: true,
                activeDuringBreak: false
            ),
            BlockingRule(
                mode: .deny,
                target: .domain(host: "youtube.com"),
                activeDuringFocus: true,
                activeDuringBreak: false
            ),
            BlockingRule(
                mode: .deny,
                target: .domain(host: "news.ycombinator.com"),
                activeDuringFocus: true,
                activeDuringBreak: true
            )
        ],
        events: [
            DistractionEvent(
                kind: .blockedApp(name: "Discord"),
                occurredAt: Date(timeIntervalSince1970: 1_741_451_200)
            ),
            DistractionEvent(
                kind: .blockedWebsite(host: "youtube.com"),
                occurredAt: Date(timeIntervalSince1970: 1_741_450_900)
            )
        ],
        isBlockingEnabled: true
    )
}

@MainActor
final class BlockerViewModel: ObservableObject {
    @Published private(set) var rules: [BlockingRule] = []
    @Published private(set) var recentEvents: [DistractionEvent] = []
    @Published private(set) var lastBlockedAppName: String?
    @Published private(set) var errorMessage: String?
    @Published var newRuleValue = ""
    @Published var newRuleMode: BlockingRuleMode = .deny
    @Published var newTargetKind: BlockerTargetKind = .app
    @Published var activeDuringFocus = true
    @Published var activeDuringBreak = false
    @Published var isBlockingEnabled = false {
        didSet {
            coordinator.isBlockingEnabled = isBlockingEnabled
        }
    }

    private let rulesRepository: BlockingRuleRepository
    private let eventRepository: DistractionEventRepository
    private let coordinator: BlockerCoordinator
    private var isSessionManagingBlocking = false

    init(
        rulesRepository: BlockingRuleRepository? = nil,
        eventRepository: DistractionEventRepository? = nil,
        coordinator: BlockerCoordinator? = nil
    ) {
        let modelContext = ModelContext(FocusSessionModelContainer.shared)
        self.rulesRepository = rulesRepository ?? BlockingRuleRepository(modelContext: modelContext)
        self.eventRepository = eventRepository ?? DistractionEventRepository(modelContext: modelContext)
        self.coordinator = coordinator ?? BlockerCoordinator(
            rulesRepository: self.rulesRepository,
            distractionEventRepository: self.eventRepository
        )

        self.coordinator.onEventLogged = { [weak self] in
            Task { @MainActor [weak self] in
                self?.lastBlockedAppName = self?.coordinator.lastBlockedAppName
                self?.loadEvents()
            }
        }
        self.coordinator.startWatching()
        load()
    }

    var appRules: [BlockingRule] {
        rules.filter {
            if case .app = $0.target { return true }
            return false
        }
    }

    var domainRules: [BlockingRule] {
        rules.filter {
            if case .domain = $0.target { return true }
            return false
        }
    }

    func load() {
        do {
            rules = try rulesRepository.fetchAll()
            recentEvents = try eventRepository.fetchAll()
            coordinator.reloadRules()
            lastBlockedAppName = coordinator.lastBlockedAppName ?? mostRecentBlockedAppName(in: recentEvents)
            errorMessage = nil
        } catch {
            errorMessage = "Unable to load blocker rules."
        }
    }

    static func demo() -> BlockerViewModel {
        let container: ModelContainer
        do {
            container = try FocusSessionModelContainer.makeInMemory()
        } catch {
            fatalError("Unable to create blocker demo container: \(error)")
        }

        let modelContext = ModelContext(container)
        let rulesRepository = BlockingRuleRepository(modelContext: modelContext)
        let eventRepository = DistractionEventRepository(modelContext: modelContext)
        let demoContent = BlockerDemoContent.blocker

        for rule in demoContent.rules {
            try? rulesRepository.save(rule)
        }

        for event in demoContent.events {
            try? eventRepository.save(event)
        }

        let coordinator = BlockerCoordinator(
            rulesRepository: rulesRepository,
            distractionEventRepository: eventRepository,
            watcher: NoopForegroundAppWatcher()
        )
        let viewModel = BlockerViewModel(
            rulesRepository: rulesRepository,
            eventRepository: eventRepository,
            coordinator: coordinator
        )
        viewModel.isBlockingEnabled = demoContent.isBlockingEnabled
        viewModel.load()
        return viewModel
    }

    func createRule() {
        let trimmedValue = newRuleValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedValue.isEmpty else {
            errorMessage = "Rule value is required."
            return
        }

        let target: BlockingRuleTarget
        switch newTargetKind {
        case .app:
            target = .app(name: trimmedValue)
        case .domain:
            target = .domain(host: trimmedValue)
        }

        do {
            try rulesRepository.save(
                BlockingRule(
                    mode: newRuleMode,
                    target: target,
                    activeDuringFocus: activeDuringFocus,
                    activeDuringBreak: activeDuringBreak
                )
            )
            newRuleValue = ""
            activeDuringFocus = true
            activeDuringBreak = false
            load()
        } catch {
            errorMessage = "Unable to save blocker rule."
        }
    }

    func deleteRule(_ rule: BlockingRule) {
        do {
            try rulesRepository.delete(id: rule.id)
            load()
        } catch {
            errorMessage = "Unable to delete blocker rule."
        }
    }

    func clearActivity() {
        do {
            try eventRepository.deleteAll()
            load()
        } catch {
            errorMessage = "Unable to clear blocker activity."
        }
    }

    func syncSessionPhase(
        _ phase: SessionPhase,
        autoEnableDuringFocus: Bool
    ) {
        let isFocusActive: Bool
        switch phase {
        case .focusing, .focusPaused:
            isFocusActive = true
        case .idle, .breakRunning, .breakPaused, .reflecting, .completed, .abandoned:
            isFocusActive = false
        }

        if isFocusActive {
            guard autoEnableDuringFocus else {
                return
            }
            if !isBlockingEnabled {
                isSessionManagingBlocking = true
                isBlockingEnabled = true
            }
            return
        }

        guard isSessionManagingBlocking else {
            return
        }
        isSessionManagingBlocking = false
        isBlockingEnabled = false
    }

    private func loadEvents() {
        recentEvents = (try? eventRepository.fetchAll()) ?? []
        lastBlockedAppName = coordinator.lastBlockedAppName ?? mostRecentBlockedAppName(in: recentEvents)
    }

    private func mostRecentBlockedAppName(in events: [DistractionEvent]) -> String? {
        for event in events {
            if case let .blockedApp(name) = event.kind {
                return name
            }
        }
        return nil
    }
}
