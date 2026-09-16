import Foundation

public struct LegacyDataService: Sendable {
    private let storeURLProvider: @Sendable () throws -> URL

    public init(storeURLProvider: @escaping @Sendable () throws -> URL = {
        try MemoryStore.legacyStoreURL()
    }) {
        self.storeURLProvider = storeURLProvider
    }

    public func hasLegacyData() -> Bool {
        guard let url = try? storeURLProvider() else { return false }
        return Self.storeFiles(for: url).contains { FileManager.default.fileExists(atPath: $0.path) }
    }

    public func deleteLegacyData() throws {
        let url = try storeURLProvider()
        for candidate in Self.storeFiles(for: url) where FileManager.default.fileExists(atPath: candidate.path) {
            try FileManager.default.removeItem(at: candidate)
        }
    }

    private static func storeFiles(for url: URL) -> [URL] {
        [
            url,
            URL(fileURLWithPath: url.path + "-shm"),
            URL(fileURLWithPath: url.path + "-wal")
        ]
    }
}
