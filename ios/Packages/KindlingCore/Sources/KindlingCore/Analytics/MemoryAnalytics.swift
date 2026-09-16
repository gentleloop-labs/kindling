import Foundation

public enum AnalyticsCountBucket: String, Sendable {
    case oneToFive = "1_5"
    case sixToTwenty = "6_20"
    case twentyOneToFifty = "21_50"
    case fiftyOneToOneHundred = "51_100"
    case oneHundredOneToFiveHundred = "101_500"
    case overFiveHundred = "over_500"

    public init(_ count: Int) {
        switch count {
        case ...5: self = .oneToFive
        case ...20: self = .sixToTwenty
        case ...50: self = .twentyOneToFifty
        case ...100: self = .fiftyOneToOneHundred
        case ...500: self = .oneHundredOneToFiveHundred
        default: self = .overFiveHundred
        }
    }
}

public enum AnalyticsDurationBucket: String, Sendable {
    case underThreeSeconds = "under_3s"
    case threeToTenSeconds = "3_10s"
    case elevenToThirtySeconds = "11_30s"
    case overThirtySeconds = "over_30s"

    public init(seconds: TimeInterval) {
        switch seconds {
        case ..<3: self = .underThreeSeconds
        case ...10: self = .threeToTenSeconds
        case ...30: self = .elevenToThirtySeconds
        default: self = .overThirtySeconds
        }
    }
}

public enum AnalyticsPaywallSource: String, Sendable {
    case thirdTrip = "third_trip"
    case settings
    case premiumTheme = "premium_theme"
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

public enum AnalyticsEvent: Sendable, Equatable {
    case appOpened
    case onboardingStarted
    case onboardingCompleted
    case sampleTripOpened
    case photoPickerOpened
    case photoSelectionCompleted(count: AnalyticsCountBucket)
    case importStarted(count: AnalyticsCountBucket)
    case importCompleted(duration: AnalyticsDurationBucket, count: AnalyticsCountBucket)
    case importFailed(code: AnalyticsImportError)
    case draftReviewOpened
    case draftSaved
    case memoryTrailViewed
    case sparkPresented(family: SparkFamily)
    case sparkAnswered(family: SparkFamily)
    case sparkSkipped(family: SparkFamily)
    case voiceNoteCreated(duration: AnalyticsVoiceDurationBucket)
    case recapPreviewed(type: AnalyticsArtifactType)
    case recapExported(type: AnalyticsArtifactType, theme: AnalyticsTheme, privacy: AnalyticsPrivacyPreset)
    case shareSheetOpened
    case resurfacingEnabled
    case postcardPresented
    case postcardOpened
    case searchPerformed(results: AnalyticsResultBucket)
    case thirdTripSaveAttempted
    case paywallDisplayed(source: AnalyticsPaywallSource)
    case purchaseStarted(period: AnalyticsProductPeriod)
    case purchaseCompleted(period: AnalyticsProductPeriod)
    case purchaseCancelled(period: AnalyticsProductPeriod)
    case purchaseFailed(period: AnalyticsProductPeriod)
    case restoreStarted
    case restoreCompleted
    case notificationPermission(AnalyticsPermissionOutcome)
    case notificationOpened
    case tripDeleted
    case allDataDeleted

    public var name: String {
        switch self {
        case .appOpened: "app_opened"
        case .onboardingStarted: "onboarding_started"
        case .onboardingCompleted: "onboarding_completed"
        case .sampleTripOpened: "sample_trip_opened"
        case .photoPickerOpened: "photo_picker_opened"
        case .photoSelectionCompleted: "photo_selection_completed"
        case .importStarted: "import_started"
        case .importCompleted: "import_completed"
        case .importFailed: "import_failed"
        case .draftReviewOpened: "draft_review_opened"
        case .draftSaved: "draft_saved"
        case .memoryTrailViewed: "memory_trail_viewed"
        case .sparkPresented: "spark_presented"
        case .sparkAnswered: "spark_answered"
        case .sparkSkipped: "spark_skipped"
        case .voiceNoteCreated: "voice_note_created"
        case .recapPreviewed: "recap_previewed"
        case .recapExported: "recap_exported"
        case .shareSheetOpened: "share_sheet_opened"
        case .resurfacingEnabled: "resurfacing_enabled"
        case .postcardPresented: "postcard_presented"
        case .postcardOpened: "postcard_opened"
        case .searchPerformed: "search_performed"
        case .thirdTripSaveAttempted: "third_trip_save_attempted"
        case .paywallDisplayed: "paywall_displayed"
        case .purchaseStarted: "purchase_started"
        case .purchaseCompleted: "purchase_completed"
        case .purchaseCancelled: "purchase_cancelled"
        case .purchaseFailed: "purchase_failed"
        case .restoreStarted: "restore_started"
        case .restoreCompleted: "restore_completed"
        case .notificationPermission: "notification_permission"
        case .notificationOpened: "notification_opened"
        case .tripDeleted: "trip_deleted"
        case .allDataDeleted: "all_data_deleted"
        }
    }

    public var parameters: [String: String] {
        switch self {
        case .photoSelectionCompleted(let count), .importStarted(let count):
            ["count_bucket": count.rawValue]
        case .importCompleted(let duration, let count):
            ["duration_bucket": duration.rawValue, "count_bucket": count.rawValue]
        case .importFailed(let code):
            ["error_code": code.rawValue]
        case .sparkPresented(let family), .sparkAnswered(let family), .sparkSkipped(let family):
            ["prompt_family": family.rawValue]
        case .voiceNoteCreated(let duration):
            ["duration_bucket": duration.rawValue]
        case .recapPreviewed(let type):
            ["artifact_type": type.rawValue]
        case .recapExported(let type, let theme, let privacy):
            ["artifact_type": type.rawValue, "theme": theme.rawValue, "privacy": privacy.rawValue]
        case .searchPerformed(let results):
            ["result_count_bucket": results.rawValue]
        case .paywallDisplayed(let source):
            ["paywall_source": source.rawValue]
        case .purchaseStarted(let period), .purchaseCompleted(let period),
             .purchaseCancelled(let period), .purchaseFailed(let period):
            ["product_period": period.rawValue]
        case .notificationPermission(let outcome):
            ["outcome": outcome.rawValue]
        default:
            [:]
        }
    }
}

public enum AnalyticsImportError: String, Sendable {
    case unavailable, loadFailed = "load_failed", processingFailed = "processing_failed"
    case storageFull = "storage_full", cancelled, unknown
}

public enum AnalyticsVoiceDurationBucket: String, Sendable {
    case underThirtySeconds = "under_30s", thirtyToSixtySeconds = "30_60s", overSixtySeconds = "over_60s"
    public init(seconds: Double) {
        if seconds < 30 { self = .underThirtySeconds }
        else if seconds <= 60 { self = .thirtyToSixtySeconds }
        else { self = .overSixtySeconds }
    }
}

public enum AnalyticsArtifactType: String, Sendable { case postcard, mapCard = "map_card" }
public enum AnalyticsTheme: String, Sendable { case standard, dusk, ocean, ember }
public enum AnalyticsPrivacyPreset: String, Sendable { case shareable, custom }
public enum AnalyticsResultBucket: String, Sendable {
    case zero, oneToFive = "1_5", sixToTwenty = "6_20", overTwenty = "over_20"
    public init(_ count: Int) {
        if count == 0 { self = .zero }
        else if count <= 5 { self = .oneToFive }
        else if count <= 20 { self = .sixToTwenty }
        else { self = .overTwenty }
    }
}

public protocol AnalyticsTracking: Sendable { func track(_ event: AnalyticsEvent) }
public struct NoOpAnalyticsTracker: AnalyticsTracking {
    public init() {}
    public func track(_ event: AnalyticsEvent) {}
}
