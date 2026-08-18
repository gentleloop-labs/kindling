import Foundation

/// A running session, reduced to the only three facts needed to render it.
public struct SessionSnapshot: Sendable, Equatable {
    public let durationSeconds: Int
    public let startedAt: Date
    public let endedAt: Date?

    public init(durationSeconds: Int, startedAt: Date, endedAt: Date? = nil) {
        self.durationSeconds = durationSeconds
        self.startedAt = startedAt
        self.endedAt = endedAt
    }

    public var scheduledEnd: Date {
        startedAt.addingTimeInterval(TimeInterval(durationSeconds))
    }
}

/// What the UI should be showing right now.
public enum SessionPhase: Sendable, Equatable {
    /// Still counting down, with this much left.
    case running(remaining: TimeInterval)
    /// The timer reached its end — possibly while the app was closed.
    case elapsed
    /// The user stopped it early.
    case stoppedEarly
}

/// Derives session state from wall-clock time against the persisted start.
///
/// **Nothing here counts down in memory.** Remaining time is always recomputed
/// from `startedAt`, which is what lets a session survive backgrounding, a
/// force-quit, or a reboot, and what lets the Live Activity in Phase 4 be a pure
/// render of a date range rather than something that needs feeding per second.
public enum SessionRuntime {
    public static func phase(of session: SessionSnapshot, clock: SessionClock) -> SessionPhase {
        if let endedAt = session.endedAt {
            // Ended before its scheduled end means the user stopped it.
            return endedAt < session.scheduledEnd ? .stoppedEarly : .elapsed
        }

        let now = clock.now()
        let remaining = session.scheduledEnd.timeIntervalSince(now)
        guard remaining > 0 else { return .elapsed }

        // A clock moved backwards must never show more time than the session was
        // ever set for. Without this, changing the device clock hands out free time.
        return .running(remaining: min(remaining, TimeInterval(session.durationSeconds)))
    }

    public static func remaining(of session: SessionSnapshot, clock: SessionClock) -> TimeInterval {
        if case .running(let remaining) = phase(of: session, clock: clock) { return remaining }
        return 0
    }

    /// 0 through 1, for the timer ring. Clamped at both ends so a clock change
    /// cannot drive the ring past full or below empty.
    public static func progress(of session: SessionSnapshot, clock: SessionClock) -> Double {
        guard session.durationSeconds > 0 else { return 1 }
        let left = remaining(of: session, clock: clock)
        return min(1, max(0, 1 - left / TimeInterval(session.durationSeconds)))
    }

    /// True when a session that was left running has already finished — the case
    /// that fires on relaunch after a force-quit or a reboot.
    public static func endedWhileAway(_ session: SessionSnapshot, clock: SessionClock) -> Bool {
        session.endedAt == nil && phase(of: session, clock: clock) == .elapsed
    }
}
