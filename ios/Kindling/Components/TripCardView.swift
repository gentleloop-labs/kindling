import KindlingCore
import KindlingUI
import SwiftUI

struct TripCardView: View {
    let trip: MemoryTrip

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            MemoryMediaView(reference: cover, height: 148)
            VStack(alignment: .leading, spacing: 5) {
                Text(trip.title)
                    .font(.kindlingButton)
                    .foregroundStyle(KindlingColor.textPrimary)
                    .lineLimit(2)
                HStack(spacing: 6) {
                    if let dateText {
                        Text(dateText)
                    }
                    if let place = trip.summaryPlaceText {
                        if dateText != nil { Text("·") }
                        Text(place)
                    }
                }
                .font(.kindlingCaption)
                .foregroundStyle(KindlingColor.textSecondary)
                .lineLimit(1)
                Text("\(trip.moments.count) moments")
                    .font(.kindlingCaption)
                    .foregroundStyle(KindlingColor.textSecondary)
            }
            .padding(Space.s2)
        }
        .background(KindlingColor.surface, in: RoundedRectangle(cornerRadius: KindlingLayout.radius))
        .clipShape(RoundedRectangle(cornerRadius: KindlingLayout.radius))
        .accessibilityElement(children: .combine)
    }

    private var cover: MediaReference? {
        let all = trip.orderedMoments.flatMap(\.orderedMedia)
        return all.first(where: { $0.id == trip.coverMediaReferenceID }) ?? all.first
    }

    private var dateText: String? {
        guard let start = trip.startDate else { return nil }
        if let end = trip.endDate, !Calendar.current.isDate(start, inSameDayAs: end) {
            return "\(start.formatted(.dateTime.month(.abbreviated).day()))–\(end.formatted(.dateTime.month(.abbreviated).day().year()))"
        }
        return start.formatted(.dateTime.month(.abbreviated).day().year())
    }
}
