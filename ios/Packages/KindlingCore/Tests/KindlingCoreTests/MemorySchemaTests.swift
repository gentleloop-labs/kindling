import Foundation
import SwiftData
import Testing
@testable import KindlingCore

@Suite("Memory schema")
struct MemorySchemaTests {
    @Test("the memory schema declares the ten product entities")
    func entityCount() {
        #expect(SchemaV2.models.count == 10)
    }

    @Test("a complete memory graph round-trips")
    @MainActor
    func graphRoundTrip() throws {
        let container = try MemoryStore.makeModelContainer(inMemory: true)
        let context = ModelContext(container)
        let trip = MemoryTrip(title: "Lisbon", status: .complete)
        let moment = MemoryMoment(title: "First tram", capturedAt: .now, sortIndex: 0)
        let media = MediaReference(mediaType: .image, creationDate: .now, sortIndex: 0)
        moment.mediaReferences.append(media)
        trip.moments.append(moment)
        context.insert(trip)
        try context.save()

        let fetched = try #require(context.fetch(FetchDescriptor<MemoryTrip>()).first)
        #expect(fetched.title == "Lisbon")
        #expect(fetched.status == .complete)
        #expect(fetched.moments.count == 1)
        #expect(fetched.moments.first?.mediaReferences.count == 1)
    }

    @Test("deleting a trip cascades its owned graph")
    @MainActor
    func cascadeDelete() throws {
        let container = try MemoryStore.makeModelContainer(inMemory: true)
        let context = ModelContext(container)
        let trip = MemoryTrip(title: "Kyoto")
        let moment = MemoryMoment(sortIndex: 0)
        moment.mediaReferences.append(MediaReference(mediaType: .image, sortIndex: 0))
        moment.promptResponses.append(PromptResponse(
            promptKey: "sensory.sound",
            promptTextSnapshot: "What did this place sound like?",
            state: .answered
        ))
        moment.voiceNotes.append(VoiceNote(relativeFilePath: "note.m4a", durationSeconds: 4))
        trip.moments.append(moment)
        context.insert(trip)
        try context.save()
        context.delete(trip)
        try context.save()

        #expect(try context.fetch(FetchDescriptor<MemoryMoment>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<MediaReference>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<PromptResponse>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<VoiceNote>()).isEmpty)
    }
}
