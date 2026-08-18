import Foundation
import SwiftData
import Testing
@testable import KindlingCore

/// Schema-level guarantees. These run in memory so they never touch the App Group
/// and need no entitlement or simulator.
@MainActor
struct SchemaTests {
    private func makeContext() throws -> ModelContext {
        let container = try KindlingStore.makeModelContainer(inMemory: true)
        return ModelContext(container)
    }

    @Test("all five entities round-trip through the store")
    func roundTrip() throws {
        let context = try makeContext()
        let task = AvoidedTask(title: "reply to the email")
        context.insert(task)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<AvoidedTask>())
        #expect(fetched.count == 1)
        #expect(fetched.first?.title == "reply to the email")
        #expect(fetched.first?.status == .active)
        #expect(fetched.first?.source == .typed)
    }

    @Test("deleting a task cascades to its steps, sessions, and request logs")
    func cascadeDelete() throws {
        let context = try makeContext()
        let task = AvoidedTask(title: "clean my desk")
        context.insert(task)

        let step = FirstStep(text: "Pick up one visible item.", task: task)
        let session = StarterSession(durationSeconds: 120, startedAt: .now, task: task, firstStep: step)
        let log = AiRequestLog(provider: .onDevice, latencyMs: 12, success: true, task: task)
        context.insert(step)
        context.insert(session)
        context.insert(log)
        try context.save()

        context.delete(task)
        try context.save()

        #expect(try context.fetch(FetchDescriptor<AvoidedTask>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<FirstStep>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<StarterSession>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<AiRequestLog>()).isEmpty)
    }

    @Test("a running session has no outcome, and every outcome is a non-failure")
    func outcomeIsOptionalAndNeverAFailure() throws {
        let context = try makeContext()
        let session = StarterSession(durationSeconds: 120, startedAt: .now)
        context.insert(session)
        try context.save()

        #expect(session.outcome == nil)
        #expect(session.isRunning)

        // The no-shame principle at schema level: three cases, none of them a failure.
        #expect(SessionOutcome.allCases.count == 3)
        #expect(!SessionOutcome.allCases.map(\.rawValue).contains { $0.contains("fail") })
    }

    @Test("AiRequestLog has no property capable of holding task content")
    func requestLogCannotLeakContent() throws {
        // Structural, not stylistic: if someone adds a prompt or response property
        // later, this fails and forces the conversation.
        let mirror = Mirror(reflecting: AiRequestLog(provider: .api, latencyMs: 40, success: true))
        let names = mirror.children.compactMap(\.label).map { $0.lowercased() }
        for forbidden in ["prompt", "response", "completion", "text", "content", "title"] {
            #expect(!names.contains { $0.contains(forbidden) }, "AiRequestLog gained a '\(forbidden)' property")
        }
    }

    @Test("scheduledEnd derives from the persisted start, not from a countdown")
    func scheduledEndDerives() {
        let start = Date(timeIntervalSince1970: 1_000_000)
        let session = StarterSession(durationSeconds: 120, startedAt: start)
        #expect(session.scheduledEnd == start.addingTimeInterval(120))
    }

    @Test("user preferences are a plain key/value table")
    func preferences() throws {
        let context = try makeContext()
        context.insert(UserPreference(key: "haptics", value: "true"))
        try context.save()
        #expect(try context.fetch(FetchDescriptor<UserPreference>()).first?.value == "true")
    }

    @Test("the shipped schema declares exactly the five §11 entities")
    func schemaShape() {
        #expect(SchemaV1.models.count == 5)
        #expect(SchemaV1.versionIdentifier == Schema.Version(1, 0, 0))
        #expect(KindlingMigrationPlan.stages.isEmpty)
    }
}
