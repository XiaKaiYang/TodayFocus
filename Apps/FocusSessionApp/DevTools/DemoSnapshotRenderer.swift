import AppKit
import SwiftUI
import SwiftData
import FocusSessionCore

enum DemoSnapshotRendererError: Error {
    case unableToCreateBitmap
    case unableToEncodePNG
}

@MainActor
enum DemoSnapshotRenderer {
    static func renderBlocker(
        to url: URL,
        size: CGSize = CGSize(width: 1440, height: 960)
    ) throws {
        let rootView = AppShellView(
            configuration: AppLaunchConfiguration(
                environment: ["FOCUSSESSION_DEMO_MODE": "blocker"]
            )
        )
        .frame(width: size.width, height: size.height)

        try render(rootView, to: url, size: size)
    }

    static func renderTasks(
        to url: URL,
        size: CGSize = CGSize(width: 1440, height: 960)
    ) throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let repository = TasksRepository(modelContext: ModelContext(container))

        try repository.save(
            FocusTask(
                title: "Write MPC derivation notes",
                details: "整理终端约束和 QP 标准形式",
                estimatedMinutes: 45,
                createdAt: Date(timeIntervalSince1970: 1_000)
            )
        )
        try repository.save(
            FocusTask(
                title: "Review policy iteration",
                details: "把 value update 和 policy improvement 串起来",
                estimatedMinutes: 25,
                createdAt: Date(timeIntervalSince1970: 2_000)
            )
        )
        try repository.save(
            FocusTask(
                title: "Ship blocker polish",
                details: "补一轮规则文案和日志展示",
                estimatedMinutes: 20,
                isCompleted: true,
                createdAt: Date(timeIntervalSince1970: 500),
                completedAt: Date(timeIntervalSince1970: 3_000)
            )
        )

        let tasksViewModel = TasksViewModel(repository: repository)
        let rootView = AppShellView(
            configuration: AppLaunchConfiguration(
                environment: ["FOCUSSESSION_INITIAL_SECTION": "tasks"]
            ),
            currentSessionViewModel: CurrentSessionViewModel(snapshotStore: nil),
            tasksViewModel: tasksViewModel
        )
        .frame(width: size.width, height: size.height)

        try render(rootView, to: url, size: size)
    }

    static func renderCurrentSession(
        to url: URL,
        size: CGSize = CGSize(width: 1440, height: 900)
    ) throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let modelContext = ModelContext(container)
        let repository = FocusSessionRepository(modelContext: modelContext)
        let tasksRepository = TasksRepository(modelContext: modelContext)
        let referenceDate = Date()

        try repository.save(
            FocusSessionRecord(
                intention: "Review policy iteration",
                startedAt: referenceDate.addingTimeInterval(-3_600),
                endedAt: referenceDate.addingTimeInterval(-3_000),
                notes: "Link value update with policy improvement.",
                wasCompleted: true
            )
        )
        try repository.save(
            FocusSessionRecord(
                intention: "Write MPC notes",
                startedAt: referenceDate.addingTimeInterval(-1_800),
                endedAt: referenceDate.addingTimeInterval(-1_200),
                notes: "整理终端约束和标准 QP 形式。",
                wasCompleted: true
            )
        )
        let selectedTask = FocusTask(
            title: "Study control theory",
            details: "Clarify the state transition and keep the derivation tight.",
            estimatedMinutes: 45,
            createdAt: referenceDate.addingTimeInterval(-900)
        )
        try tasksRepository.save(selectedTask)

        let currentSessionViewModel = CurrentSessionViewModel(
            snapshotStore: nil,
            focusSessionRepository: repository,
            tasksRepository: tasksRepository
        )
        currentSessionViewModel.selectTask(selectedTask)
        currentSessionViewModel.durationMinutes = 45
        currentSessionViewModel.sessionNotes = """
        Clarify the state transition and keep the derivation tight.
        """
        currentSessionViewModel.startSession()

        let rootView = CurrentSessionView(viewModel: currentSessionViewModel)
        .frame(width: size.width, height: size.height)

        try render(rootView, to: url, size: size)
    }

    static func renderCurrentSessionSetup(
        to url: URL,
        size: CGSize = CGSize(width: 1440, height: 900)
    ) throws {
        let container = try FocusSessionModelContainer.makeInMemory()
        let modelContext = ModelContext(container)
        let tasksRepository = TasksRepository(modelContext: modelContext)
        let focusSessionRepository = FocusSessionRepository(modelContext: modelContext)

        let selectedTask = FocusTask(
            title: "English words",
            details: "Collect the next 20 words and test recall.",
            estimatedMinutes: 20,
            createdAt: Date(timeIntervalSince1970: 2_000)
        )
        try tasksRepository.save(selectedTask)
        try tasksRepository.save(
            FocusTask(
                title: "Practice listening",
                details: "Shadow one short paragraph twice.",
                estimatedMinutes: 30,
                createdAt: Date(timeIntervalSince1970: 1_000)
            )
        )

        let currentSessionViewModel = CurrentSessionViewModel(
            snapshotStore: nil,
            focusSessionRepository: focusSessionRepository,
            tasksRepository: tasksRepository
        )
        currentSessionViewModel.selectTask(selectedTask)
        currentSessionViewModel.durationMinutes = 20

        let rootView = CurrentSessionView(viewModel: currentSessionViewModel)
            .frame(width: size.width, height: size.height)

        try render(rootView, to: url, size: size)
    }

    static func renderCurrentSessionShellSetup(
        to url: URL,
        size: CGSize = CGSize(width: 1440, height: 900)
    ) throws {
        let currentSessionViewModel = try makeSeededCurrentSessionViewModel()

        let rootView = AppShellView(
            currentSessionViewModel: currentSessionViewModel
        )
        .frame(width: size.width, height: size.height)

        try render(rootView, to: url, size: size)
    }

    private static func makeSeededCurrentSessionViewModel() throws -> CurrentSessionViewModel {
        let container = try FocusSessionModelContainer.makeInMemory()
        let modelContext = ModelContext(container)
        let tasksRepository = TasksRepository(modelContext: modelContext)
        let focusSessionRepository = FocusSessionRepository(modelContext: modelContext)

        let selectedTask = FocusTask(
            title: "Practice listening",
            details: "Loop one short paragraph until it feels natural.",
            estimatedMinutes: 25,
            createdAt: Date(timeIntervalSince1970: 2_500)
        )
        try tasksRepository.save(selectedTask)

        let currentSessionViewModel = CurrentSessionViewModel(
            snapshotStore: nil,
            focusSessionRepository: focusSessionRepository,
            tasksRepository: tasksRepository
        )
        currentSessionViewModel.selectTask(selectedTask)
        currentSessionViewModel.durationMinutes = 25
        return currentSessionViewModel
    }

    private static func render<RootView: View>(
        _ rootView: RootView,
        to url: URL,
        size: CGSize
    ) throws {
        let hostingView = NSHostingView(rootView: rootView)
        hostingView.frame = CGRect(origin: .zero, size: size)

        let window = NSWindow(
            contentRect: CGRect(origin: .zero, size: size),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.contentView = hostingView
        window.layoutIfNeeded()
        window.displayIfNeeded()

        guard let bitmap = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds) else {
            throw DemoSnapshotRendererError.unableToCreateBitmap
        }

        hostingView.cacheDisplay(in: hostingView.bounds, to: bitmap)

        guard let data = bitmap.representation(using: .png, properties: [:]) else {
            throw DemoSnapshotRendererError.unableToEncodePNG
        }

        try data.write(to: url, options: .atomic)
    }
}
