import Foundation

/// Tries each generator in order and falls back to the template engine.
///
/// This is the §12 shape: **the template engine is the floor, always.** Generators
/// are layered on top in preference order — on-device first when the hardware
/// supports it, then a hosted call if the user opted in — and if every one of them
/// fails, is unavailable, or returns something implausible, the user still gets a
/// usable step. There is no path through this type that produces an error or an
/// empty string.
///
/// Validation lives here rather than in each generator so every source is held to
/// the same bar.
public struct StepEngineChain: AsyncStepSuggesting {
    /// A first step is one short sentence. Anything longer means the model ignored
    /// its instructions, so it is discarded in favour of the template.
    public static let maxStepCharacters = 160

    private let generators: [any StepGenerating]
    private let fallback: any StepSuggesting
    private let now: @Sendable () -> Date

    public init(
        generators: [any StepGenerating],
        fallback: any StepSuggesting = TemplateStepEngine(),
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.generators = generators
        self.fallback = fallback
        self.now = now
    }

    /// Called when the user reaches task entry, so a slow first model load happens
    /// while they type rather than while they wait.
    public func prewarm() {
        for generator in generators { generator.prewarm() }
    }

    public func suggestFirstStep(for task: String, attempt: Int) async -> StepSuggestion {
        let normalized = TemplateStepEngine.normalize(task)
        let templateText = fallback.suggestFirstStep(for: task, attempt: attempt)

        let startedAt = now()
        func elapsedMs() -> Int { max(0, Int(now().timeIntervalSince(startedAt) * 1000)) }

        // An empty task never reaches a generator: there is nothing to ask about,
        // and the template already carries the right guidance for it.
        guard !normalized.isEmpty, !generators.isEmpty else {
            return StepSuggestion(text: templateText, origin: .template, latencyMs: 0, attemptedRemote: false)
        }

        var attempted = false
        var lastProvider: AiProvider = .onDevice

        for generator in generators {
            guard await generator.isAvailable else { continue }
            attempted = true
            lastProvider = generator.provider
            do {
                let candidate = try await generator.generateStep(for: normalized, attempt: max(0, attempt))
                if let valid = Self.validate(candidate) {
                    return StepSuggestion(
                        text: valid,
                        origin: .ai,
                        latencyMs: elapsedMs(),
                        attemptedRemote: true,
                        provider: generator.provider
                    )
                }
                // Implausible output is a failure like any other — try the next
                // generator rather than showing the user a paragraph.
            } catch {
                continue
            }
        }

        return StepSuggestion(
            text: templateText,
            origin: .template,
            latencyMs: elapsedMs(),
            attemptedRemote: attempted,
            provider: lastProvider
        )
    }

    static func validate(_ candidate: String) -> String? {
        let trimmed = candidate.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.count <= maxStepCharacters else { return nil }
        return trimmed
    }
}
