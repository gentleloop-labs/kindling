import Foundation
import SwiftData

/// Builds the one `ModelContainer` the app and the widget extension both use.
///
/// This lives in `KindlingCore` rather than in either target so the two cannot
/// disagree about where the store file is. The store sits in the **App Group
/// container**, not the default app-sandbox path, because the extension has to
/// read it.
public enum KindlingStore {
    public static let appGroupID = "group.dev.aftaab.kindling"

    public enum StoreError: Error, CustomStringConvertible {
        case appGroupUnavailable(String)

        public var description: String {
            switch self {
            case .appGroupUnavailable(let id):
                return """
                    App Group container '\(id)' is unavailable. Check that the entitlement is \
                    present on both the app and the widget extension, and that the group exists \
                    on the developer account.
                    """
            }
        }
    }

    /// The SQLite file inside the shared container.
    public static func storeURL(appGroupID: String = appGroupID) throws -> URL {
        guard let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            throw StoreError.appGroupUnavailable(appGroupID)
        }
        return container.appending(path: "Kindling.store")
    }

    /// The shared container. Pass `inMemory: true` in tests so they never touch
    /// the App Group — that also lets them run without an entitlement.
    public static func makeModelContainer(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema(versionedSchema: SchemaV1.self)

        let configuration: ModelConfiguration = if inMemory {
            ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        } else {
            ModelConfiguration(schema: schema, url: try storeURL())
        }

        return try ModelContainer(
            for: schema,
            migrationPlan: KindlingMigrationPlan.self,
            configurations: [configuration]
        )
    }

    /// Backs the §11 settings toggle. Excluding the store from device backup is
    /// opt-in: the default is to be included, which is still local-first — the data
    /// only ever leaves the device inside the user's own backup.
    public static func setExcludedFromBackup(_ excluded: Bool, appGroupID: String = appGroupID) throws {
        var url = try storeURL(appGroupID: appGroupID)
        var values = URLResourceValues()
        values.isExcludedFromBackup = excluded
        try url.setResourceValues(values)
    }

    public static func isExcludedFromBackup(appGroupID: String = appGroupID) throws -> Bool {
        let url = try storeURL(appGroupID: appGroupID)
        return try url.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup ?? false
    }
}
