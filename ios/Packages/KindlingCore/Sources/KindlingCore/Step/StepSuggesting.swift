import Foundation

/// The seam v1.1's AI layer slots into, as an opt-in decorator that falls back to
/// the template path on any failure.
///
/// The protocol is declared now and nothing is built behind it. **v1 ships no AI
/// at all** — the most vulnerable moment in the product is someone's first attempt
/// to start something, and it must never depend on a network call.
public protocol StepSuggesting: Sendable {
    /// - Parameter attempt: how many times the user has asked for a different step.
    ///   Regeneration is deterministic and cycles rather than randomising, so the
    ///   same task always offers the same steps in the same order.
    func suggestFirstStep(for task: String, attempt: Int) -> String
}

public extension StepSuggesting {
    func suggestFirstStep(for task: String) -> String {
        suggestFirstStep(for: task, attempt: 0)
    }
}
