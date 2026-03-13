import Foundation
import SwiftData

enum FocusSessionModelContainer {
    enum StoreConfigurationError: Error {
        case missingApplicationSupportDirectory
    }

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
        let storeURL = try persistentStoreURL()
        return try makePersistent(at: storeURL)
    }

    static func makeInMemory() throws -> ModelContainer {
        let configuration = ModelConfiguration(
            isStoredInMemoryOnly: true
        )
        return try makeContainer(configuration: configuration)
    }

    static func makePersistent(at storeURL: URL) throws -> ModelContainer {
        let configuration = ModelConfiguration(url: storeURL)
        return try makeContainer(configuration: configuration)
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

    private static func migrateLegacyStoreIfNeeded(
        to storeURL: URL,
        baseDirectory: URL,
        fileManager: FileManager
    ) throws {
        guard !fileManager.fileExists(atPath: storeURL.path()) else {
            return
        }

        let legacyStoreURL = baseDirectory.appendingPathComponent("default.store", isDirectory: false)
        guard fileManager.fileExists(atPath: legacyStoreURL.path()) else {
            return
        }

        for (sourceURL, destinationURL) in storeFamilyMappings(from: legacyStoreURL, to: storeURL) {
            guard fileManager.fileExists(atPath: sourceURL.path()) else {
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
}
