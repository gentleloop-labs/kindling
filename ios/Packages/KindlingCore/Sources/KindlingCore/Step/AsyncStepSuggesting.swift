import Foundation

/// Where a suggestion came from, and what it cost.
///
/// The origin is carried out of the engine rather than inferred by the caller so
/// `FirstStep.generatedBy` records what actually happened — including when an AI
/// call was attempted and quietly fell back to a template.
public struct StepSuggestion: Sendable, Equatable {
    public let text: String
    public let origin: StepOrigin
    public let latencyMs: Int
    /// True when an AI generator was attempted, whatever the outcome. Drives the
    /// `AiRequestLog` row — which records latency and success only, never content.
    public let attemptedRemote: Bool
    /// Which generator served, or last attempted. Distinguishes an on-device step
    /// from a hosted one in history, which matters because only one of the two
    /// sent anything off the device.
    public let provider: AiProvider

    public init(
        text: String,
        origin: StepOrigin,
        latencyMs: Int,
        attemptedRemote: Bool,
        provider: AiProvider = .onDevice
    ) {
        self.text = text
        self.origin = origin
        self.latencyMs = latencyMs
        self.attemptedRemote = attemptedRemote
        self.provider = provider
    }
}

/// The async counterpart to `StepSuggesting`, for engines that may go off-device.
///
/// Deliberately **non-throwing**: a step suggestion has no failure case that the
/// UI is allowed to see. Every error path inside an implementation must resolve
/// to a usable step, because the alternative is a dead end at the exact moment
/// someone is least able to cope with one.
public protocol AsyncStepSuggesting: Sendable {
    func suggestFirstStep(for task: String, attempt: Int) async -> StepSuggestion
    /// Optional hint that a suggestion is likely soon. Default does nothing.
    func prewarm()
}

public extension AsyncStepSuggesting {
    func prewarm() {}
}

/// Lets the template engine satisfy the async protocol unchanged, so the app can
/// hold a single type whether or not AI is switched on.
public struct LocalStepEngine: AsyncStepSuggesting {
    private let engine: any StepSuggesting

    public init(engine: any StepSuggesting = TemplateStepEngine()) {
        self.engine = engine
    }

    public func suggestFirstStep(for task: String, attempt: Int) async -> StepSuggestion {
        StepSuggestion(
            text: engine.suggestFirstStep(for: task, attempt: attempt),
            origin: .template,
            latencyMs: 0,
            attemptedRemote: false
        )
    }
}
