import Foundation

/// Time is injected rather than read inline via `Date()`.
///
/// This exists for the tests that matter most: a session that was interrupted by
/// backgrounding, a force-quit, a reboot, or a clock change. Those are unwritable
/// against a hard-coded `Date()`.
public struct SessionClock: Sendable {
    public var now: @Sendable () -> Date

    public init(now: @escaping @Sendable () -> Date) {
        self.now = now
    }

    public static let system = SessionClock { Date() }

    /// A clock parked at a fixed instant, for tests.
    public static func fixed(_ date: Date) -> SessionClock {
        SessionClock { date }
    }
}
