import Foundation

/// The §11 status transitions, kept in one tested place rather than spread through
/// view code.
///
/// Note what is not here: there is no failure or abandoned state. A task that did
/// not go well is `steppedAway`, which is a resting place, not a verdict.
public enum TaskStateMachine {
    public static func canTransition(from current: TaskStatus, to next: TaskStatus) -> Bool {
        switch (current, next) {
        // A live task can be parked, finished, or thrown away.
        case (.active, .steppedAway), (.active, .done), (.active, .discarded):
            true
        // A parked task can always be picked back up — that is the whole resume promise.
        case (.steppedAway, .active), (.steppedAway, .done), (.steppedAway, .discarded):
            true
        // Finishing something is not a trap: it can be reopened.
        case (.done, .active):
            true
        // Discarding is the one deliberate end point.
        case (.discarded, _):
            false
        case (_, _) where current == next:
            false
        default:
            false
        }
    }

    /// Where a task lands after each of the three outcomes.
    ///
    /// All three are legitimate landings. "Keep going" leaves the task live for
    /// another session; the other two park it, ready to resume with nothing to
    /// re-enter. None of them marks the task done — only the user does that.
    public static func status(after outcome: SessionOutcome, from current: TaskStatus) -> TaskStatus {
        switch outcome {
        case .keptGoing: .active
        case .stoppedEnough, .distracted: .steppedAway
        }
    }
}

/// The free tier's one real boundary: one active task at a time.
///
/// Enforced here so it is unit-tested rather than scattered through views, and so
/// Phase 5's paywall has a single rule to ask. Nobody is ever blocked from getting
/// unstuck on the thing they came for — this only bites when expanding to a second
/// simultaneous task.
public enum ActiveTaskPolicy {
    public static let freeTierActiveLimit = 1

    public static func canStartAnotherTask(currentActiveCount: Int, hasMultiTaskEntitlement: Bool) -> Bool {
        hasMultiTaskEntitlement || currentActiveCount < freeTierActiveLimit
    }

    /// Convenience for call sites that hold a provider rather than a Bool.
    public static func canStartAnotherTask(
        currentActiveCount: Int,
        entitlements: any EntitlementProviding
    ) async -> Bool {
        if currentActiveCount < freeTierActiveLimit { return true }
        return await entitlements.isActive(.multiTask)
    }
}
