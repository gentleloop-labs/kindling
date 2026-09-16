import Foundation
import UserNotifications

enum MemoryNotificationService {
    static let identifier = "kindling.memory.postcard"

    static func requestAuthorization() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])) ?? false
    }

    static func scheduleNextPostcard(hour: Int = 18, minute: Int = 0) async throws {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        let content = UNMutableNotificationContent()
        content.title = "A postcard from your past is ready"
        content.body = "Open Kindling when you feel like revisiting a memory."
        content.sound = .default
        content.userInfo = ["kindling_destination": "postcard"]
        var components = DateComponents()
        components.hour = max(0, min(23, hour))
        components.minute = max(0, min(59, minute))
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        try await center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
    }

    static func cancelPostcards() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}
