import Foundation

#if canImport(FoundationModels)
import FoundationModels

/// Step generation using Apple's on-device model.
///
/// This is the best available fit for Kindling's local-first promise: the task
/// text never leaves the phone, it works with no network, it costs nothing, and
/// it needs no privacy disclosure, no API key, and no server.
///
/// The catch is hardware. Apple Intelligence requires an iPhone 15 Pro or later
/// (A17 Pro, 8GB RAM); everything older reports `deviceNotEligible`. So this is a
/// layer in the chain, never the whole answer — `StepEngineChain` moves on when it
/// is unavailable.
@available(iOS 26.0, macOS 26.0, *)
public struct OnDeviceStepGenerator: StepGenerating {
    /// Constrained generation, so the model returns a step rather than prose about
    /// a step. `@Guide` carries the shape requirements into the schema itself.
    @Generable
    struct StepReply {
        @Guide(description: "One imperative sentence under 12 words naming a single physical action.")
        var step: String
    }

    /// KEEP IN SYNC with `SYSTEM_PROMPT` in `proxy/src/index.ts`. The two sources
    /// must produce steps that feel like the same product, so a rule added to one
    /// belongs in both.
    static let instructions = """
        You generate the single smallest first physical action for someone with ADHD \
        who knows what they need to do and cannot start. They are frozen right now.

        Rules:
        - Exactly one sentence, imperative, under 12 words.
        - A physical, observable action they could finish in under two minutes.
        - Concrete: name the object, app, page, or person involved.
        - Make it smaller than they expect. Opening the thing IS the step.
        - No encouragement, no praise, no explanation, no preamble.
        - Never ask a question. Never mention that the task is hard or that they're stuck.
        - Never name a specific company, brand, website, domain, app store, government
          agency, or phone number. You do not know the person's country, language, or which
          services they use, and a step naming the wrong country's website is worse than a
          vague one. Say "your bank's app", "their contact", "the booking page" instead.
        - For anything official — passports, visas, taxes, licences, benefits, utilities —
          do not name the agency or its site. Send them to a search instead, e.g.
          "Open your browser and search for passport renewal."
        """

    public let provider: AiProvider = .onDevice

    public init() {}

    public var isAvailable: Bool {
        get async { SystemLanguageModel.default.isAvailable }
    }

    /// Why the model can't run, for diagnostics and the settings screen. Never
    /// shown as an error in the rescue flow — the chain just moves on.
    public static var unavailableReason: String? {
        switch SystemLanguageModel.default.availability {
        case .available:
            return nil
        case .unavailable(let reason):
            switch reason {
            case .deviceNotEligible:
                return "This iPhone doesn't support Apple Intelligence."
            case .appleIntelligenceNotEnabled:
                return "Apple Intelligence is turned off in Settings."
            case .modelNotReady:
                return "The on-device model is still downloading."
            @unknown default:
                return "On-device steps aren't available right now."
            }
        @unknown default:
            return "On-device steps aren't available right now."
        }
    }

    /// Loads the model before it is needed.
    ///
    /// Measured on an M4 simulator: the first generation costs ~5.8s, every one
    /// after ~1.3-1.7s. That first hit lands exactly where it hurts most — someone
    /// frozen, waiting. Calling this when the task-entry screen appears means the
    /// model loads while they are still typing, so their first real request is
    /// already warm. Safe to call repeatedly and safe to ignore.
    public func prewarm() {
        guard SystemLanguageModel.default.isAvailable else { return }
        LanguageModelSession(instructions: Self.instructions).prewarm()
    }

    public func generateStep(for task: String, attempt: Int) async throws -> String {
        guard SystemLanguageModel.default.isAvailable else {
            throw StepGenerationError.unavailable
        }

        // A fresh session per request: each rescue is independent, and carrying a
        // transcript would let one task's wording bleed into the next one's step.
        let session = LanguageModelSession(instructions: Self.instructions)

        let response = try await session.respond(
            to: Self.prompt(task: task, attempt: attempt),
            generating: StepReply.self,
            options: GenerationOptions(
                // Deterministic at attempt 0 so the same task gives the same step;
                // loosened on regeneration so "try a different step" actually differs.
                sampling: attempt == 0 ? .greedy : .random(top: 20),
                maximumResponseTokens: 60
            )
        )

        return response.content.step
    }

    static func prompt(task: String, attempt: Int) -> String {
        guard attempt > 0 else { return "The task they are avoiding: \(task)" }
        return """
            The task they are avoiding: \(task)

            They have already asked for a different step \(attempt) time(s). Give a step \
            that starts from a different object, place, or sense than the obvious one. \
            Still one small action.
            """
    }
}
#endif
