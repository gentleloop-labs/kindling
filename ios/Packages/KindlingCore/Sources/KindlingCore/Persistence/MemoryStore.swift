import Foundation
import SwiftData

public enum MemoryStore {
    public static let legacyAppGroupID = "group.dev.aftaab.kindling"
    public static let databaseName = "KindlingMemory.store"

    public enum StoreError: Error, CustomStringConvertible {
        case applicationSupportUnavailable
        case legacyAppGroupUnavailable(String)

        public var description: String {
            switch self {
            case .applicationSupportUnavailable:
                "Kindling could not open its private application storage."
            case .legacyAppGroupUnavailable(let id):
                "The previous Kindling data container '\(id)' is unavailable."
            }
        }
    }

    public static func storeURL(baseDirectory: URL? = nil) throws -> URL {
        let directory: URL
        if let baseDirectory {
            directory = baseDirectory
        } else {
            guard let resolved = FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first else {
                throw StoreError.applicationSupportUnavailable
            }
            directory = resolved.appending(path: "Kindling", directoryHint: .isDirectory)
        }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appending(path: databaseName)
    }

    public static func makeModelContainer(
        inMemory: Bool = false,
        baseDirectory: URL? = nil
    ) throws -> ModelContainer {
        let schema = Schema(versionedSchema: SchemaV2.self)
        let configuration: ModelConfiguration = if inMemory {
            ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        } else {
            ModelConfiguration(schema: schema, url: try storeURL(baseDirectory: baseDirectory))
        }
        return try ModelContainer(
            for: schema,
            migrationPlan: MemoryMigrationPlan.self,
            configurations: [configuration]
        )
    }

    public static func legacyStoreURL(
        appGroupID: String = legacyAppGroupID
    ) throws -> URL {
        guard let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupID
        ) else {
            throw StoreError.legacyAppGroupUnavailable(appGroupID)
        }
        return container.appending(path: "Kindling.store")
    }
}

public enum MemoryFileStore {
    public enum Directory: String, Sendable {
        case media = "Media"
        case voice = "Voice"
        case thumbnails = "Thumbnails"
        case exports = "Exports"
    }

    public static func baseURL(for directory: Directory) throws -> URL {
        let fileManager = FileManager.default
        let rootSearch: FileManager.SearchPathDirectory = switch directory {
        case .media, .voice: .applicationSupportDirectory
        case .thumbnails, .exports: .cachesDirectory
        }
        guard let root = fileManager.urls(for: rootSearch, in: .userDomainMask).first else {
            throw MemoryStore.StoreError.applicationSupportUnavailable
        }
        let url = root
            .appending(path: "Kindling", directoryHint: .isDirectory)
            .appending(path: directory.rawValue, directoryHint: .isDirectory)
        try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        if directory == .media || directory == .voice {
            try? (url as NSURL).setResourceValue(
                URLFileProtection.complete,
                forKey: .fileProtectionKey
            )
        }
        return url
    }

    public static func URL(forRelativePath relativePath: String, in directory: Directory) throws -> URL {
        try baseURL(for: directory).appending(path: relativePath)
    }

    public static func remove(relativePath: String?, from directory: Directory) {
        guard let relativePath,
              let url = try? URL(forRelativePath: relativePath, in: directory)
        else { return }
        try? FileManager.default.removeItem(at: url)
    }

    public static func directorySize(_ directory: Directory) -> Int64 {
        guard let root = try? baseURL(for: directory),
              let enumerator = FileManager.default.enumerator(
                at: root,
                includingPropertiesForKeys: [.fileSizeKey],
                options: [.skipsHiddenFiles]
              )
        else { return 0 }

        var total: Int64 = 0
        for case let url as URL in enumerator {
            total += Int64((try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
        }
        return total
    }
}
