import Foundation
import KindlingCore
import UserNotifications

/// The §17 notification surface. Two rules govern everything here:
///
/// 1. **No notification ever contains the task's own title.** These render on a
///    public lock screen, and a task title can incidentally reveal health,
///    financial, or relationship information.
/// 2. Nothing is scheduled until the user has opted in from the §14 screen.
enum NotificationService {
    static let sessionEndIdentifier = "kindling.session.end"

    static func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound])
        } catch {
            return false
        }
    }

    static func isAuthorized() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
    }

    /// Fires only if the session ends while the app is not in front. Cancelled the
    /// moment the user comes back, so nobody is told about a timer they just watched.
    static func scheduleSessionEnd(at date: Date, durationSeconds: Int) async {
        guard await isAuthorized() else { return }

        let interval = date.timeIntervalSinceNow
        guard interval > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = SessionEndNotification.title
        // The copy is built in KindlingCore from a duration alone, so there is no
        // parameter here through which task text could reach the lock screen.
        content.body = SessionEndNotification.body(forDurationSeconds: durationSeconds)
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: sessionEndIdentifier,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        )
        try? await UNUserNotificationCenter.current().add(request)
    }

    static func cancelSessionEnd() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [sessionEndIdentifier])
    }
}
