import Foundation

/// The five §9 states.
///
/// This state is **derived, never persisted**. It is always computable from the
/// task and session at render time; storing it would create a second source of
/// truth that can drift out of agreement with the data.
public enum EmberState: String, Sendable, CaseIterable {
    /// Dim and grey-warm. Nothing in flight.
    case resting
    /// A small warm glow. A task is named and a step is waiting.
    case ready
    /// Brighter, gently pulsing. A session is running.
    case focusing
    /// Flickering. The user said they got distracted.
    case distracted
    /// A soft warm bloom. No fireworks, no confetti, no numbers.
    case celebrating

    /// State is carried by glow, which a screen reader cannot see. Every state
    /// therefore has an explicit text equivalent, and none may ship without one.
    public var accessibilityLabel: String {
        switch self {
        case .resting: "Ember resting"
        case .ready: "Ember ready"
        case .focusing: "Ember glowing, session in progress"
        case .distracted: "Ember flickering"
        case .celebrating: "Ember blooming, you started"
        }
    }
}
