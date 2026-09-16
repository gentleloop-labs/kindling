import Foundation
import Testing
@testable import KindlingCore

@Suite("Legacy task data")
struct LegacyDataServiceTests {
    @Test("legacy data is detected and deleted only on request")
    func detectAndDelete() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let storeURL = directory.appending(path: "Kindling.store")
        try Data("legacy".utf8).write(to: storeURL)
        try Data("wal".utf8).write(to: URL(fileURLWithPath: storeURL.path + "-wal"))
        let service = LegacyDataService(storeURLProvider: { storeURL })

        #expect(service.hasLegacyData())
        try service.deleteLegacyData()
        #expect(!service.hasLegacyData())
    }
}
