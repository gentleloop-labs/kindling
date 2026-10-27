import Foundation

public enum TripLimitPolicy {
    public static let freeSavedTripLimit = 2

    public static func canSaveTrip(completedTripCount: Int, hasPro: Bool) -> Bool {
        hasPro || completedTripCount < freeSavedTripLimit
    }
}

public enum ReviewPromptPolicy {
    /// Asks at most once per app version, and only after a real (non-sample) trail is saved.
    /// StoreKit applies its own yearly cap on top of this.
    public static func shouldRequestReview(
        savedTripCount: Int,
        lastPromptedVersion: String?,
        currentVersion: String
    ) -> Bool {
        savedTripCount >= 1 && lastPromptedVersion != currentVersion
    }
}

public struct ResurfacingCandidate: Sendable, Equatable {
    public let momentID: UUID
    public let tripID: UUID
    public let capturedAt: Date?
    public let lastPresentedAt: Date?
    public let isTripArchived: Bool
    public let isHidden: Bool
    public let isSensitive: Bool
    public let doNotResurface: Bool

    public init(
        momentID: UUID,
        tripID: UUID,
        capturedAt: Date?,
        lastPresentedAt: Date?,
        isTripArchived: Bool,
        isHidden: Bool,
        isSensitive: Bool,
        doNotResurface: Bool
    ) {
        self.momentID = momentID
        self.tripID = tripID
        self.capturedAt = capturedAt
        self.lastPresentedAt = lastPresentedAt
        self.isTripArchived = isTripArchived
        self.isHidden = isHidden
        self.isSensitive = isSensitive
        self.doNotResurface = doNotResurface
    }
}

public struct ResurfacingPolicy: Sendable {
    public let minimumAge: TimeInterval
    public let repeatInterval: TimeInterval

    public init(
        minimumAge: TimeInterval = 30 * 24 * 60 * 60,
        repeatInterval: TimeInterval = 90 * 24 * 60 * 60
    ) {
        self.minimumAge = minimumAge
        self.repeatInterval = repeatInterval
    }

    public func eligible(_ candidate: ResurfacingCandidate, now: Date) -> Bool {
        guard !candidate.isTripArchived,
              !candidate.isHidden,
              !candidate.isSensitive,
              !candidate.doNotResurface
        else { return false }
        if let capturedAt = candidate.capturedAt,
           now.timeIntervalSince(capturedAt) < minimumAge {
            return false
        }
        if let lastPresentedAt = candidate.lastPresentedAt,
           now.timeIntervalSince(lastPresentedAt) < repeatInterval {
            return false
        }
        return true
    }

    public func choose(from candidates: [ResurfacingCandidate], now: Date) -> ResurfacingCandidate? {
        candidates
            .filter { eligible($0, now: now) }
            .sorted { lhs, rhs in
                switch (lhs.lastPresentedAt, rhs.lastPresentedAt) {
                case (nil, nil): return lhs.momentID.uuidString < rhs.momentID.uuidString
                case (nil, _): return true
                case (_, nil): return false
                case let (left?, right?): return left < right
                }
            }
            .first
    }
}

public struct ArtifactPrivacySelection: Sendable, Equatable {
    public var includesTitle: Bool
    public var includesDates: Bool
    public var includesPlaces: Bool
    public var includesNotes: Bool
    public var includesSensitiveMoments: Bool

    public static let shareable = ArtifactPrivacySelection(
        includesTitle: true,
        includesDates: true,
        includesPlaces: false,
        includesNotes: false,
        includesSensitiveMoments: false
    )

    public init(
        includesTitle: Bool,
        includesDates: Bool,
        includesPlaces: Bool,
        includesNotes: Bool,
        includesSensitiveMoments: Bool
    ) {
        self.includesTitle = includesTitle
        self.includesDates = includesDates
        self.includesPlaces = includesPlaces
        self.includesNotes = includesNotes
        self.includesSensitiveMoments = includesSensitiveMoments
    }
}

public enum MemorySearchNormalizer {
    public static func normalize(_ text: String) -> String {
        text.folding(
            options: [.caseInsensitive, .diacriticInsensitive],
            locale: .current
        ).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
