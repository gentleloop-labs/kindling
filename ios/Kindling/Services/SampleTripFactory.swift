import Foundation
import KindlingCore
import SwiftData

@MainActor
enum SampleTripFactory {
    static let sampleTitle = "A Weekend in Lisbon"

    private struct LibraryTrip {
        let title: String
        let place: String
        let assetName: String
        let start: DateComponents
        let latitude: Double
        let longitude: Double
        let momentTitles: [String]
    }

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
            if index == 0 {
                moment.returnIntent = .yes
                moment.tags.append(PrivateTag(name: "tram ride"))
                moment.tags.append(PrivateTag(name: "golden hour"))
                moment.promptResponses.append(PromptResponse(
                    promptKey: "sample.sound",
                    promptTextSnapshot: "What sound brings this moment back?",
                    responseText: "The bell bouncing between the tiled buildings.",
                    state: .answered
                ))
            }
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

    /// Populates a realistic library for deterministic marketing captures. The
    /// app's normal bundled sample remains a single Lisbon trail.
    static func createScreenshotLibrary(in context: ModelContext) {
        let lisbon = create(in: context)
        lisbon.status = .complete
        lisbon.updatedAt = .now

        let calendar = Calendar(identifier: .gregorian)
        let definitions = [
            LibraryTrip(
                title: "Rainlight in Kyoto",
                place: "Kyoto, Japan",
                assetName: "SampleKyoto",
                start: DateComponents(year: 2025, month: 4, day: 7, hour: 18),
                latitude: 35.0037,
                longitude: 135.7788,
                momentTitles: ["Lanterns after rain", "Tea near Gion", "The quiet walk home"]
            ),
            LibraryTrip(
                title: "Three Days on the Amalfi Coast",
                place: "Positano, Italy",
                assetName: "SampleAmalfi",
                start: DateComponents(year: 2024, month: 9, day: 9, hour: 15),
                latitude: 40.6281,
                longitude: 14.4849,
                momentTitles: ["Espresso above the sea", "The road to Ravello", "Last swim before sunset"]
            ),
            LibraryTrip(
                title: "The Long Way Around Iceland",
                place: "South Coast, Iceland",
                assetName: "SampleIceland",
                start: DateComponents(year: 2024, month: 3, day: 18, hour: 8),
                latitude: 63.5321,
                longitude: -19.5114,
                momentTitles: ["Woke up beside the falls", "Black sand and strong wind", "Soup at the tiny harbor"]
            )
        ]

        for (offset, definition) in definitions.enumerated() {
            let title = definition.title
            let descriptor = FetchDescriptor<MemoryTrip>(predicate: #Predicate {
                $0.sourceRaw == "sample" && $0.title == title
            })
            if let existing = try? context.fetch(descriptor).first {
                existing.status = .complete
                continue
            }

            let start = calendar.date(from: definition.start)!
            let trip = MemoryTrip(
                title: definition.title,
                status: .complete,
                source: .sample,
                startDate: start,
                endDate: start.addingTimeInterval(3 * 24 * 3600),
                createdAt: start
            )
            trip.summaryPlaceText = definition.place
            trip.updatedAt = Date().addingTimeInterval(TimeInterval(-(offset + 1) * 60))

            for (index, title) in definition.momentTitles.enumerated() {
                let capturedAt = start.addingTimeInterval(TimeInterval(index * 8 * 3600))
                let moment = MemoryMoment(
                    title: title,
                    capturedAt: capturedAt,
                    latitude: definition.latitude + Double(index) * 0.008,
                    longitude: definition.longitude + Double(index) * 0.008,
                    placeName: index == 0 ? definition.place : title,
                    sortIndex: index
                )
                moment.locality = definition.place
                moment.noteText = index == 0 ? "The kind of view that made us put our phones down." : nil
                if index == 0 {
                    let media = MediaReference(
                        bundledAssetName: definition.assetName,
                        mediaType: .image,
                        creationDate: capturedAt,
                        latitude: definition.latitude,
                        longitude: definition.longitude,
                        pixelWidth: 1_200,
                        pixelHeight: 1_800,
                        sortIndex: 0,
                        metadataFingerprint: "screenshot-\(offset)"
                    )
                    moment.mediaReferences.append(media)
                    trip.coverMediaReferenceID = media.id
                }
                trip.moments.append(moment)
            }
            context.insert(trip)
        }
        try? context.save()
    }
}
