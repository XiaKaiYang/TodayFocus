import Foundation
import SwiftData

enum FocusSessionModelContainer {
    enum StoreConfigurationError: Error {
        case missingApplicationSupportDirectory
    }

    private static let sharedStoreName = "TodayFocus"

    @MainActor
    static let shared: ModelContainer = {
        do {
            return try makeShared()
        } catch {
            fatalError("Unable to create a persistent model container: \(error)")
        }
    }()

    @MainActor
    static func makeShared() throws -> ModelContainer {
        do {
            let sharedContainer = try makeSharedCloudBacked()
            try importLegacyStoreIfNeeded(into: sharedContainer)
            return sharedContainer
        } catch {
            let storeURL = try persistentStoreURL()
            return try makePersistent(at: storeURL)
        }
    }

    static func makeInMemory() throws -> ModelContainer {
        let configuration = ModelConfiguration(
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        return try makeContainer(configuration: configuration)
    }

    static func makePersistent(at storeURL: URL) throws -> ModelContainer {
        try ensureParentDirectoryExists(for: storeURL, fileManager: .default)
        let configuration = ModelConfiguration(
            url: storeURL,
            cloudKitDatabase: .none
        )
        return try makeContainer(configuration: configuration)
    }

    static func importLegacyContentIfNeeded(
        from legacyContainer: ModelContainer,
        to destinationContainer: ModelContainer
    ) throws -> Bool {
        let destinationContext = ModelContext(destinationContainer)
        guard try containsContent(in: destinationContext) == false else {
            return false
        }

        let legacyContext = ModelContext(legacyContainer)
        guard try containsContent(in: legacyContext) else {
            return false
        }

        try cloneFocusSessions(from: legacyContext, to: destinationContext)
        try cloneTasks(from: legacyContext, to: destinationContext)
        try clonePlanGoals(from: legacyContext, to: destinationContext)
        try cloneBlockingRules(from: legacyContext, to: destinationContext)
        try cloneDistractionEvents(from: legacyContext, to: destinationContext)
        try destinationContext.save()
        return true
    }

    static func persistentStoreURL(
        baseDirectory: URL? = nil,
        fileManager: FileManager = .default
    ) throws -> URL {
        let rootDirectory = try baseDirectory ?? applicationSupportDirectory(fileManager: fileManager)
        let storeDirectory = rootDirectory.appendingPathComponent("TodayFocus", isDirectory: true)
        try fileManager.createDirectory(at: storeDirectory, withIntermediateDirectories: true)

        let storeURL = storeDirectory.appendingPathComponent("TodayFocus.store", isDirectory: false)
        try migrateLegacyStoreIfNeeded(
            to: storeURL,
            baseDirectory: rootDirectory,
            fileManager: fileManager
        )
        return storeURL
    }

    static func prepareApplicationSupportDirectory(
        fileManager: FileManager = .default,
        directoryOverride: URL? = nil
    ) throws -> URL {
        let directory = try directoryOverride ?? applicationSupportDirectory(fileManager: fileManager)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private static func makeSharedCloudBacked() throws -> ModelContainer {
        _ = try prepareApplicationSupportDirectory()
        let configuration = ModelConfiguration(
            sharedStoreName,
            cloudKitDatabase: .automatic
        )
        return try makeContainer(configuration: configuration)
    }

    private static func makeContainer(configuration: ModelConfiguration) throws -> ModelContainer {
        try ModelContainer(
            for: StoredFocusSessionRecord.self,
            StoredTask.self,
            StoredPlanGoal.self,
            StoredBlockingRule.self,
            StoredDistractionEvent.self,
            configurations: configuration
        )
    }

    private static func applicationSupportDirectory(fileManager: FileManager) throws -> URL {
        guard let directory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw StoreConfigurationError.missingApplicationSupportDirectory
        }
        return directory
    }

    @MainActor
    private static func importLegacyStoreIfNeeded(into sharedContainer: ModelContainer) throws {
        let legacyStoreURL = try persistentStoreURL()
        guard FileManager.default.fileExists(atPath: legacyStoreURL.path) else {
            return
        }

        let legacyContainer = try makePersistent(at: legacyStoreURL)
        _ = try importLegacyContentIfNeeded(
            from: legacyContainer,
            to: sharedContainer
        )
    }

    private static func containsContent(in context: ModelContext) throws -> Bool {
        try containsItems(of: StoredFocusSessionRecord.self, in: context)
            || containsItems(of: StoredTask.self, in: context)
            || containsItems(of: StoredPlanGoal.self, in: context)
            || containsItems(of: StoredBlockingRule.self, in: context)
            || containsItems(of: StoredDistractionEvent.self, in: context)
    }

    private static func containsItems<Model: PersistentModel>(
        of type: Model.Type,
        in context: ModelContext
    ) throws -> Bool {
        var descriptor = FetchDescriptor<Model>()
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).isEmpty == false
    }

    private static func cloneFocusSessions(
        from sourceContext: ModelContext,
        to destinationContext: ModelContext
    ) throws {
        for record in try sourceContext.fetch(FetchDescriptor<StoredFocusSessionRecord>()) {
            destinationContext.insert(
                StoredFocusSessionRecord(record: record.domainModel)
            )
        }
    }

    private static func cloneTasks(
        from sourceContext: ModelContext,
        to destinationContext: ModelContext
    ) throws {
        for task in try sourceContext.fetch(FetchDescriptor<StoredTask>()) {
            destinationContext.insert(
                StoredTask(task: task.domainModel)
            )
        }
    }

    private static func clonePlanGoals(
        from sourceContext: ModelContext,
        to destinationContext: ModelContext
    ) throws {
        for goal in try sourceContext.fetch(FetchDescriptor<StoredPlanGoal>()) {
            destinationContext.insert(
                StoredPlanGoal(goal: goal.domainModel)
            )
        }
    }

    private static func cloneBlockingRules(
        from sourceContext: ModelContext,
        to destinationContext: ModelContext
    ) throws {
        for rule in try sourceContext.fetch(FetchDescriptor<StoredBlockingRule>()) {
            destinationContext.insert(
                StoredBlockingRule(rule: rule.domainModel)
            )
        }
    }

    private static func cloneDistractionEvents(
        from sourceContext: ModelContext,
        to destinationContext: ModelContext
    ) throws {
        for event in try sourceContext.fetch(FetchDescriptor<StoredDistractionEvent>()) {
            destinationContext.insert(
                StoredDistractionEvent(event: event.domainModel)
            )
        }
    }

    private static func migrateLegacyStoreIfNeeded(
        to storeURL: URL,
        baseDirectory: URL,
        fileManager: FileManager
    ) throws {
        guard !fileManager.fileExists(atPath: storeURL.path) else {
            return
        }

        let legacyStoreURL = baseDirectory.appendingPathComponent("default.store", isDirectory: false)
        guard fileManager.fileExists(atPath: legacyStoreURL.path) else {
            return
        }

        for (sourceURL, destinationURL) in storeFamilyMappings(from: legacyStoreURL, to: storeURL) {
            guard fileManager.fileExists(atPath: sourceURL.path) else {
                continue
            }
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
        }
    }

    private static func storeFamilyMappings(from sourceURL: URL, to destinationURL: URL) -> [(URL, URL)] {
        [
            (sourceURL, destinationURL),
            (
                sourceURL.deletingPathExtension().appendingPathExtension("store-wal"),
                destinationURL.deletingPathExtension().appendingPathExtension("store-wal")
            ),
            (
                sourceURL.deletingPathExtension().appendingPathExtension("store-shm"),
                destinationURL.deletingPathExtension().appendingPathExtension("store-shm")
            )
        ]
    }

    private static func ensureParentDirectoryExists(for storeURL: URL, fileManager: FileManager) throws {
        try fileManager.createDirectory(
            at: storeURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
    }
}
