import Foundation
import KindlingCore
import KindlingUI
import SwiftData
import Observation

/// Drives the rescue flow. Onboarding *is* the first rescue, so these screens serve
/// both a first run and every subsequent use — there is no separate demo path.
///
/// Rules live in `KindlingCore` (the step engine, the session machine, the status
/// transitions) and are called from here. Nothing that has a rule to it is decided
/// in a view.
@Observable
@MainActor
final class RescueFlowModel {
    enum Screen: Equatable {
        case welcome
        case taskEntry
        case firstStep
        case session
        case outcome
        case success
        case notificationAsk
    }

    var screen: Screen = .welcome
    var draftTitle = ""
    /// Which alternative step the user is on. Regeneration cycles deterministically.
    var stepAttempt = 0
    var suggestedStep = ""
    var durationSeconds = 120

    /// Set once the §14 ask has been answered in this session, so it is never
    /// re-asked after a decline.
    var notificationAskAnswered = false

    private(set) var task: AvoidedTask?
    private(set) var session: StarterSession?
    private(set) var lastOutcome: SessionOutcome?
    /// Recorded on the persisted `FirstStep` so history distinguishes a template
    /// step from an AI one.
    private(set) var lastStepOrigin: StepOrigin = .template

    /// True while an AI call is in flight. The step screen shows the Ember
    /// working rather than an empty space — and because the engine always
    /// resolves to *something*, this can never hang on a failure.
    var isGeneratingStep = false

    var engine: any AsyncStepSuggesting
    let clock: SessionClock
    private let analytics: any AnalyticsTracking
    private let context: ModelContext

    init(
        context: ModelContext,
        engine: any AsyncStepSuggesting = LocalStepEngine(),
        clock: SessionClock = .system,
        analytics: any AnalyticsTracking = NoOpAnalyticsTracker()
    ) {
        self.context = context
        self.engine = engine
        self.clock = clock
        self.analytics = analytics
        let preferences = PreferencesStore(context: context)
        self.durationSeconds = preferences
            .int(PreferenceKey.lastDurationSeconds, default: SessionDuration.default)
        self.screen = preferences.bool(PreferenceKey.onboardingCompletedV1, default: false)
            ? .taskEntry
            : .welcome
    }

    /// §6: the last timer choice is remembered, so the user re-decides nothing.
    func choose(durationSeconds seconds: Int) {
        guard SessionDuration.allowed.contains(seconds) else { return }
        durationSeconds = seconds
        PreferencesStore(context: context).set(PreferenceKey.lastDurationSeconds, seconds)
    }

    // MARK: - Ember

    /// Derived every time it is read, never stored. §11 keeps mascot state out of
    /// the schema precisely so it cannot drift from the data.
    var emberState: EmberState {
        switch screen {
        case .welcome: .resting
        case .taskEntry: draftTitle.isEmpty ? .resting : .ready
        case .firstStep: .ready
        case .session: .focusing
        case .outcome: lastOutcome == .distracted ? .distracted : .ready
        case .success, .notificationAsk: .celebrating
        }
    }

    // MARK: - Screen 1 → 2

    func beginRescue() {
        PreferencesStore(context: context).set(PreferenceKey.onboardingCompletedV1, true)
        analytics.track(.onboardingCompleted)
        beginNewTask()
    }

    /// Starts a genuinely new flow. Clearing the selected model is essential:
    /// otherwise `startSession()` edits the previous task's title in place.
    func beginNewTask() {
        task = nil
        session = nil
        lastOutcome = nil
        draftTitle = ""
        suggestedStep = ""
        stepAttempt = 0
        lastStepOrigin = .template
        screen = .taskEntry
        // Load the on-device model while they type, not while they wait.
        engine.prewarm()
    }

    // MARK: - Screen 2 → 3

    var canContinueFromTaskEntry: Bool {
        !TemplateStepEngine.normalize(draftTitle).isEmpty
    }

    /// The blank-page mitigation. Filling the field rather than skipping ahead is
    /// deliberate: the user still sees their own words on the next screen.
    func useSampleTask() {
        draftTitle = Self.sampleTask
    }

    static let sampleTask = "reply to that one message you've been putting off"

    func showFirstStep() async {
        guard canContinueFromTaskEntry else { return }
        analytics.track(.taskEntered)
        stepAttempt = 0
        // Move to the step screen first, then fill it in. The user sees progress
        // immediately instead of a frozen entry screen while a request is in flight.
        screen = .firstStep
        await generateStep(attempt: 0)
    }

    /// With the template engine this is deterministic and cycles. With AI it asks
    /// for a distinctly different angle, and still falls back to the cycling
    /// template list if the call fails.
    func regenerateStep() async {
        stepAttempt += 1
        await generateStep(attempt: stepAttempt)
    }

    private func generateStep(attempt: Int) async {
        isGeneratingStep = true
        defer { isGeneratingStep = false }

        let suggestion = await engine.suggestFirstStep(for: draftTitle, attempt: attempt)
        suggestedStep = Self.cleanStepCopy(suggestion.text)
        lastStepOrigin = suggestion.origin
        let origin = AnalyticsGenerationOrigin(
            stepOrigin: suggestion.origin,
            provider: suggestion.provider
        )
        analytics.track(attempt == 0
                        ? .firstStepDisplayed(origin: origin)
                        : .stepRegenerated(origin: origin))

        // §11: latency and outcome only. There is nowhere in this row to put the
        // task or the step, which is what makes leaking them impossible.
        if suggestion.attemptedRemote {
            context.insert(
                AiRequestLog(
                    requestedAt: clock.now(),
                    provider: suggestion.provider,
                    latencyMs: suggestion.latencyMs,
                    success: suggestion.origin == .ai,
                    task: task
                )
            )
            save()
        }
    }

    var echoedTask: String {
        TemplateStepEngine.normalize(draftTitle)
    }

    private static func cleanStepCopy(_ text: String) -> String {
        switch text {
        case "Decide how you'll reach them—call, message, or in person—and pick one.":
            return "Decide how you'll reach them: call, message, or in person. Then pick one."
        case "Find the amount and due date—nothing else yet.":
            return "Find the amount and due date. Nothing else yet."
        default:
            return text
                .replacingOccurrences(of: " — ", with: ", ")
                .replacingOccurrences(of: "—", with: ", ")
                .replacingOccurrences(of: " – ", with: " - ")
                .replacingOccurrences(of: "–", with: "-")
        }
    }

    // MARK: - Screen 3 → 4: starting a session

    /// Persists the task, the step, and the session together, then moves to the
    /// timer. `startedAt` is written here and never updated — everything the timer
    /// shows is derived from it, which is what lets the session survive a
    /// force-quit, a reboot, or the app being closed entirely.
    func startSession() {
        let task: AvoidedTask
        if let existing = self.task, existing.status != .discarded {
            task = existing
            task.title = echoedTask
            task.updatedAt = clock.now()
        } else {
            task = AvoidedTask(title: echoedTask, source: .typed, createdAt: clock.now())
            context.insert(task)
        }

        let step = FirstStep(text: suggestedStep, generatedBy: lastStepOrigin, createdAt: clock.now(), task: task)
        context.insert(step)
        task.lastFirstStepID = step.id

        let session = StarterSession(
            durationSeconds: durationSeconds,
            startedAt: clock.now(),
            task: task,
            firstStep: step
        )
        context.insert(session)

        if task.status != .active {
            task.status = .active
        }

        save()
        self.task = task
        self.session = session
        screen = .session
        analytics.track(.sessionStarted(
            duration: AnalyticsDurationBucket(durationSeconds: durationSeconds)
        ))

        let snapshot = SessionSnapshot(
            durationSeconds: session.durationSeconds,
            startedAt: session.startedAt,
            endedAt: nil
        )
        LiveActivityController.start(for: snapshot)
        // Only fires if the session ends while the app is not in front; cancelled
        // on return, so nobody is notified about a timer they just watched finish.
        Task { await NotificationService.scheduleSessionEnd(at: session.scheduledEnd, durationSeconds: session.durationSeconds) }
    }

    // MARK: - Screen 4 → 5

    var sessionSnapshot: SessionSnapshot? {
        session.map {
            SessionSnapshot(durationSeconds: $0.durationSeconds, startedAt: $0.startedAt, endedAt: $0.endedAt)
        }
    }

    /// The user tapped Stop. Available at every moment of a session, and it is not a
    /// failure — it goes to the same three choices as running the clock out.
    func stopSession() {
        endSession(at: clock.now())
    }

    /// The timer reached its end, whether or not the app was open to see it.
    func sessionElapsed() {
        guard let session, session.endedAt == nil else { return }
        endSession(at: session.scheduledEnd)
    }

    private func endSession(at date: Date) {
        guard let session, session.endedAt == nil else {
            screen = .outcome
            return
        }
        session.endedAt = date
        save()
        screen = .outcome

        NotificationService.cancelSessionEnd()
        Task { await LiveActivityController.end() }
    }

    // MARK: - Screen 5 → 6

    /// All three land somewhere legitimate. `TaskStateMachine` owns where, so the
    /// rule is unit-tested rather than decided in a view.
    func record(outcome: SessionOutcome) {
        analytics.track(.sessionOutcome(outcome))
        lastOutcome = outcome
        session?.outcome = outcome

        if PlusNudgePolicy.countsAsValueMoment(outcome) {
            let preferences = PreferencesStore(context: context)
            let count = preferences.int(PreferenceKey.plusValueMomentCountV1, default: 0)
            preferences.set(PreferenceKey.plusValueMomentCountV1, count + 1)
        }

        if let task {
            let next = TaskStateMachine.status(after: outcome, from: task.status)
            if TaskStateMachine.canTransition(from: task.status, to: next) {
                task.status = next
            }
            task.updatedAt = clock.now()
        }
        save()

        screen = outcome == .keptGoing ? .firstStep : .success
    }

    // MARK: - Resume

    /// Reopens a parked task with nothing to re-enter. §22 names zero data loss on
    /// resume as a beta exit criterion, so this path is deliberately dumb: read what
    /// was persisted and put the user back where they were.
    func restoreInterruptedWork() {
        var descriptor = FetchDescriptor<AvoidedTask>(
            predicate: #Predicate { $0.statusRaw == "active" || $0.statusRaw == "stepped_away" },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1

        guard let task = try? context.fetch(descriptor).first else { return }
        resume(task)
    }

    /// Selects a specific item from Your tasks rather than always choosing the
    /// most recently updated one.
    func resumeTask(id: UUID) {
        var descriptor = FetchDescriptor<AvoidedTask>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        guard let task = try? context.fetch(descriptor).first,
              ActiveTaskPolicy.countsTowardLimit(task.status)
        else { return }
        resume(task)
    }

    /// If the shelf finishes the task currently shown behind the sheet, clear the
    /// flow as well so a discarded task cannot be accidentally revived.
    func handleReleasedTask(id: UUID) {
        guard task?.id == id else { return }
        beginNewTask()
    }

    private func resume(_ task: AvoidedTask) {
        self.task = task
        draftTitle = task.title

        let latest = task.sessions.sorted { $0.startedAt > $1.startedAt }.first
        let rawStep = latest?.firstStep?.text
            ?? task.firstSteps.sorted { $0.createdAt > $1.createdAt }.first?.text
            ?? TemplateStepEngine().suggestFirstStep(for: task.title, attempt: 0)
        suggestedStep = Self.cleanStepCopy(rawStep)

        if let latest, latest.endedAt == nil {
            let snapshot = SessionSnapshot(
                durationSeconds: latest.durationSeconds,
                startedAt: latest.startedAt,
                endedAt: nil
            )
            session = latest
            durationSeconds = latest.durationSeconds

            // Ended while the app was closed: go straight to the three choices
            // rather than showing a timer that has already run out.
            if SessionRuntime.endedWhileAway(snapshot, clock: clock) {
                sessionElapsed()
            } else {
                screen = .session
            }
        } else {
            session = latest
            screen = .firstStep
        }
    }

    /// Called when the app comes to the front. Three things can have changed while
    /// it was away: the session may have ended, the user may have dismissed the
    /// Activity, or the device may have rebooted. All three reconcile here.
    func handleForeground() {
        NotificationService.cancelSessionEnd()

        if let session, session.endedAt == nil {
            let snapshot = SessionSnapshot(
                durationSeconds: session.durationSeconds,
                startedAt: session.startedAt,
                endedAt: nil
            )
            if SessionRuntime.endedWhileAway(snapshot, clock: clock) {
                sessionElapsed()
                return
            }
        }

        let running = session?.endedAt == nil && session != nil
        Task { await LiveActivityController.reconcile(hasRunningSession: running) }
    }

    private func save() {
        do {
            try context.save()
        } catch {
            // A failed save must never take the session down with it — the user is
            // mid-rescue. Surfacing this is Phase 5 telemetry work.
            assertionFailure("save failed: \(error)")
        }
    }

    #if DEBUG
    /// Jumps straight to a screen with a seeded task, so any single screen can be
    /// inspected without tapping through the whole flow. Debug-only; never
    /// compiled into a release build.
    ///
    /// Drive it with: `SIMCTL_CHILD_KINDLING_SCREEN=firstStep xcrun simctl launch ...`
    /// Add `SIMCTL_CHILD_KINDLING_FORCE_AI=1` to exercise the real engine chain.
    func applyDebugScreenOverride() async {
        guard let name = ProcessInfo.processInfo.environment["KINDLING_SCREEN"] else { return }
        draftTitle = ProcessInfo.processInfo.environment["KINDLING_TASK"] ?? "reply to the email"
        suggestedStep = TemplateStepEngine().suggestFirstStep(for: draftTitle, attempt: 0)

        switch name {
        case "welcome", "welcomePlus": screen = .welcome
        case "taskEntry": screen = .taskEntry
        case "firstStep":
            // Route through the real engine so this actually tests the chain,
            // rather than quietly showing a template step.
            screen = .firstStep
            await generateStep(attempt: 0)
        case "session": startSession()
        case "outcome": startSession(); screen = .outcome
        case "success": screen = .success
        case "notificationAsk": screen = .notificationAsk
        default: break
        }
    }
    #endif
}
