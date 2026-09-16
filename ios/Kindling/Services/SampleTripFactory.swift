import Foundation
import KindlingCore
import SwiftData

@MainActor
enum SampleTripFactory {
    static let sampleTitle = "A Weekend in Lisbon"

    static func existing(in context: ModelContext) -> MemoryTrip? {
        let title = sampleTitle
        let descriptor = FetchDescriptor<MemoryTrip>(predicate: #Predicate {
            $0.sourceRaw == "sample" && $0.title == title
        })
        return try? context.fetch(descriptor).first
    }

    static func create(in context: ModelContext) -> MemoryTrip {
        if let existing = existing(in: context) { return existing }
        let calendar = Calendar(identifier: .gregorian)
        let start = calendar.date(from: DateComponents(year: 2025, month: 5, day: 16, hour: 10))!
        let trip = MemoryTrip(
            title: sampleTitle,
            status: .complete,
            source: .sample,
            startDate: start,
            endDate: start.addingTimeInterval(2 * 24 * 3600)
        )
        trip.summaryPlaceText = "Lisbon, Portugal"
        let moments: [(String, String, String, Double, Double, TimeInterval)] = [
            ("The yellow tram", "The bell echoed through the narrow street.", "SampleTram", 38.7138, -9.1394, 0),
            ("Pastéis while they were warm", "Flaky, cinnamon-dusted, and gone too quickly.", "SampleTarts", 38.6975, -9.2064, 5 * 3600),
            ("Sunset over Alfama", "We stayed after the music started below us.", "SampleSunset", 38.7110, -9.1295, 32 * 3600),
            ("One last tiled doorway", "A small detail I would have forgotten without the photo.", "SampleDoor", 38.7102, -9.1421, 48 * 3600)
        ]
        for (index, value) in moments.enumerated() {
            let moment = MemoryMoment(
                title: value.0,
                capturedAt: start.addingTimeInterval(value.5),
                latitude: value.3,
                longitude: value.4,
                placeName: value.0,
                sortIndex: index
            )
            moment.locality = "Lisbon"
            moment.countryCode = "PT"
            moment.noteText = value.1
            let media = MediaReference(
                bundledAssetName: value.2,
                mediaType: .image,
                creationDate: start.addingTimeInterval(value.5),
                latitude: value.3,
                longitude: value.4,
                pixelWidth: 1_600,
                pixelHeight: 1_067,
                sortIndex: 0,
                metadataFingerprint: "sample-\(index)"
            )
            moment.mediaReferences.append(media)
            if index == 0 { trip.coverMediaReferenceID = media.id }
            trip.moments.append(moment)
        }
        context.insert(trip)
        try? context.save()
        return trip
    }
}
