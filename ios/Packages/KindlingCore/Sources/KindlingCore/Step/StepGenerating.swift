import Foundation

/// A source of step suggestions that is allowed to fail.
///
/// Generators throw; the *chain* decides what a failure means. Keeping fallback
/// out of the generators is what lets them compose — an engine that silently
/// substituted a template step could never be "tried next".
public protocol StepGenerating: Sendable {
    /// - Returns: one candidate step. Throwing is normal and expected.
    func generateStep(for task: String, attempt: Int) async throws -> String

    /// Cheap pre-check so the chain can skip a generator it knows can't run —
    /// an ineligible device, or a build with no endpoint configured.
    var isAvailable: Bool { get async }

    /// Recorded on the persisted step and in `AiRequestLog`.
    var provider: AiProvider { get }

    /// Optional hint that a request is likely soon. Default does nothing.
    func prewarm()
}

public extension StepGenerating {
    var isAvailable: Bool { get async { true } }
    func prewarm() {}
}

public enum StepGenerationError: Error {
    case unavailable
    case notConfigured
    case badResponse
    case emptyStep
    /// The model ignored the instructions — a paragraph where a sentence was asked
    /// for. Treated as a failure so the template answers instead.
    case implausibleStep
}
