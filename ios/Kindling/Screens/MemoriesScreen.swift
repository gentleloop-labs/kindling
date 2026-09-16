import KindlingCore
import KindlingUI
import SwiftData
import SwiftUI

struct MemoriesScreen: View {
    @Environment(\.analyticsTracker) private var analytics
    @Query(sort: \MemoryTrip.updatedAt, order: .reverse) private var trips: [MemoryTrip]
    @State private var query = ""
    @State private var favoritesOnly = false
    @State private var returnIntentOnly = false

    private var results: [MemoryTrip] {
        trips.filter { trip in
            guard trip.status == .complete else { return false }
            if favoritesOnly && !trip.isFavorite { return false }
            if returnIntentOnly && !trip.moments.contains(where: { $0.returnIntent == .yes }) { return false }
            let needle = MemorySearchNormalizer.normalize(query)
            guard !needle.isEmpty else { return true }
            let fields = [trip.title, trip.summaryPlaceText]
                + trip.moments.flatMap { moment in
                    [moment.title, moment.noteText, moment.placeName, moment.locality]
                        + moment.promptResponses.map(\.responseText)
                        + moment.tags.map { Optional($0.name) }
                }
            return fields.compactMap { $0 }
                .contains { MemorySearchNormalizer.normalize($0).contains(needle) }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if results.isEmpty {
                    ContentUnavailableView.search(text: query)
                } else {
                    List(results) { trip in
                        NavigationLink {
                            MemoryTrailView(trip: trip)
                        } label: {
                            HStack(spacing: Space.s2) {
                                MemoryMediaView(reference: cover(for: trip), height: 76)
                                    .frame(width: 88)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(trip.title).font(.kindlingButton)
                                    Text([trip.summaryPlaceText, "\(trip.moments.count) moments"]
                                        .compactMap { $0 }.joined(separator: " · "))
                                        .font(.kindlingCaption)
                                        .foregroundStyle(KindlingColor.textSecondary)
                                }
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .background(KindlingColor.background)
            .navigationTitle("Memories")
            .searchable(text: $query, prompt: "Place, note, tag, or trip")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Toggle("Favorites", isOn: $favoritesOnly)
                        Toggle("Would return", isOn: $returnIntentOnly)
                    } label: {
                        Label("Filters", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .onSubmit(of: .search) {
                analytics.track(.searchPerformed(results: AnalyticsResultBucket(results.count)))
            }
        }
    }

    private func cover(for trip: MemoryTrip) -> MediaReference? {
        let media = trip.orderedMoments.flatMap(\.orderedMedia)
        return media.first(where: { $0.id == trip.coverMediaReferenceID }) ?? media.first
    }
}
