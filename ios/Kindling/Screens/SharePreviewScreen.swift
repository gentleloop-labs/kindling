import KindlingCore
import KindlingUI
import SwiftData
import SwiftUI
import UIKit

struct SharePreviewScreen: View {
    @Bindable var trip: MemoryTrip
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.analyticsTracker) private var analytics
    @Environment(StoreKitEntitlementStore.self) private var entitlements

    @State private var artifactType: AnalyticsArtifactType = .postcard
    @State private var theme: ShareTheme = .standard
    @State private var privacy = ArtifactPrivacySelection.shareable
    @State private var artifactURL: URL?
    @State private var isRendering = false
    @State private var showingPaywall = false
    @State private var message: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Space.s3) {
                    ArtifactCanvasView(
                        trip: trip,
                        type: artifactType,
                        theme: theme,
                        privacy: privacy
                    )
                    .aspectRatio(4 / 5, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: KindlingLayout.radius))
                    .shadow(color: .black.opacity(0.12), radius: 12, y: 6)
                    .accessibilityLabel("Exact sharing preview")

                    Picker("Artifact", selection: $artifactType) {
                        Text("Postcard").tag(AnalyticsArtifactType.postcard)
                        Text("Map card").tag(AnalyticsArtifactType.mapCard)
                    }
                    .pickerStyle(.segmented)

                    VStack(alignment: .leading, spacing: Space.s1) {
                        Text("Style").font(.kindlingButton)
                        ScrollView(.horizontal) {
                            HStack {
                                ForEach(ShareTheme.allCases) { candidate in
                                    Button {
                                        if candidate.isPro && !entitlements.hasPro {
                                            analytics.track(.paywallDisplayed(source: .premiumTheme))
                                            showingPaywall = true
                                        } else {
                                            theme = candidate
                                            artifactURL = nil
                                        }
                                    } label: {
                                        VStack(spacing: 4) {
                                            Circle()
                                                .fill(candidate.background)
                                                .frame(width: 38, height: 38)
                                                .overlay {
                                                    if theme == candidate {
                                                        Circle().stroke(KindlingColor.focus, lineWidth: 3)
                                                    }
                                                }
                                            Text(candidate.label + (candidate.isPro ? " Pro" : ""))
                                                .font(.kindlingCaption)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .scrollIndicators(.hidden)
                    }

                    VStack(alignment: .leading, spacing: Space.s1) {
                        Text("What to include").font(.kindlingButton)
                        Toggle("Trip title", isOn: $privacy.includesTitle)
                        Toggle("Dates", isOn: $privacy.includesDates)
                        Toggle("Places", isOn: $privacy.includesPlaces)
                        Toggle("Notes", isOn: $privacy.includesNotes)
                        Toggle("Sensitive moments", isOn: $privacy.includesSensitiveMoments)
                    }
                    .padding(Space.s2)
                    .background(KindlingColor.surface, in: RoundedRectangle(cornerRadius: KindlingLayout.radius))

                    if let message {
                        Text(message)
                            .font(.kindlingCaption)
                            .foregroundStyle(KindlingColor.textSecondary)
                    }

                    if let artifactURL {
                        ShareLink(item: artifactURL) {
                            Label("Share", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.kindlingPrimary)
                        .simultaneousGesture(TapGesture().onEnded {
                            analytics.track(.shareSheetOpened)
                        })
                    } else {
                        Button(isRendering ? "Preparing…" : "Prepare to share") {
                            render()
                        }
                        .buttonStyle(.kindlingPrimary)
                        .disabled(isRendering || (artifactType == .mapCard && locatedMoments.isEmpty))
                    }
                }
                .padding(Space.s3)
            }
            .background(KindlingColor.background)
            .navigationTitle("Privacy preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .onChange(of: artifactType) { _, _ in artifactURL = nil }
        .onChange(of: privacy) { _, _ in artifactURL = nil }
        .sheet(isPresented: $showingPaywall) {
            PaywallScreen(source: .premiumTheme) {
                theme = .dusk
            }
        }
    }

    private var locatedMoments: [MemoryMoment] {
        trip.orderedMoments.filter { $0.latitude != nil && $0.longitude != nil }
    }

    @MainActor
    private func render() {
        isRendering = true
        message = nil
        let view = ArtifactCanvasView(
            trip: trip,
            type: artifactType,
            theme: theme,
            privacy: privacy
        )
        .frame(width: 540, height: 675)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2
        guard let image = renderer.uiImage,
              let data = image.pngData()
        else {
            isRendering = false
            message = "That card could not be prepared. Try a different style."
            return
        }

        do {
            let filename = "kindling-\(UUID().uuidString).png"
            let url = try MemoryFileStore.URL(forRelativePath: filename, in: .exports)
            try data.write(to: url, options: .atomic)
            let artifact = GeneratedArtifact(
                type: artifactType == .postcard ? .postcard : .mapCard,
                themeID: theme.rawValue,
                privacyPreset: privacy == .shareable ? .shareable : .custom,
                relativeFilePath: filename,
                expiresAt: Date().addingTimeInterval(7 * 24 * 3600)
            )
            trip.artifacts.append(artifact)
            try? context.save()
            artifactURL = url
            analytics.track(.recapExported(
                type: artifactType,
                theme: theme.analyticsTheme,
                privacy: privacy == .shareable ? .shareable : .custom
            ))
        } catch {
            message = "Kindling could not save the card. Check available storage and try again."
        }
        isRendering = false
    }
}

private enum ShareTheme: String, CaseIterable, Identifiable {
    case standard
    case dusk
    case ocean
    case ember

    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    var isPro: Bool { self != .standard }
    var analyticsTheme: AnalyticsTheme { AnalyticsTheme(rawValue: rawValue) ?? .standard }

    var background: Color {
        switch self {
        case .standard: Color(red: 0.98, green: 0.95, blue: 0.89)
        case .dusk: Color(red: 0.18, green: 0.14, blue: 0.28)
        case .ocean: Color(red: 0.08, green: 0.30, blue: 0.38)
        case .ember: Color(red: 0.42, green: 0.16, blue: 0.08)
        }
    }

    var foreground: Color { self == .standard ? Color(red: 0.17, green: 0.12, blue: 0.09) : .white }
    var accent: Color { self == .standard ? Color(red: 0.66, green: 0.28, blue: 0.11) : Color(red: 1, green: 0.68, blue: 0.36) }
}

private struct ArtifactCanvasView: View {
    let trip: MemoryTrip
    let type: AnalyticsArtifactType
    let theme: ShareTheme
    let privacy: ArtifactPrivacySelection

    var body: some View {
        ZStack {
            theme.background
            if type == .postcard { postcard }
            else { mapCard }
        }
        .clipped()
    }

    private var postcard: some View {
        VStack(alignment: .leading, spacing: 18) {
            if let image = coverImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 355)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 22))
            } else {
                RoundedRectangle(cornerRadius: 22)
                    .fill(theme.accent.opacity(0.23))
                    .frame(height: 355)
                    .overlay {
                        Image(systemName: "map.fill")
                            .font(.system(size: 64, weight: .light))
                            .foregroundStyle(theme.accent)
                    }
            }
            if privacy.includesTitle {
                Text(trip.title)
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.foreground)
                    .lineLimit(2)
            }
            Text(detailLine)
                .font(.system(size: 19, weight: .medium, design: .rounded))
                .foregroundStyle(theme.foreground.opacity(0.76))
                .lineLimit(2)
            if privacy.includesNotes, let note = exportMoments.compactMap(\.noteText).first {
                Text(note)
                    .font(.system(size: 20, design: .rounded))
                    .foregroundStyle(theme.foreground)
                    .lineLimit(3)
            }
            Spacer()
            HStack {
                Image(systemName: "flame.fill")
                Text("Kindled in Kindling")
            }
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundStyle(theme.accent)
        }
        .padding(30)
    }

    private var mapCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            if privacy.includesTitle {
                Text(trip.title)
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.foreground)
            }
            RouteDrawing(moments: exportMoments, color: theme.accent)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(theme.foreground.opacity(0.06), in: RoundedRectangle(cornerRadius: 24))
            Text("Approximate memory path")
                .font(.system(size: 16, design: .rounded))
                .foregroundStyle(theme.foreground.opacity(0.7))
            Text(detailLine)
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundStyle(theme.foreground)
            HStack {
                Image(systemName: "flame.fill")
                Text("Kindled in Kindling")
            }
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundStyle(theme.accent)
        }
        .padding(30)
    }

    private var exportMoments: [MemoryMoment] {
        trip.orderedMoments.filter {
            !$0.isHidden && (privacy.includesSensitiveMoments || !$0.isSensitive)
        }
    }

    private var coverImage: UIImage? {
        let media = exportMoments.flatMap(\.orderedMedia)
        guard let reference = media.first(where: { $0.id == trip.coverMediaReferenceID }) ?? media.first else { return nil }
        if let assetName = reference.bundledAssetName { return UIImage(named: assetName) }
        let path = reference.mediaType == .video ? reference.posterFileRelativePath : reference.importedFileRelativePath
        let directory: MemoryFileStore.Directory = reference.mediaType == .video ? .thumbnails : .media
        guard let path, let url = try? MemoryFileStore.URL(forRelativePath: path, in: directory) else { return nil }
        return UIImage(contentsOfFile: url.path)
    }

    private var detailLine: String {
        var details: [String] = []
        if privacy.includesDates, let start = trip.startDate {
            details.append(start.formatted(.dateTime.month(.wide).year()))
        }
        if privacy.includesPlaces, let place = trip.summaryPlaceText { details.append(place) }
        details.append("\(exportMoments.count) moments")
        return details.joined(separator: " · ")
    }
}

private struct RouteDrawing: View {
    let moments: [MemoryMoment]
    let color: Color

    private var points: [(Double, Double)] {
        moments.compactMap { moment in
            guard let latitude = moment.latitude, let longitude = moment.longitude else { return nil }
            return (latitude, longitude)
        }
    }

    var body: some View {
        Canvas { context, size in
            guard !points.isEmpty else { return }
            let minLat = points.map(\.0).min() ?? 0
            let maxLat = points.map(\.0).max() ?? 1
            let minLon = points.map(\.1).min() ?? 0
            let maxLon = points.map(\.1).max() ?? 1
            func mapped(_ point: (Double, Double)) -> CGPoint {
                let x = (point.1 - minLon) / max(0.001, maxLon - minLon)
                let y = (point.0 - minLat) / max(0.001, maxLat - minLat)
                return CGPoint(x: 35 + x * (size.width - 70), y: size.height - 35 - y * (size.height - 70))
            }
            var path = Path()
            path.move(to: mapped(points[0]))
            for point in points.dropFirst() { path.addLine(to: mapped(point)) }
            context.stroke(path, with: .color(color.opacity(0.8)), style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
            for point in points {
                let center = mapped(point)
                context.fill(Path(ellipseIn: CGRect(x: center.x - 8, y: center.y - 8, width: 16, height: 16)), with: .color(color))
            }
        }
    }
}
