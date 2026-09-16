import Foundation

public struct MemoryMediaMetadata: Sendable, Equatable {
    public let id: UUID
    public let stableIdentifier: String
    public let creationDate: Date?
    public let latitude: Double?
    public let longitude: Double?

    public init(
        id: UUID,
        stableIdentifier: String,
        creationDate: Date?,
        latitude: Double?,
        longitude: Double?
    ) {
        self.id = id
        self.stableIdentifier = stableIdentifier
        self.creationDate = creationDate
        self.latitude = latitude
        self.longitude = longitude
    }
}

public struct ClusteredMemoryMoment: Sendable, Equatable {
    public let mediaIDs: [UUID]
    public let startDate: Date?
    public let endDate: Date?
    public let representativeLatitude: Double?
    public let representativeLongitude: Double?

    public init(
        mediaIDs: [UUID],
        startDate: Date?,
        endDate: Date?,
        representativeLatitude: Double?,
        representativeLongitude: Double?
    ) {
        self.mediaIDs = mediaIDs
        self.startDate = startDate
        self.endDate = endDate
        self.representativeLatitude = representativeLatitude
        self.representativeLongitude = representativeLongitude
    }
}

public struct TripSplitProposal: Sendable, Equatable {
    public let beforeMediaID: UUID
    public let reason: Reason

    public enum Reason: String, Sendable, Equatable {
        case longTimeGap = "long_time_gap"
        case distantRegion = "distant_region"
        case longSpan = "long_span"
    }
}

public struct MemoryClusteringConfiguration: Sendable, Equatable {
    public var momentTimeGap: TimeInterval
    public var nearbyTimeWindow: TimeInterval
    public var nearbyDistanceMeters: Double
    public var tripTimeGap: TimeInterval
    public var distantRegionMeters: Double
    public var maximumTripSpan: TimeInterval
    public var algorithmVersion: Int

    public static let v1 = MemoryClusteringConfiguration(
        momentTimeGap: 6 * 60 * 60,
        nearbyTimeWindow: 3 * 60 * 60,
        nearbyDistanceMeters: 1_000,
        tripTimeGap: 72 * 60 * 60,
        distantRegionMeters: 500_000,
        maximumTripSpan: 21 * 24 * 60 * 60,
        algorithmVersion: 1
    )

    public init(
        momentTimeGap: TimeInterval,
        nearbyTimeWindow: TimeInterval,
        nearbyDistanceMeters: Double,
        tripTimeGap: TimeInterval,
        distantRegionMeters: Double,
        maximumTripSpan: TimeInterval,
        algorithmVersion: Int
    ) {
        self.momentTimeGap = momentTimeGap
        self.nearbyTimeWindow = nearbyTimeWindow
        self.nearbyDistanceMeters = nearbyDistanceMeters
        self.tripTimeGap = tripTimeGap
        self.distantRegionMeters = distantRegionMeters
        self.maximumTripSpan = maximumTripSpan
        self.algorithmVersion = algorithmVersion
    }
}

public protocol TripClusteringService: Sendable {
    func cluster(_ media: [MemoryMediaMetadata]) -> [ClusteredMemoryMoment]
    func proposedTripSplits(_ media: [MemoryMediaMetadata]) -> [TripSplitProposal]
}

public struct DeterministicTripClusteringService: TripClusteringService {
    public let configuration: MemoryClusteringConfiguration

    public init(configuration: MemoryClusteringConfiguration = .v1) {
        self.configuration = configuration
    }

    public func cluster(_ media: [MemoryMediaMetadata]) -> [ClusteredMemoryMoment] {
        let ordered = Self.ordered(media)
        guard let first = ordered.first else { return [] }

        var groups: [[MemoryMediaMetadata]] = [[first]]
        for item in ordered.dropFirst() {
            let previous = groups[groups.count - 1].last!
            if startsNewMoment(previous: previous, current: item) {
                groups.append([item])
            } else {
                groups[groups.count - 1].append(item)
            }
        }
        return groups.map(Self.makeMoment)
    }

    public func proposedTripSplits(_ media: [MemoryMediaMetadata]) -> [TripSplitProposal] {
        let ordered = Self.ordered(media)
        guard ordered.count > 1 else { return [] }
        var result: [TripSplitProposal] = []
        let firstDate = ordered.compactMap(\.creationDate).first

        for pair in zip(ordered, ordered.dropFirst()) {
            let previous = pair.0
            let current = pair.1
            if let lhs = previous.creationDate, let rhs = current.creationDate,
               rhs.timeIntervalSince(lhs) > configuration.tripTimeGap {
                result.append(TripSplitProposal(beforeMediaID: current.id, reason: .longTimeGap))
                continue
            }
            if let distance = Self.distance(from: previous, to: current),
               distance > configuration.distantRegionMeters {
                result.append(TripSplitProposal(beforeMediaID: current.id, reason: .distantRegion))
                continue
            }
            if let firstDate, let date = current.creationDate,
               date.timeIntervalSince(firstDate) > configuration.maximumTripSpan,
               !result.contains(where: { $0.beforeMediaID == current.id }) {
                result.append(TripSplitProposal(beforeMediaID: current.id, reason: .longSpan))
            }
        }
        return result
    }

    private func startsNewMoment(
        previous: MemoryMediaMetadata,
        current: MemoryMediaMetadata
    ) -> Bool {
        guard let previousDate = previous.creationDate,
              let currentDate = current.creationDate
        else { return false }
        let elapsed = max(0, currentDate.timeIntervalSince(previousDate))
        if elapsed > configuration.momentTimeGap { return true }
        guard let distance = Self.distance(from: previous, to: current) else { return false }
        return elapsed > configuration.nearbyTimeWindow
            && distance > configuration.nearbyDistanceMeters
    }

    private static func ordered(_ media: [MemoryMediaMetadata]) -> [MemoryMediaMetadata] {
        media.sorted { lhs, rhs in
            switch (lhs.creationDate, rhs.creationDate) {
            case let (left?, right?) where left != right: left < right
            case (_?, nil): true
            case (nil, _?): false
            default: lhs.stableIdentifier < rhs.stableIdentifier
            }
        }
    }

    private static func makeMoment(_ items: [MemoryMediaMetadata]) -> ClusteredMemoryMoment {
        let dates = items.compactMap(\.creationDate).sorted()
        let locations = items.compactMap { item -> (Double, Double)? in
            guard let latitude = item.latitude, let longitude = item.longitude else { return nil }
            return (latitude, longitude)
        }
        let latitude = locations.isEmpty ? nil : locations.map(\.0).reduce(0, +) / Double(locations.count)
        let longitude = locations.isEmpty ? nil : locations.map(\.1).reduce(0, +) / Double(locations.count)
        return ClusteredMemoryMoment(
            mediaIDs: items.map(\.id),
            startDate: dates.first,
            endDate: dates.last,
            representativeLatitude: latitude,
            representativeLongitude: longitude
        )
    }

    public static func distance(from lhs: MemoryMediaMetadata, to rhs: MemoryMediaMetadata) -> Double? {
        guard let latitude1 = lhs.latitude,
              let longitude1 = lhs.longitude,
              let latitude2 = rhs.latitude,
              let longitude2 = rhs.longitude
        else { return nil }

        let radius = 6_371_000.0
        let phi1 = latitude1 * .pi / 180
        let phi2 = latitude2 * .pi / 180
        let deltaPhi = (latitude2 - latitude1) * .pi / 180
        let deltaLambda = (longitude2 - longitude1) * .pi / 180
        let a = sin(deltaPhi / 2) * sin(deltaPhi / 2)
            + cos(phi1) * cos(phi2)
            * sin(deltaLambda / 2) * sin(deltaLambda / 2)
        return radius * 2 * atan2(sqrt(a), sqrt(1 - a))
    }
}
