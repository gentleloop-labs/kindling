import Foundation

/// Keeps proactive upgrade invitations tied to demonstrated value and spaced
/// far enough apart that Kindling never feels like another source of pressure.
public enum PlusNudgePolicy {
    public static let minimumValueMoments = 2
    public static let cooldown: TimeInterval = 14 * 24 * 60 * 60

    public static func countsAsValueMoment(_ outcome: SessionOutcome) -> Bool {
        switch outcome {
        case .keptGoing, .stoppedEnough:
            true
        case .distracted:
            false
        }
    }

    public static func shouldShow(
        after outcome: SessionOutcome?,
        hasPlus: Bool,
        valueMomentCount: Int,
        lastShownAt: Date?,
        now: Date
    ) -> Bool {
        guard !hasPlus,
              let outcome,
              countsAsValueMoment(outcome),
              valueMomentCount >= minimumValueMoments
        else { return false }

        guard let lastShownAt else { return true }
        return now.timeIntervalSince(lastShownAt) >= cooldown
    }
}
