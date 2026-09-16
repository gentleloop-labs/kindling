import Foundation
import KindlingCore
import SwiftData

@MainActor
enum MemoryDeletionService {
    static func delete(_ trip: MemoryTrip, from context: ModelContext) {
        for moment in trip.moments {
            for media in moment.mediaReferences {
                MemoryFileStore.remove(relativePath: media.importedFileRelativePath, from: .media)
                MemoryFileStore.remove(relativePath: media.posterFileRelativePath, from: .thumbnails)
            }
            for note in moment.voiceNotes {
                MemoryFileStore.remove(relativePath: note.relativeFilePath, from: .voice)
            }
        }
        for artifact in trip.artifacts {
            MemoryFileStore.remove(relativePath: artifact.relativeFilePath, from: .exports)
        }
        context.delete(trip)
        try? context.save()
    }
}
