import Foundation

/// What the Live Activity renders. Deliberately a plain `Codable` value with no
/// ActivityKit import, for two reasons: the privacy rule below is then testable
/// without a simulator, and the ActivityKit conformance stays a thin wrapper.
///
/// **This type has nowhere to put the task's title, and that is the point.** The
/// Activity renders on a public lock screen, and a title can incidentally reveal
/// health, financial, or relationship information. There is no free-text field
/// carrying user content — only a fixed headline chosen from this file.
public struct LiveActivityPayload: Codable, Hashable, Sendable {
    /// The OS renders the countdown from this range itself. Nothing pushes
    /// per-second updates — that would exhaust the update budget and drain the
    /// battery for a number the system can already draw.
    public let window: ClosedRange<Date>

    /// Fixed copy. Never interpolated from anything the user typed.
    public let headline: String

    public init(window: ClosedRange<Date>, headline: String) {
        self.window = window
        self.headline = headline
    }
}

public enum LiveActivityContent {
    /// The only headline the Activity ever shows.
    public static let headline = "You're in a session"

    /// Built once at session start from the persisted start date, and never
    /// refreshed for a normal countdown.
    public static func payload(for session: SessionSnapshot) -> LiveActivityPayload {
        // A zero or negative duration would make an invalid range; clamp so this
        // can never trap on a bad stored value.
        let end = max(session.scheduledEnd, session.startedAt.addingTimeInterval(1))
        return LiveActivityPayload(window: session.startedAt...end, headline: headline)
    }
}
