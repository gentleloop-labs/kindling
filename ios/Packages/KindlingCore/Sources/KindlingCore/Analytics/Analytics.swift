import Foundation

/// The only analytics input accepted by the app. There is intentionally no
/// free-form event name or parameter API, so task and step text cannot be passed.
public enum AnalyticsEvent: Sendable, Equatable {
    case onboardingStarted
    case onboardingCompleted
    case taskEntered
    case firstStepDisplayed(origin: AnalyticsGenerationOrigin)
    case stepRegenerated(origin: AnalyticsGenerationOrigin)
    case sessionStarted(duration: AnalyticsDurationBucket)
    case sessionOutcome(SessionOutcome)
    case secondTaskAttempted
    case paywallDisplayed(source: AnalyticsPaywallSource)
    case upgradeCompleted(period: AnalyticsProductPeriod)
    case notificationPermission(AnalyticsPermissionOutcome)
    case notificationOpened

    public var name: String {
        switch self {
        case .onboardingStarted: "onboarding_started"
        case .onboardingCompleted: "onboarding_completed"
        case .taskEntered: "task_entered"
        case .firstStepDisplayed: "first_step_displayed"
        case .stepRegenerated: "step_regenerated"
        case .sessionStarted: "session_started"
        case .sessionOutcome: "session_outcome"
        case .secondTaskAttempted: "second_task_attempted"
        case .paywallDisplayed: "paywall_displayed"
        case .upgradeCompleted: "upgrade_completed"
        case .notificationPermission: "notification_permission"
        case .notificationOpened: "notification_opened"
        }
    }

    public var parameters: [String: String] {
        switch self {
        case .firstStepDisplayed(let origin), .stepRegenerated(let origin):
            ["generation_origin": origin.rawValue]
        case .sessionStarted(let duration):
            ["duration_bucket": duration.rawValue]
        case .sessionOutcome(let outcome):
            ["outcome": outcome.rawValue]
        case .paywallDisplayed(let source):
            ["paywall_source": source.rawValue]
        case .upgradeCompleted(let period):
            ["product_period": period.rawValue]
        case .notificationPermission(let outcome):
            ["outcome": outcome.rawValue]
        case .onboardingStarted, .onboardingCompleted, .taskEntered,
             .secondTaskAttempted, .notificationOpened:
            [:]
        }
    }
}

public enum AnalyticsGenerationOrigin: String, Sendable {
    case template
    case onDevice = "on_device"
    case hosted

    public init(stepOrigin: StepOrigin, provider: AiProvider) {
        if stepOrigin != .ai {
            self = .template
        } else {
            self = provider == .onDevice ? .onDevice : .hosted
        }
    }
}

public enum AnalyticsDurationBucket: String, Sendable {
    case twoMinutes = "2_minutes"
    case fiveMinutes = "5_minutes"

    public init(durationSeconds: Int) {
        self = durationSeconds == SessionDuration.fiveMinutes ? .fiveMinutes : .twoMinutes
    }
}

public enum AnalyticsPaywallSource: String, Sendable {
    case taskShelf = "task_shelf"
    case settings
    case home
    case postSession = "post_session"
}

public enum AnalyticsProductPeriod: String, Sendable {
    case monthly
    case annual
    case lifetime
}

public enum AnalyticsPermissionOutcome: String, Sendable {
    case allowed
    case declined
}

public protocol AnalyticsTracking: Sendable {
    func track(_ event: AnalyticsEvent)
}

public struct NoOpAnalyticsTracker: AnalyticsTracking {
    public init() {}
    public func track(_ event: AnalyticsEvent) {}
}
