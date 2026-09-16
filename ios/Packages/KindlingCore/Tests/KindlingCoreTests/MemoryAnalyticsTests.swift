import Testing
@testable import KindlingCore

@Suite("Content-free memory analytics")
struct MemoryAnalyticsTests {
    @Test("events expose only fixed parameter keys")
    func fixedParameters() {
        let events: [AnalyticsEvent] = [
            .photoSelectionCompleted(count: .sixToTwenty),
            .importCompleted(duration: .threeToTenSeconds, count: .twentyOneToFifty),
            .sparkAnswered(family: .sensory),
            .searchPerformed(results: .oneToFive),
            .paywallDisplayed(source: .thirdTrip)
        ]
        let allowed = Set([
            "count_bucket", "duration_bucket", "error_code", "prompt_family",
            "artifact_type", "theme", "privacy", "result_count_bucket",
            "paywall_source", "product_period", "outcome"
        ])
        for event in events {
            #expect(Set(event.parameters.keys).isSubset(of: allowed))
        }
    }

    @Test("no analytics key can carry private memory content")
    func noSensitiveKeys() {
        let combined = AnalyticsEvent.recapExported(
            type: .postcard,
            theme: .standard,
            privacy: .shareable
        ).parameters.keys.joined(separator: " ")
        for forbidden in ["title", "note", "coordinate", "filename", "query", "place"] {
            #expect(!combined.contains(forbidden))
        }
    }
}
