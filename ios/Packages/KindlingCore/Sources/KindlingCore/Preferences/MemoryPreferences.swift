import Foundation
import SwiftData

public enum PreferenceKey {
    public static let onboardingCompleted = "onboarding_completed"
    public static let notificationsOptIn = "notifications_opt_in"
    public static let quietHoursStart = "quiet_hours_start"
    public static let quietHoursEnd = "quiet_hours_end"
    public static let resurfacingCadence = "resurfacing_cadence"
    public static let includePhotosInPostcards = "include_photos_in_postcards"
    public static let legacyDataDecision = "legacy_data_decision"
}

@MainActor
public struct PreferencesStore {
    private let context: ModelContext

    public init(context: ModelContext) { self.context = context }

    public func value(_ key: String) -> String? {
        let descriptor = FetchDescriptor<UserPreference>(predicate: #Predicate { $0.key == key })
        return try? context.fetch(descriptor).first?.value
    }

    public func bool(_ key: String, default fallback: Bool) -> Bool {
        guard let value = value(key) else { return fallback }
        return value == "true"
    }

    public func set(_ key: String, _ value: String) {
        let descriptor = FetchDescriptor<UserPreference>(predicate: #Predicate { $0.key == key })
        if let existing = try? context.fetch(descriptor).first { existing.value = value }
        else { context.insert(UserPreference(key: key, value: value)) }
        try? context.save()
    }

    public func set(_ key: String, _ value: Bool) { set(key, value ? "true" : "false") }
}
