import KindlingCore
import SwiftUI
import TelemetryDeck
import UIKit
import UserNotifications

struct TelemetryDeckAnalyticsTracker: AnalyticsTracking {
    func track(_ event: AnalyticsEvent) {
        TelemetryDeck.signal(event.name, parameters: event.parameters)
    }
}

enum AnalyticsBootstrap {
    static func make() -> any AnalyticsTracking {
        guard let appID = Bundle.main.object(forInfoDictionaryKey: "KindlingTelemetryDeckAppID") as? String,
              !appID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return NoOpAnalyticsTracker()
        }

        let config = TelemetryDeck.Config(appID: appID)
        #if DEBUG
        config.testMode = true
        #endif
        // Do not set defaultUser. The SDK uses its installation-scoped identifier.
        TelemetryDeck.initialize(config: config)
        return TelemetryDeckAnalyticsTracker()
    }
}

private struct AnalyticsTrackerKey: EnvironmentKey {
    static let defaultValue: any AnalyticsTracking = NoOpAnalyticsTracker()
}

extension EnvironmentValues {
    var analyticsTracker: any AnalyticsTracking {
        get { self[AnalyticsTrackerKey.self] }
        set { self[AnalyticsTrackerKey.self] = newValue }
    }
}

/// The notification delegate is outside SwiftUI's environment, so it reaches the
/// same fixed tracker through this tiny content-free bridge.
final class AnalyticsRuntime: @unchecked Sendable {
    static let shared = AnalyticsRuntime()
    private let lock = NSLock()
    private var tracker: any AnalyticsTracking = NoOpAnalyticsTracker()

    func configure(_ tracker: any AnalyticsTracking) {
        lock.lock()
        self.tracker = tracker
        lock.unlock()
    }

    func track(_ event: AnalyticsEvent) {
        lock.lock()
        let tracker = tracker
        lock.unlock()
        tracker.track(event)
    }
}

final class KindlingAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

}

extension KindlingAppDelegate: @preconcurrency UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        AnalyticsRuntime.shared.track(.notificationOpened)
        completionHandler()
    }
}
