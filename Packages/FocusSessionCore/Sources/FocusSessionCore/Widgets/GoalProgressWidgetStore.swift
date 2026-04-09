import Foundation

public enum FocusSessionSharedContainer {
    public static let appGroupIdentifier = "group.com.example.FocusSession"
}

public enum GoalProgressWidgetStoreError: Error, Equatable {
    case missingAppGroupContainer
}

public struct GoalProgressWidgetStore {
    private let containerURL: URL
    private let fileManager: FileManager
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(containerURL: URL, fileManager: FileManager = .default) {
        self.containerURL = containerURL
        self.fileManager = fileManager
    }

    public init(
        fileManager: FileManager = .default,
        appGroupIdentifier: String = FocusSessionSharedContainer.appGroupIdentifier
    ) throws {
        guard let rootURL = fileManager.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) else {
            throw GoalProgressWidgetStoreError.missingAppGroupContainer
        }

        self.init(
            containerURL: rootURL
                .appendingPathComponent("Widgets", isDirectory: true)
                .appendingPathComponent("GoalProgress", isDirectory: true),
            fileManager: fileManager
        )
    }

    public func write(_ snapshot: GoalProgressWidgetSnapshot) throws {
        try fileManager.createDirectory(at: containerURL, withIntermediateDirectories: true)
        let data = try encoder.encode(snapshot)
        try data.write(to: snapshotURL, options: .atomic)
    }

    public func read() throws -> GoalProgressWidgetSnapshot {
        let data = try Data(contentsOf: snapshotURL)
        return try decoder.decode(GoalProgressWidgetSnapshot.self, from: data)
    }

    public func clear() throws {
        guard fileManager.fileExists(atPath: snapshotURL.path) else {
            return
        }
        try fileManager.removeItem(at: snapshotURL)
    }

    private var snapshotURL: URL {
        containerURL.appendingPathComponent("goals-progress.json", isDirectory: false)
    }
}
