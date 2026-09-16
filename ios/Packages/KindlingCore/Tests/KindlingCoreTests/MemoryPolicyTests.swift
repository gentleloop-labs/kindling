import Foundation
import Testing
@testable import KindlingCore

@Suite("Memory product policies")
struct MemoryPolicyTests {
    @Test("free users save two trips and Pro removes the limit")
    func tripLimit() {
        #expect(TripLimitPolicy.canSaveTrip(completedTripCount: 0, hasPro: false))
        #expect(TripLimitPolicy.canSaveTrip(completedTripCount: 1, hasPro: false))
        #expect(!TripLimitPolicy.canSaveTrip(completedTripCount: 2, hasPro: false))
        #expect(TripLimitPolicy.canSaveTrip(completedTripCount: 99, hasPro: true))
    }

    @Test("all new products grant Pro and old task products grant nothing")
    func productMapping() {
        #expect(ProductID.all.count == 3)
        for product in ProductID.all { #expect(ProductID.entitlement(for: product) == .pro) }
        #expect(ProductID.entitlement(for: "dev.aftaab.kindling.multitask.monthly") == nil)
    }

    @Test("sensitive and excluded memories never resurface")
    func resurfacingSafety() {
        let now = Date(timeIntervalSince1970: 2_000_000_000)
        let old = now.addingTimeInterval(-100 * 24 * 3600)
        let policy = ResurfacingPolicy()
        let safe = candidate(capturedAt: old)
        #expect(policy.eligible(safe, now: now))
        #expect(!policy.eligible(candidate(capturedAt: old, sensitive: true), now: now))
        #expect(!policy.eligible(candidate(capturedAt: old, excluded: true), now: now))
    }

    @Test("Spark selection respects skipped families and answered prompts")
    func sparks() throws {
        let selector = SparkSelector()
        let momentID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let first = try #require(selector.next(for: momentID, excludingFamilies: [], answeredKeys: []))
        let second = selector.next(
            for: momentID,
            excludingFamilies: [first.family],
            answeredKeys: [first.key]
        )
        #expect(second?.family != first.family)
        #expect(second?.key != first.key)
    }

    private func candidate(
        capturedAt: Date,
        sensitive: Bool = false,
        excluded: Bool = false
    ) -> ResurfacingCandidate {
        ResurfacingCandidate(
            momentID: UUID(),
            tripID: UUID(),
            capturedAt: capturedAt,
            lastPresentedAt: nil,
            isTripArchived: false,
            isHidden: false,
            isSensitive: sensitive,
            doNotResurface: excluded
        )
    }
}
