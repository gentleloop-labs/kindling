import Foundation
import SwiftData

/// The five §11 entities, nested inside the versioned schema that ships as v1.
///
/// There is nothing to migrate from yet. The `VersionedSchema` scaffolding exists
/// anyway, because lightweight migrations are only free if the versioning is
/// already in place when the first additive change arrives.
///
/// Deliberately absent, and not to be added speculatively: a `Reminder` entity
/// (feature not built), a persisted mascot state (derivable from task and session
/// at render time — persisting it would create a second source of truth that
/// drifts), and `SubscriptionEntitlement` (billing is Phase 5).
public enum SchemaV1: VersionedSchema {
    public static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }

    public static var models: [any PersistentModel.Type] {
        [AvoidedTask.self, FirstStep.self, StarterSession.self, UserPreference.self, AiRequestLog.self]
    }

    // MARK: - AvoidedTask

    /// Named `AvoidedTask` rather than `Task` because `Task` is Swift's concurrency
    /// type. Decided once, here, so it never needs renaming across call sites.
    ///
    /// **Sensitive.** A title can incidentally reveal health, financial, or
    /// relationship information. Local-only by default; never rendered on a
    /// lock-screen surface.
    @Model
    public final class AvoidedTask {
        public var id: UUID = UUID()
        public var title: String = ""
        public var statusRaw: String = TaskStatus.active.rawValue
        public var sourceRaw: String = TaskSource.typed.rawValue
        public var obstacleTag: String?
        /// Nullable pointer to the step most recently shown for this task.
        public var lastFirstStepID: UUID?
        public var createdAt: Date = Date()
        public var updatedAt: Date = Date()

        // Delete rules are set explicitly rather than left to defaults: clearing a
        // task must take its steps, sessions, and request logs with it.
        @Relationship(deleteRule: .cascade, inverse: \FirstStep.task)
        public var firstSteps: [FirstStep] = []

        @Relationship(deleteRule: .cascade, inverse: \StarterSession.task)
        public var sessions: [StarterSession] = []

        @Relationship(deleteRule: .cascade, inverse: \AiRequestLog.task)
        public var aiRequestLogs: [AiRequestLog] = []

        public var status: TaskStatus {
            get { TaskStatus(rawValue: statusRaw) ?? .active }
            set { statusRaw = newValue.rawValue }
        }

        public var source: TaskSource {
            get { TaskSource(rawValue: sourceRaw) ?? .typed }
            set { sourceRaw = newValue.rawValue }
        }

        public init(
            id: UUID = UUID(),
            title: String,
            status: TaskStatus = .active,
            source: TaskSource = .typed,
            obstacleTag: String? = nil,
            createdAt: Date = Date()
        ) {
            self.id = id
            self.title = title
            self.statusRaw = status.rawValue
            self.sourceRaw = source.rawValue
            self.obstacleTag = obstacleTag
            self.createdAt = createdAt
            self.updatedAt = createdAt
        }
    }

    // MARK: - FirstStep

    /// Sensitive for the same reason as `AvoidedTask` — step text quotes the task back.
    @Model
    public final class FirstStep {
        public var id: UUID = UUID()
        public var text: String = ""
        public var generatedByRaw: String = StepOrigin.template.rawValue
        public var createdAt: Date = Date()
        public var task: AvoidedTask?

        public var generatedBy: StepOrigin {
            get { StepOrigin(rawValue: generatedByRaw) ?? .template }
            set { generatedByRaw = newValue.rawValue }
        }

        public init(
            id: UUID = UUID(),
            text: String,
            generatedBy: StepOrigin = .template,
            createdAt: Date = Date(),
            task: AvoidedTask? = nil
        ) {
            self.id = id
            self.text = text
            self.generatedByRaw = generatedBy.rawValue
            self.createdAt = createdAt
            self.task = task
        }
    }

    // MARK: - StarterSession

    /// `outcome` has three cases and no failure case. That is the no-shame
    /// principle enforced at schema level rather than only in the UI — a failed
    /// session is not representable here.
    @Model
    public final class StarterSession {
        public var id: UUID = UUID()
        public var durationSeconds: Int = 120
        public var startedAt: Date = Date()
        public var endedAt: Date?
        /// Nil while the session is running.
        public var outcomeRaw: String?
        public var task: AvoidedTask?
        public var firstStep: FirstStep?

        public var outcome: SessionOutcome? {
            get { outcomeRaw.flatMap(SessionOutcome.init(rawValue:)) }
            set { outcomeRaw = newValue?.rawValue }
        }

        public var isRunning: Bool { endedAt == nil }

        /// The moment the timer is due to end, derived from the persisted start.
        /// Remaining time is always computed from this against wall-clock, never
        /// from an in-memory countdown — that is what makes force-quit survivable.
        public var scheduledEnd: Date {
            startedAt.addingTimeInterval(TimeInterval(durationSeconds))
        }

        public init(
            id: UUID = UUID(),
            durationSeconds: Int,
            startedAt: Date,
            endedAt: Date? = nil,
            outcome: SessionOutcome? = nil,
            task: AvoidedTask? = nil,
            firstStep: FirstStep? = nil
        ) {
            self.id = id
            self.durationSeconds = durationSeconds
            self.startedAt = startedAt
            self.endedAt = endedAt
            self.outcomeRaw = outcome?.rawValue
            self.task = task
            self.firstStep = firstStep
        }
    }

    // MARK: - UserPreference

    /// A plain key/value table, so new settings never need a schema change.
    @Model
    public final class UserPreference {
        @Attribute(.unique) public var key: String = ""
        public var value: String = ""

        public init(key: String, value: String) {
            self.key = key
            self.value = value
        }
    }

    // MARK: - AiRequestLog

    /// **There is no prompt or response property, on purpose.** Task content cannot
    /// leak through this table because there is nowhere for it to be written.
    /// v1 ships no AI at all; this exists so the v1.1 layer has somewhere to record
    /// latency and success without ever touching content.
    @Model
    public final class AiRequestLog {
        public var id: UUID = UUID()
        public var requestedAt: Date = Date()
        public var providerRaw: String = AiProvider.onDevice.rawValue
        public var latencyMs: Int = 0
        public var success: Bool = false
        public var task: AvoidedTask?

        public var provider: AiProvider {
            get { AiProvider(rawValue: providerRaw) ?? .onDevice }
            set { providerRaw = newValue.rawValue }
        }

        public init(
            id: UUID = UUID(),
            requestedAt: Date = Date(),
            provider: AiProvider,
            latencyMs: Int,
            success: Bool,
            task: AvoidedTask? = nil
        ) {
            self.id = id
            self.requestedAt = requestedAt
            self.providerRaw = provider.rawValue
            self.latencyMs = latencyMs
            self.success = success
            self.task = task
        }
    }
}

// Top-level names so call sites read as `AvoidedTask`, not `SchemaV1.AvoidedTask`.
public typealias AvoidedTask = SchemaV1.AvoidedTask
public typealias FirstStep = SchemaV1.FirstStep
public typealias StarterSession = SchemaV1.StarterSession
public typealias UserPreference = SchemaV1.UserPreference
public typealias AiRequestLog = SchemaV1.AiRequestLog

/// One shipped schema so far. Additive changes migrate lightweight with no stage
/// written by hand; a stage is only needed when a change is not additive.
public enum KindlingMigrationPlan: SchemaMigrationPlan {
    public static var schemas: [any VersionedSchema.Type] { [SchemaV1.self] }
    public static var stages: [MigrationStage] { [] }
}
