import ActivityKit
import Foundation
import KindlingCore

/// Starts and ends the session Live Activity.
///
/// The content state is computed once at session start and never refreshed for a
/// normal countdown — the OS renders the remaining time from the date range itself.
/// Because Phase 2 persists `startedAt`, that range survives the app being closed.
@MainActor
enum LiveActivityController {
    private static var current: Activity<KindlingSessionAttributes>?

    static var isSupported: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    static func start(for session: SessionSnapshot) {
        guard isSupported else { return }

        // The system is the source of truth here, not the in-process handle.
        // After a force-quit and relaunch, `current` is nil while the Activity the
        // previous process started is still alive — guarding on `current` alone
        // stacks a second Activity onto the first on every relaunch.
        if let existing = Activity<KindlingSessionAttributes>.activities.first {
            current = existing
            return
        }

        let attributes = KindlingSessionAttributes(durationSeconds: session.durationSeconds)
        let state = ActivityContent(state: LiveActivityContent.payload(for: session), staleDate: nil)

        current = try? Activity.request(attributes: attributes, content: state, pushType: nil)
    }

    static func end() async {
        // Reconcile against the system rather than trusting the in-process handle:
        // the app may have been relaunched since the Activity started, or the user
        // may have dismissed it.
        for activity in Activity<KindlingSessionAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        current = nil
    }

    /// Called on foreground. If a session is no longer running but an Activity is
    /// still alive — force-quit, or the session ended while away — clear it.
    static func reconcile(hasRunningSession: Bool) async {
        let live = Activity<KindlingSessionAttributes>.activities
        if !hasRunningSession, !live.isEmpty {
            await end()
        }
        if hasRunningSession, live.isEmpty {
            // The user dismissed it mid-session. Do not silently re-create it —
            // dismissing is a choice, and re-adding it would override that choice.
            current = nil
        } else {
            current = live.first
        }
    }
}
