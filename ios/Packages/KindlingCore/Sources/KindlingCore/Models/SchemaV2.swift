import Foundation
import SwiftData

public enum MemoryTripStatus: String, Codable, Sendable, CaseIterable {
    case draft
    case complete
    case archived
}

public enum MemoryTripSource: String, Codable, Sendable {
    case manualSelection = "manual_selection"
    case sample
    case automaticDiscovery = "automatic_discovery"
}

public enum MemoryMediaType: String, Codable, Sendable {
    case image
    case livePhoto = "live_photo"
    case video
}

public enum MediaAvailability: String, Codable, Sendable {
    case available
    case downloading
    case missing
    case denied
}

public enum MemoryPlaceSource: String, Codable, Sendable {
    case metadata
    case geocoder
    case user
}

public enum ReturnIntent: String, Codable, Sendable, CaseIterable {
    case yes
    case maybe
    case no

    public var label: String {
        switch self {
        case .yes: "Would return"
        case .maybe: "Maybe return"
        case .no: "Once was enough"
        }
    }
}

public enum PromptResponseState: String, Codable, Sendable {
    case answered
    case skipped
    case dismissed
}

public enum MemoryImportState: String, Codable, Sendable {
    case reading
    case clustering
    case resolvingPlaces = "resolving_places"
    case reviewing
    case saved
    case cancelled
    case failed
}

public enum MemoryArtifactType: String, Codable, Sendable {
    case postcard
    case mapCard = "map_card"
    case verticalVideo = "vertical_video"
    case summary
}

public enum ArtifactPrivacyPreset: String, Codable, Sendable {
    case privateCopy = "private"
    case shareable
    case custom
}

public enum ResurfacingSource: String, Codable, Sendable {
    case inApp = "in_app"
    case notification
}

/// The memory product starts in a separate store. The retired schema is not part
/// of this migration graph: previous-version data stays intact in the App Group
/// until the person explicitly deletes it from Settings.
public enum SchemaV2: VersionedSchema {
    public static var versionIdentifier: Schema.Version { Schema.Version(2, 0, 0) }

    public static var models: [any PersistentModel.Type] {
        [
            MemoryTrip.self,
            MemoryMoment.self,
            MediaReference.self,
            PromptResponse.self,
            VoiceNote.self,
            ImportBatch.self,
            GeneratedArtifact.self,
            ResurfacingRecord.self,
            PrivateTag.self,
            UserPreference.self
        ]
    }

    @Model
    public final class MemoryTrip {
        public var id: UUID = UUID()
        public var title: String = ""
        public var statusRaw: String = MemoryTripStatus.draft.rawValue
        public var sourceRaw: String = MemoryTripSource.manualSelection.rawValue
        public var startDate: Date?
        public var endDate: Date?
        public var coverMediaReferenceID: UUID?
        public var summaryPlaceText: String?
        public var isFavorite: Bool = false
        public var isSensitive: Bool = false
        public var createdAt: Date = Date()
        public var updatedAt: Date = Date()

        @Relationship(deleteRule: .cascade, inverse: \MemoryMoment.trip)
        public var moments: [MemoryMoment] = []

        @Relationship(deleteRule: .cascade, inverse: \GeneratedArtifact.trip)
        public var artifacts: [GeneratedArtifact] = []

        public var status: MemoryTripStatus {
            get { MemoryTripStatus(rawValue: statusRaw) ?? .draft }
            set { statusRaw = newValue.rawValue }
        }

        public var source: MemoryTripSource {
            get { MemoryTripSource(rawValue: sourceRaw) ?? .manualSelection }
            set { sourceRaw = newValue.rawValue }
        }

        public var orderedMoments: [MemoryMoment] {
            moments.sorted { lhs, rhs in
                if lhs.sortIndex != rhs.sortIndex { return lhs.sortIndex < rhs.sortIndex }
                return lhs.id.uuidString < rhs.id.uuidString
            }
        }

        public init(
            id: UUID = UUID(),
            title: String,
            status: MemoryTripStatus = .draft,
            source: MemoryTripSource = .manualSelection,
            startDate: Date? = nil,
            endDate: Date? = nil,
            createdAt: Date = Date()
        ) {
            self.id = id
            self.title = title
            self.statusRaw = status.rawValue
            self.sourceRaw = source.rawValue
            self.startDate = startDate
            self.endDate = endDate
            self.createdAt = createdAt
            self.updatedAt = createdAt
        }
    }

    @Model
    public final class MemoryMoment {
        public var id: UUID = UUID()
        public var title: String?
        public var capturedAt: Date?
        public var endCapturedAt: Date?
        public var latitude: Double?
        public var longitude: Double?
        public var placeName: String?
        public var locality: String?
        public var administrativeArea: String?
        public var countryCode: String?
        public var placeSourceRaw: String = MemoryPlaceSource.metadata.rawValue
        public var placeConfidence: Double?
        public var noteText: String?
        public var returnIntentRaw: String?
        public var isHidden: Bool = false
        public var isSensitive: Bool = false
        public var doNotResurface: Bool = false
        public var sortIndex: Int = 0
        public var createdAt: Date = Date()
        public var updatedAt: Date = Date()
        public var trip: MemoryTrip?

        @Relationship(deleteRule: .cascade, inverse: \MediaReference.moment)
        public var mediaReferences: [MediaReference] = []

        @Relationship(deleteRule: .cascade, inverse: \PromptResponse.moment)
        public var promptResponses: [PromptResponse] = []

        @Relationship(deleteRule: .cascade, inverse: \VoiceNote.moment)
        public var voiceNotes: [VoiceNote] = []

        @Relationship(inverse: \PrivateTag.moments)
        public var tags: [PrivateTag] = []

        public var placeSource: MemoryPlaceSource {
            get { MemoryPlaceSource(rawValue: placeSourceRaw) ?? .metadata }
            set { placeSourceRaw = newValue.rawValue }
        }

        public var returnIntent: ReturnIntent? {
            get { returnIntentRaw.flatMap(ReturnIntent.init(rawValue:)) }
            set { returnIntentRaw = newValue?.rawValue }
        }

        public var orderedMedia: [MediaReference] {
            mediaReferences.sorted { lhs, rhs in
                if lhs.sortIndex != rhs.sortIndex { return lhs.sortIndex < rhs.sortIndex }
                return lhs.id.uuidString < rhs.id.uuidString
            }
        }

        public var displayPlace: String? {
            placeName ?? locality ?? administrativeArea
        }

        public init(
            id: UUID = UUID(),
            title: String? = nil,
            capturedAt: Date? = nil,
            endCapturedAt: Date? = nil,
            latitude: Double? = nil,
            longitude: Double? = nil,
            placeName: String? = nil,
            sortIndex: Int,
            createdAt: Date = Date()
        ) {
            self.id = id
            self.title = title
            self.capturedAt = capturedAt
            self.endCapturedAt = endCapturedAt
            self.latitude = latitude
            self.longitude = longitude
            self.placeName = placeName
            self.sortIndex = sortIndex
            self.createdAt = createdAt
            self.updatedAt = createdAt
        }
    }

    @Model
    public final class MediaReference {
        public var id: UUID = UUID()
        public var localIdentifier: String?
        /// An app-owned image in the asset catalog. Used only by the bundled
        /// reviewer sample; imported memories always use durable local files.
        public var bundledAssetName: String?
        public var importedFileRelativePath: String?
        public var posterFileRelativePath: String?
        public var mediaTypeRaw: String = MemoryMediaType.image.rawValue
        public var creationDate: Date?
        public var latitude: Double?
        public var longitude: Double?
        public var pixelWidth: Int?
        public var pixelHeight: Int?
        public var durationSeconds: Double?
        public var sortIndex: Int = 0
        public var thumbnailCacheKey: String?
        public var availabilityRaw: String = MediaAvailability.available.rawValue
        public var metadataFingerprint: String?
        public var createdAt: Date = Date()
        public var moment: MemoryMoment?

        public var mediaType: MemoryMediaType {
            get { MemoryMediaType(rawValue: mediaTypeRaw) ?? .image }
            set { mediaTypeRaw = newValue.rawValue }
        }

        public var availability: MediaAvailability {
            get { MediaAvailability(rawValue: availabilityRaw) ?? .missing }
            set { availabilityRaw = newValue.rawValue }
        }

        public init(
            id: UUID = UUID(),
            localIdentifier: String? = nil,
            bundledAssetName: String? = nil,
            importedFileRelativePath: String? = nil,
            posterFileRelativePath: String? = nil,
            mediaType: MemoryMediaType,
            creationDate: Date? = nil,
            latitude: Double? = nil,
            longitude: Double? = nil,
            pixelWidth: Int? = nil,
            pixelHeight: Int? = nil,
            durationSeconds: Double? = nil,
            sortIndex: Int,
            metadataFingerprint: String? = nil,
            createdAt: Date = Date()
        ) {
            self.id = id
            self.localIdentifier = localIdentifier
            self.bundledAssetName = bundledAssetName
            self.importedFileRelativePath = importedFileRelativePath
            self.posterFileRelativePath = posterFileRelativePath
            self.mediaTypeRaw = mediaType.rawValue
            self.creationDate = creationDate
            self.latitude = latitude
            self.longitude = longitude
            self.pixelWidth = pixelWidth
            self.pixelHeight = pixelHeight
            self.durationSeconds = durationSeconds
            self.sortIndex = sortIndex
            self.metadataFingerprint = metadataFingerprint
            self.createdAt = createdAt
        }
    }

    @Model
    public final class PromptResponse {
        public var id: UUID = UUID()
        public var promptKey: String = ""
        public var promptVersion: Int = 1
        public var promptTextSnapshot: String = ""
        public var responseText: String?
        public var responseChoiceRaw: String?
        public var stateRaw: String = PromptResponseState.dismissed.rawValue
        public var createdAt: Date = Date()
        public var updatedAt: Date = Date()
        public var moment: MemoryMoment?

        public var state: PromptResponseState {
            get { PromptResponseState(rawValue: stateRaw) ?? .dismissed }
            set { stateRaw = newValue.rawValue }
        }

        public init(
            id: UUID = UUID(),
            promptKey: String,
            promptVersion: Int = 1,
            promptTextSnapshot: String,
            responseText: String? = nil,
            state: PromptResponseState,
            createdAt: Date = Date()
        ) {
            self.id = id
            self.promptKey = promptKey
            self.promptVersion = promptVersion
            self.promptTextSnapshot = promptTextSnapshot
            self.responseText = responseText
            self.stateRaw = state.rawValue
            self.createdAt = createdAt
            self.updatedAt = createdAt
        }
    }

    @Model
    public final class VoiceNote {
        public var id: UUID = UUID()
        public var relativeFilePath: String = ""
        public var durationSeconds: Double = 0
        public var createdAt: Date = Date()
        public var updatedAt: Date = Date()
        public var moment: MemoryMoment?

        public init(
            id: UUID = UUID(),
            relativeFilePath: String,
            durationSeconds: Double,
            createdAt: Date = Date()
        ) {
            self.id = id
            self.relativeFilePath = relativeFilePath
            self.durationSeconds = durationSeconds
            self.createdAt = createdAt
            self.updatedAt = createdAt
        }
    }

    @Model
    public final class ImportBatch {
        public var id: UUID = UUID()
        public var stateRaw: String = MemoryImportState.reading.rawValue
        public var selectedCount: Int = 0
        public var processedCount: Int = 0
        public var failureCount: Int = 0
        public var startedAt: Date = Date()
        public var completedAt: Date?
        public var algorithmVersion: Int = 1
        public var draftTripID: UUID?
        public var recoverableErrorCode: String?

        public var state: MemoryImportState {
            get { MemoryImportState(rawValue: stateRaw) ?? .failed }
            set { stateRaw = newValue.rawValue }
        }

        public init(
            id: UUID = UUID(),
            state: MemoryImportState = .reading,
            selectedCount: Int,
            startedAt: Date = Date(),
            algorithmVersion: Int = 1
        ) {
            self.id = id
            self.stateRaw = state.rawValue
            self.selectedCount = selectedCount
            self.startedAt = startedAt
            self.algorithmVersion = algorithmVersion
        }
    }

    @Model
    public final class GeneratedArtifact {
        public var id: UUID = UUID()
        public var typeRaw: String = MemoryArtifactType.postcard.rawValue
        public var themeID: String = "standard"
        public var privacyPresetRaw: String = ArtifactPrivacyPreset.shareable.rawValue
        public var relativeFilePath: String?
        public var createdAt: Date = Date()
        public var expiresAt: Date?
        public var trip: MemoryTrip?

        public var type: MemoryArtifactType {
            get { MemoryArtifactType(rawValue: typeRaw) ?? .postcard }
            set { typeRaw = newValue.rawValue }
        }

        public init(
            id: UUID = UUID(),
            type: MemoryArtifactType,
            themeID: String,
            privacyPreset: ArtifactPrivacyPreset,
            relativeFilePath: String? = nil,
            createdAt: Date = Date(),
            expiresAt: Date? = nil
        ) {
            self.id = id
            self.typeRaw = type.rawValue
            self.themeID = themeID
            self.privacyPresetRaw = privacyPreset.rawValue
            self.relativeFilePath = relativeFilePath
            self.createdAt = createdAt
            self.expiresAt = expiresAt
        }
    }

    @Model
    public final class ResurfacingRecord {
        public var id: UUID = UUID()
        public var momentID: UUID = UUID()
        public var scheduledAt: Date?
        public var presentedAt: Date?
        public var openedAt: Date?
        public var dismissedAt: Date?
        public var sourceRaw: String = ResurfacingSource.inApp.rawValue

        public init(
            id: UUID = UUID(),
            momentID: UUID,
            source: ResurfacingSource,
            scheduledAt: Date? = nil
        ) {
            self.id = id
            self.momentID = momentID
            self.sourceRaw = source.rawValue
            self.scheduledAt = scheduledAt
        }
    }

    @Model
    public final class PrivateTag {
        public var id: UUID = UUID()
        public var name: String = ""
        public var normalizedName: String = ""
        public var moments: [MemoryMoment] = []

        public init(id: UUID = UUID(), name: String) {
            self.id = id
            self.name = name
            self.normalizedName = name.folding(
                options: [.caseInsensitive, .diacriticInsensitive],
                locale: .current
            )
        }
    }

    @Model
    public final class UserPreference {
        @Attribute(.unique) public var key: String = ""
        public var value: String = ""

        public init(key: String, value: String) {
            self.key = key
            self.value = value
        }
    }
}

public typealias MemoryTrip = SchemaV2.MemoryTrip
public typealias MemoryMoment = SchemaV2.MemoryMoment
public typealias MediaReference = SchemaV2.MediaReference
public typealias PromptResponse = SchemaV2.PromptResponse
public typealias VoiceNote = SchemaV2.VoiceNote
public typealias ImportBatch = SchemaV2.ImportBatch
public typealias GeneratedArtifact = SchemaV2.GeneratedArtifact
public typealias ResurfacingRecord = SchemaV2.ResurfacingRecord
public typealias PrivateTag = SchemaV2.PrivateTag
public typealias UserPreference = SchemaV2.UserPreference

public enum MemoryMigrationPlan: SchemaMigrationPlan {
    public static var schemas: [any VersionedSchema.Type] { [SchemaV2.self] }
    public static var stages: [MigrationStage] { [] }
}
