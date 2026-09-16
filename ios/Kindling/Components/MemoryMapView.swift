import KindlingCore
import KindlingUI
import MapKit
import SwiftUI

struct MemoryMapView: View {
    let moments: [MemoryMoment]
    var interactive = true
    var selectedMomentID: UUID?
    var onSelect: ((MemoryMoment) -> Void)?

    private var located: [MemoryMoment] {
        moments.filter { $0.latitude != nil && $0.longitude != nil && !$0.isHidden }
    }

    var body: some View {
        if located.isEmpty {
            ContentUnavailableView(
                "No map details",
                systemImage: "map",
                description: Text("This trail still works without location metadata.")
            )
            .frame(minHeight: 180)
        } else {
            Map(initialPosition: .region(region), interactionModes: interactive ? .all : []) {
                if coordinates.count > 1 {
                    MapPolyline(coordinates: coordinates)
                        .stroke(KindlingColor.accent.opacity(0.75), lineWidth: 3)
                }
                ForEach(located) { moment in
                    Annotation(moment.displayPlace ?? "Memory", coordinate: coordinate(moment)) {
                        Button {
                            onSelect?(moment)
                        } label: {
                            Image(systemName: selectedMomentID == moment.id ? "flame.fill" : "circle.fill")
                                .font(.system(size: selectedMomentID == moment.id ? 22 : 15))
                                .foregroundStyle(KindlingColor.accent)
                                .padding(8)
                                .background(.thinMaterial, in: Circle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .mapStyle(.standard(pointsOfInterest: .excludingAll))
            .overlay(alignment: .bottomLeading) {
                if coordinates.count > 1 {
                    Text("Approximate memory path")
                        .font(.kindlingCaption)
                        .foregroundStyle(KindlingColor.textSecondary)
                        .padding(8)
                        .background(.regularMaterial, in: Capsule())
                        .padding(8)
                }
            }
            .accessibilityHidden(true)
        }
    }

    private var coordinates: [CLLocationCoordinate2D] { located.map(coordinate) }

    private var region: MKCoordinateRegion {
        let points = coordinates
        guard let first = points.first else {
            return MKCoordinateRegion(center: .init(), span: .init(latitudeDelta: 1, longitudeDelta: 1))
        }
        let minLatitude = points.map(\.latitude).min() ?? first.latitude
        let maxLatitude = points.map(\.latitude).max() ?? first.latitude
        let minLongitude = points.map(\.longitude).min() ?? first.longitude
        let maxLongitude = points.map(\.longitude).max() ?? first.longitude
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: (minLatitude + maxLatitude) / 2,
                longitude: (minLongitude + maxLongitude) / 2
            ),
            span: MKCoordinateSpan(
                latitudeDelta: max(0.02, (maxLatitude - minLatitude) * 1.45),
                longitudeDelta: max(0.02, (maxLongitude - minLongitude) * 1.45)
            )
        )
    }

    private func coordinate(_ moment: MemoryMoment) -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: moment.latitude ?? 0, longitude: moment.longitude ?? 0)
    }
}
