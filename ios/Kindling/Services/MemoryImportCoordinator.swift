import Foundation
import KindlingCore
import Observation
import PhotosUI
import SwiftData
import SwiftUI

@MainActor
@Observable
final class MemoryImportCoordinator {
    enum Phase: Equatable {
        case idle
        case reading
        case clustering
        case resolvingPlaces
        case ready
        case failed(String)
        case cancelled

        var title: String {
            switch self {
            case .idle: "Getting ready"
            case .reading: "Gathering your moments"
            case .clustering: "Arranging your memory trail"
            case .resolvingPlaces: "Finding the places"
            case .ready: "Your draft is ready"
            case .failed: "The import paused"
            case .cancelled: "Import cancelled"
            }
        }
    }

    private(set) var phase: Phase = .idle
    private(set) var processedCount = 0
    private(set) var selectedCount = 0
    private(set) var failedCount = 0
    private(set) var trip: MemoryTrip?

    @ObservationIgnored private var importTask: Task<Void, Never>?
    @ObservationIgnored private var context: ModelContext?
    @ObservationIgnored private var batch: ImportBatch?
    @ObservationIgnored private var stagingMoment: MemoryMoment?
    @ObservationIgnored private var processedMedia: [ProcessedMedia] = []

    var progress: Double {
        guard selectedCount > 0 else { return 0 }
        return min(1, Double(processedCount) / Double(selectedCount))
    }

    func start(items: [PhotosPickerItem], context: ModelContext) {
        guard importTask == nil else { return }
        self.context = context

        var seen = Set<String>()
        let unique = items.enumerated().filter { index, item in
            let key = item.itemIdentifier ?? "selection-\(index)"
            return seen.insert(key).inserted
        }
        selectedCount = unique.count
        let batch = ImportBatch(selectedCount: unique.count)
        let trip = MemoryTrip(title: "Import in progress")
        let stagingMoment = MemoryMoment(sortIndex: 0)
        trip.moments.append(stagingMoment)
        batch.draftTripID = trip.id
        self.batch = batch
        self.trip = trip
        self.stagingMoment = stagingMoment
        context.insert(batch)
        context.insert(trip)
        try? context.save()

        importTask = Task { [weak self] in
            guard let self else { return }
            await self.run(uniqueItems: unique)
        }
    }

    func cancel() {
        importTask?.cancel()
        importTask = nil
        phase = .cancelled
        batch?.state = .cancelled
        batch?.completedAt = .now
        if let trip, let context {
            MemoryDeletionService.delete(trip, from: context)
        } else {
            cleanupProcessedFiles()
        }
        try? context?.save()
    }

    private func run(uniqueItems: [(offset: Int, element: PhotosPickerItem)]) async {
        guard let context, let batch else { return }
        let startedAt = Date()
        phase = .reading
        batch.state = .reading
        let service = MediaImportService()

        for chunkStart in stride(from: 0, to: uniqueItems.count, by: 3) {
            if Task.isCancelled { cancel(); return }
            let chunk = Array(uniqueItems[chunkStart..<min(chunkStart + 3, uniqueItems.count)])
            let outcomes = await withTaskGroup(of: ProcessedOutcome.self, returning: [ProcessedOutcome].self) { group in
                for entry in chunk {
                    group.addTask {
                        do {
                            let media = try await service.process(item: entry.element, index: entry.offset)
                            return .success(entry.offset, media)
                        } catch is CancellationError {
                            return .cancelled(entry.offset)
                        } catch {
                            return .failed(entry.offset)
                        }
                    }
                }
                var values: [ProcessedOutcome] = []
                for await value in group { values.append(value) }
                return values
            }

            for outcome in outcomes.sorted(by: { $0.index < $1.index }) {
                switch outcome {
                case .success(_, let media):
                    processedMedia.append(media)
                    attachToStaging(media, context: context)
                case .failed: failedCount += 1
                case .cancelled: break
                }
                processedCount += 1
                batch.processedCount = processedCount
                batch.failureCount = failedCount
                try? context.save()
            }
        }

        guard !Task.isCancelled else { cancel(); return }
        guard !processedMedia.isEmpty else {
            batch.state = .failed
            batch.recoverableErrorCode = "no_media_available"
            batch.completedAt = .now
            phase = .failed("None of those items could be loaded. Your originals are unchanged.")
            if let trip {
                MemoryDeletionService.delete(trip, from: context)
                self.trip = nil
                stagingMoment = nil
            }
            try? context.save()
            return
        }

        phase = .clustering
        batch.state = .clustering
        let clusters = DeterministicTripClusteringService().cluster(
            processedMedia.map(\.clusteringMetadata)
        )
        guard let trip else { return }
        arrangeTrip(trip, from: clusters, context: context)
        try? context.save()

        phase = .resolvingPlaces
        batch.state = .resolvingPlaces
        await resolvePlaces(for: trip)
        trip.summaryPlaceText = trip.orderedMoments.compactMap(\.displayPlace).first
        trip.updatedAt = .now
        batch.state = .reviewing
        batch.completedAt = .now
        try? context.save()

        phase = .ready
        _ = startedAt
    }

    private func arrangeTrip(
        _ trip: MemoryTrip,
        from clusters: [ClusteredMemoryMoment],
        context: ModelContext
    ) {
        let dates = processedMedia.compactMap(\.creationDate).sorted()
        trip.title = dates.first.map { "Trip from \($0.formatted(.dateTime.month(.wide).year()))" }
            ?? "A trip to remember"
        trip.startDate = dates.first
        trip.endDate = dates.last
        trip.updatedAt = .now
        let references = stagingMoment?.mediaReferences ?? []
        let mediaByID = Dictionary(uniqueKeysWithValues: references.map { ($0.id, $0) })

        for (momentIndex, cluster) in clusters.enumerated() {
            let moment = MemoryMoment(
                capturedAt: cluster.startDate,
                endCapturedAt: cluster.endDate,
                latitude: cluster.representativeLatitude,
                longitude: cluster.representativeLongitude,
                sortIndex: momentIndex
            )
            trip.moments.append(moment)
            for (mediaIndex, mediaID) in cluster.mediaIDs.enumerated() {
                guard let reference = mediaByID[mediaID] else { continue }
                reference.sortIndex = mediaIndex
                reference.moment = moment
                moment.mediaReferences.append(reference)
            }
        }
        if let stagingMoment {
            stagingMoment.mediaReferences.removeAll()
            context.delete(stagingMoment)
            self.stagingMoment = nil
        }
        trip.coverMediaReferenceID = trip.orderedMoments.first?.orderedMedia.first?.id
    }

    /// Gives every optimized file a persisted owner immediately. If the process
    /// is interrupted before clustering, launch recovery can remove the draft
    /// and its files without scanning or guessing.
    private func attachToStaging(_ media: ProcessedMedia, context: ModelContext) {
        guard let stagingMoment else { return }
        let reference = MediaReference(
            id: media.id,
            localIdentifier: media.stableIdentifier.hasPrefix("selection-") ? nil : media.stableIdentifier,
            importedFileRelativePath: media.relativePath,
            posterFileRelativePath: media.posterRelativePath,
            mediaType: media.mediaType,
            creationDate: media.creationDate,
            latitude: media.latitude,
            longitude: media.longitude,
            pixelWidth: media.pixelWidth,
            pixelHeight: media.pixelHeight,
            durationSeconds: media.durationSeconds,
            sortIndex: stagingMoment.mediaReferences.count,
            metadataFingerprint: media.fingerprint
        )
        stagingMoment.mediaReferences.append(reference)
        try? context.save()
    }

    private func resolvePlaces(for trip: MemoryTrip) async {
        let resolver = PlaceResolutionService()
        for moment in trip.orderedMoments {
            guard !Task.isCancelled,
                  let latitude = moment.latitude,
                  let longitude = moment.longitude,
                  let place = await resolver.resolve(latitude: latitude, longitude: longitude)
            else { continue }
            moment.placeName = place.name
            moment.locality = place.locality
            moment.administrativeArea = place.administrativeArea
            moment.countryCode = place.countryCode
            moment.placeSource = .geocoder
            moment.placeConfidence = 0.8
        }
    }

    private func cleanupProcessedFiles() {
        for media in processedMedia {
            MemoryFileStore.remove(relativePath: media.relativePath, from: .media)
            MemoryFileStore.remove(relativePath: media.posterRelativePath, from: .thumbnails)
        }
        processedMedia = []
    }
}

private enum ProcessedOutcome: Sendable {
    case success(Int, ProcessedMedia)
    case failed(Int)
    case cancelled(Int)

    var index: Int {
        switch self {
        case .success(let index, _), .failed(let index), .cancelled(let index): index
        }
    }
}
