import Foundation
import Testing
@testable import KindlingCore

@Suite("Deterministic memory clustering")
struct ClusteringTests {
    private let service = DeterministicTripClusteringService()
    private let base = Date(timeIntervalSince1970: 1_700_000_000)

    @Test("identical input always produces identical output")
    func deterministic() {
        let input = fixtures()
        #expect(service.cluster(input) == service.cluster(input.reversed()))
    }

    @Test("every selected item appears exactly once")
    func noDroppedMedia() {
        let input = fixtures()
        let outputIDs = service.cluster(input).flatMap(\.mediaIDs)
        #expect(Set(outputIDs) == Set(input.map(\.id)))
        #expect(outputIDs.count == input.count)
    }

    @Test("six hours is one moment and more than six starts another")
    func timeBoundary() {
        let first = item("a", hours: 0)
        let boundary = item("b", hours: 6)
        let over = item("c", hours: 12.01)
        let groups = service.cluster([first, boundary, over])
        #expect(groups.count == 2)
        #expect(groups[0].mediaIDs.count == 2)
    }

    @Test("missing dates remain stable and are never discarded")
    func missingDates() {
        let items = [
            MemoryMediaMetadata(id: UUID(), stableIdentifier: "b", creationDate: nil, latitude: nil, longitude: nil),
            MemoryMediaMetadata(id: UUID(), stableIdentifier: "a", creationDate: nil, latitude: nil, longitude: nil)
        ]
        let groups = service.cluster(items)
        #expect(groups.count == 1)
        #expect(groups[0].mediaIDs == [items[1].id, items[0].id])
    }

    @Test("a gap above 72 hours proposes a trip split")
    func tripGap() {
        let splits = service.proposedTripSplits([item("a", hours: 0), item("b", hours: 73)])
        #expect(splits.first?.reason == .longTimeGap)
    }

    @Test("500 items cluster within the release budget")
    func largeImportPerformance() {
        let input = (0..<500).map { index in
            MemoryMediaMetadata(
                id: UUID(),
                stableIdentifier: String(format: "%04d", index),
                creationDate: base.addingTimeInterval(Double(index) * 900),
                latitude: 38.72 + Double(index % 7) * 0.0001,
                longitude: -9.14
            )
        }
        let clock = ContinuousClock()
        let elapsed = clock.measure { _ = service.cluster(input) }
        #expect(elapsed < .seconds(10))
        #expect(service.cluster(input).flatMap(\.mediaIDs).count == 500)
    }

    private func fixtures() -> [MemoryMediaMetadata] {
        [item("c", hours: 9), item("a", hours: 0), item("b", hours: 1)]
    }

    private func item(_ stableID: String, hours: Double) -> MemoryMediaMetadata {
        MemoryMediaMetadata(
            id: UUID(uuidString: "00000000-0000-0000-0000-00000000000\(stableID == "a" ? 1 : stableID == "b" ? 2 : 3)")!,
            stableIdentifier: stableID,
            creationDate: base.addingTimeInterval(hours * 3600),
            latitude: 48.8566,
            longitude: 2.3522
        )
    }
}
