import Foundation
import SwiftData

/// Keys for the §11 key/value preference table. Adding a setting never needs a
/// schema change, which is the whole reason that table is shaped this way.
public enum PreferenceKey {
    public static let haptics = "haptics"
    public static let notificationsOptIn = "notifications_opt_in"
    public static let excludeFromBackup = "exclude_from_backup"
    /// §6: the last timer choice is remembered so the user re-decides nothing.
    public static let lastDurationSeconds = "last_duration_seconds"
    /// §12: AI-assisted steps are opt-in and default to off. Turning this on is
    /// the moment task text starts leaving the device.
    public static let aiStepsEnabled = "ai_steps_enabled"
    /// Versioned because a future processor or retention change requires a new
    /// affirmative choice rather than silently reusing an old one.
    public static let hostedAIConsentV1 = "hosted_ai_consent_v1"
}

public enum HostedAIConsent: String, Sendable {
    case notAsked = "not_asked"
    case allowed
    case declined
}

/// Thin typed wrapper over `UserPreference`. Lives in `KindlingCore` so defaults are
/// declared once and testable, rather than re-guessed at each call site.
@MainActor
public struct PreferencesStore {
    private let context: ModelContext

    public init(context: ModelContext) {
        self.context = context
    }

    public func bool(_ key: String, default defaultValue: Bool) -> Bool {
        guard let raw = value(key) else { return defaultValue }
        return raw == "true"
    }

    public func int(_ key: String, default defaultValue: Int) -> Int {
        guard let raw = value(key), let parsed = Int(raw) else { return defaultValue }
        return parsed
    }

    public func hostedAIConsent() -> HostedAIConsent {
        value(PreferenceKey.hostedAIConsentV1).flatMap(HostedAIConsent.init(rawValue:)) ?? .notAsked
    }

    public func setHostedAIConsent(_ consent: HostedAIConsent) {
        set(PreferenceKey.hostedAIConsentV1, consent.rawValue)
    }

    public func set(_ key: String, _ newValue: Bool) {
        set(key, newValue ? "true" : "false")
    }

    public func set(_ key: String, _ newValue: Int) {
        set(key, String(newValue))
    }

    public func set(_ key: String, _ newValue: String) {
        if let existing = row(key) {
            existing.value = newValue
        } else {
            context.insert(UserPreference(key: key, value: newValue))
        }
        try? context.save()
    }

    private func value(_ key: String) -> String? {
        row(key)?.value
    }

    private func row(_ key: String) -> UserPreference? {
        var descriptor = FetchDescriptor<UserPreference>(predicate: #Predicate { $0.key == key })
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }
}

/// The two offered session lengths. §18 lists the default as a thing to A/B test
/// later; the values themselves are fixed for v1.
public enum SessionDuration {
    public static let twoMinutes = 120
    public static let fiveMinutes = 300
    public static let allowed = [twoMinutes, fiveMinutes]
    public static let `default` = twoMinutes
}
