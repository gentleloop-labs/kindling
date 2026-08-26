import Foundation

/// Copy for the §17 session-end nudge.
///
/// Lives in `KindlingCore` rather than beside `UNUserNotificationCenter` for the
/// same reason `LiveActivityPayload` does: this text renders on a **public lock
/// screen**, so the rule that it never contains the task title needs a test, and a
/// test needs it out of the app target.
///
/// The function takes a duration and nothing else. There is no parameter through
/// which a task or a step could be passed, which is what makes the guarantee
/// structural rather than a matter of remembering.
public enum SessionEndNotification {
    public static let title = "Kindling"

    public static func body(forDurationSeconds seconds: Int) -> String {
        let minutes = max(1, seconds / 60)
        // Both choices are named as wins, deliberately: the notification must not
        // imply that stopping was the wrong answer.
        return "Your \(minutes) minutes are up. Keep going, or that's enough for today. Both are wins."
    }
}
