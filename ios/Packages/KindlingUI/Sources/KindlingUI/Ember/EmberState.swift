import Foundation

public enum EmberState: String, Sendable, CaseIterable {
    case resting
    case welcoming
    case gathering
    case arranging
    case remembering
    case celebrating

    /// State is carried by glow, which a screen reader cannot see. Every state
    /// therefore has an explicit text equivalent, and none may ship without one.
    public var accessibilityLabel: String {
        switch self {
        case .resting: "Ember resting"
        case .welcoming: "Ember welcoming you"
        case .gathering: "Ember gathering memories"
        case .arranging: "Ember arranging a memory trail"
        case .remembering: "Ember remembering with you"
        case .celebrating: "Ember glowing, your memory is ready"
        }
    }
}
