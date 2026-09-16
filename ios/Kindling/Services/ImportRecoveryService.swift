import Foundation
import KindlingCore
import SwiftData

@MainActor
enum ImportRecoveryService {
    /// Photo picker item providers cannot be recreated after process death. An
    /// interrupted import is therefore rolled back, while a completed draft in
    /// review is preserved for the person to continue editing from Atlas.
    static func recoverInterruptedImports(in context: ModelContext) {
        let descriptor = FetchDescriptor<ImportBatch>()
        guard let batches = try? context.fetch(descriptor) else { return }

        for batch in batches where isInterrupted(batch.state) {
            if let draftID = batch.draftTripID,
               let trip = fetchTrip(id: draftID, in: context) {
                MemoryDeletionService.delete(trip, from: context)
            }
            batch.state = .failed
            batch.recoverableErrorCode = "interrupted"
            batch.completedAt = .now
        }
        try? context.save()
    }

    static func markDraft(_ tripID: UUID, as state: MemoryImportState, in context: ModelContext) {
        let descriptor = FetchDescriptor<ImportBatch>(
            predicate: #Predicate { $0.draftTripID == tripID }
        )
        guard let batches = try? context.fetch(descriptor) else { return }
        for batch in batches {
            batch.state = state
            batch.completedAt = .now
        }
        try? context.save()
    }

    private static func isInterrupted(_ state: MemoryImportState) -> Bool {
        switch state {
        case .reading, .clustering, .resolvingPlaces:
            true
        case .reviewing, .saved, .failed, .cancelled:
            false
        }
    }

    private static func fetchTrip(id: UUID, in context: ModelContext) -> MemoryTrip? {
        var descriptor = FetchDescriptor<MemoryTrip>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }
}
