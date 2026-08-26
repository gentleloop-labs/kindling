import Testing
@testable import KindlingCore

struct AnalyticsTests {
    @Test("analytics exposes only the fixed event taxonomy")
    func fixedPayloads() {
        #expect(AnalyticsEvent.taskEntered.name == "task_entered")
        #expect(AnalyticsEvent.taskEntered.parameters.isEmpty)
        #expect(AnalyticsEvent.sessionStarted(duration: .twoMinutes).parameters == [
            "duration_bucket": "2_minutes"
        ])
        #expect(AnalyticsEvent.sessionOutcome(.distracted).parameters == [
            "outcome": "distracted"
        ])
        #expect(AnalyticsEvent.paywallDisplayed(source: .taskShelf).parameters == [
            "paywall_source": "task_shelf"
        ])
        #expect(AnalyticsEvent.upgradeCompleted(period: .lifetime).parameters == [
            "product_period": "lifetime"
        ])
    }

    @Test("generation origin distinguishes local, hosted, and template")
    func generationOrigins() {
        #expect(AnalyticsGenerationOrigin(stepOrigin: .template, provider: .api) == .template)
        #expect(AnalyticsGenerationOrigin(stepOrigin: .ai, provider: .onDevice) == .onDevice)
        #expect(AnalyticsGenerationOrigin(stepOrigin: .ai, provider: .api) == .hosted)
    }
}
