import CloudKit
import Security

enum CloudKitDatabaseProviderError: LocalizedError, Equatable {
    case unavailable

    var errorDescription: String? {
        switch self {
        case .unavailable:
            return "CloudKit is unavailable in this build."
        }
    }
}

enum CloudKitDatabaseProvider {
    static let containerIdentifier = "iCloud.com.example.FocusSession"

    static func isAvailable() -> Bool {
        guard
            let task = SecTaskCreateFromSelf(nil),
            let entitlementValue = SecTaskCopyValueForEntitlement(
                task,
                "com.apple.developer.icloud-services" as CFString,
                nil
            )
        else {
            return false
        }

        let services = entitlementValue as? [String]
            ?? (entitlementValue as? NSArray).flatMap { $0 as? [String] }
            ?? []

        return services.contains("CloudKit") || services.contains("CloudKit-Anonymous")
    }

    static func makeDatabase(scope: CKDatabase.Scope) throws -> CKDatabase {
        guard isAvailable() else {
            throw CloudKitDatabaseProviderError.unavailable
        }

        let container = CKContainer(identifier: containerIdentifier)
        switch scope {
        case .private:
            return container.privateCloudDatabase
        case .public:
            return container.publicCloudDatabase
        case .shared:
            return container.sharedCloudDatabase
        @unknown default:
            return container.privateCloudDatabase
        }
    }
}
