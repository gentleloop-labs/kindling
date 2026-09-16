import KindlingCore
import KindlingUI
import PhotosUI
import SwiftData
import SwiftUI

struct AtlasScreen: View {
    @Binding var pendingAction: AtlasAction?
    @Environment(\.modelContext) private var context
    @Environment(\.analyticsTracker) private var analytics
    @Query(sort: \MemoryTrip.updatedAt, order: .reverse) private var trips: [MemoryTrip]

    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var importItems: [PhotosPickerItem] = []
    @State private var showingPicker = false
    @State private var showingImport = false
    @State private var presentedTrip: MemoryTrip?
    @State private var presentedDraft: MemoryTrip?

    private var completedTrips: [MemoryTrip] {
        trips.filter { $0.status == .complete }
    }

    private var drafts: [MemoryTrip] {
        trips.filter { $0.status == .draft && !$0.moments.isEmpty }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: Space.s3) {
                    header
                    if let draft = drafts.first {
                        draftCard(draft)
                    }
                    if let postcardTrip = completedTrips.first(where: {
                        $0.source != .sample && !$0.isSensitive && !$0.orderedMoments.allSatisfy(\.doNotResurface)
                    }) {
                        postcard(trip: postcardTrip)
                    }
                    if completedTrips.isEmpty {
                        emptyState
                    } else {
                        tripGrid
                    }
                }
                .padding(Space.s3)
            }
            .background(KindlingColor.background)
            .navigationTitle("Your Atlas")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        analytics.track(.photoPickerOpened)
                        showingPicker = true
                    } label: {
                        Label("Add a trip", systemImage: "plus")
                    }
                }
            }
            .photosPicker(
                isPresented: $showingPicker,
                selection: $pickerItems,
                maxSelectionCount: 500,
                matching: .any(of: [.images, .videos]),
                preferredItemEncoding: .current
            )
            .onChange(of: pickerItems) { _, items in
                guard !items.isEmpty else { return }
                analytics.track(.photoSelectionCompleted(count: AnalyticsCountBucket(items.count)))
                importItems = items
                pickerItems = []
                showingImport = true
            }
            .sheet(isPresented: $showingImport) {
                ImportFlowView(items: importItems)
                    .interactiveDismissDisabled()
            }
            .sheet(item: $presentedTrip) { trip in
                NavigationStack { MemoryTrailView(trip: trip) }
            }
            .sheet(item: $presentedDraft) { trip in
                NavigationStack {
                    DraftReviewScreen(
                        trip: trip,
                        onSaved: { presentedDraft = nil },
                        onCancel: {
                            ImportRecoveryService.markDraft(trip.id, as: .cancelled, in: context)
                            MemoryDeletionService.delete(trip, from: context)
                            presentedDraft = nil
                        }
                    )
                }
                .interactiveDismissDisabled()
            }
            .onChange(of: pendingAction?.id, initial: true) { _, _ in
                handlePendingAction()
            }
        }
    }

    private var header: some View {
        HStack(spacing: Space.s2) {
            EmberView(state: completedTrips.isEmpty ? .welcoming : .remembering, size: 62)
            VStack(alignment: .leading, spacing: 4) {
                Text(completedTrips.isEmpty ? "Your memories have somewhere to land." : "Where life happened")
                    .font(.kindlingButton)
                    .foregroundStyle(KindlingColor.textPrimary)
                Text(completedTrips.isEmpty ? "Start with photos you already have." : "\(completedTrips.count) trails, ready whenever you are.")
                    .font(.kindlingCaption)
                    .foregroundStyle(KindlingColor.textSecondary)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: Space.s3) {
            ContentUnavailableView(
                "Build your first trail",
                systemImage: "map",
                description: Text("Choose a past trip. Kindling groups the photos into moments you can edit.")
            )
            Button("Choose photos") {
                analytics.track(.photoPickerOpened)
                showingPicker = true
            }
            .buttonStyle(.kindlingPrimary)
            Button("Explore the sample trip") { openSample() }
                .buttonStyle(.kindlingSecondary)
        }
        .padding(.vertical, Space.s4)
    }

    private func draftCard(_ trip: MemoryTrip) -> some View {
        Button { presentedDraft = trip } label: {
            HStack(spacing: Space.s2) {
                Image(systemName: "square.and.pencil")
                    .font(.title2)
                    .foregroundStyle(KindlingColor.accent)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Continue arranging your trail")
                        .font(.kindlingButton)
                        .foregroundStyle(KindlingColor.textPrimary)
                    Text(trip.title)
                        .font(.kindlingCaption)
                        .foregroundStyle(KindlingColor.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(KindlingColor.textSecondary)
            }
            .padding(Space.s2)
            .background(KindlingColor.surfaceStrong, in: RoundedRectangle(cornerRadius: KindlingLayout.radius))
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens the autosaved draft")
    }

    private var tripGrid: some View {
        VStack(alignment: .leading, spacing: Space.s2) {
            Text("Memory trails")
                .font(.kindlingButton)
                .foregroundStyle(KindlingColor.textPrimary)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 155), spacing: Space.s2)], spacing: Space.s2) {
                ForEach(completedTrips) { trip in
                    NavigationLink {
                        MemoryTrailView(trip: trip)
                    } label: {
                        TripCardView(trip: trip)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func postcard(trip: MemoryTrip) -> some View {
        Button {
            analytics.track(.postcardOpened)
            presentedTrip = trip
        } label: {
            HStack(spacing: Space.s2) {
                Image(systemName: "envelope.open.fill")
                    .font(.title2)
                    .foregroundStyle(KindlingColor.accent)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Postcard from your past")
                        .font(.kindlingButton)
                        .foregroundStyle(KindlingColor.textPrimary)
                    Text(trip.title)
                        .font(.kindlingCaption)
                        .foregroundStyle(KindlingColor.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(KindlingColor.textSecondary)
            }
            .padding(Space.s2)
            .background(KindlingColor.surfaceStrong, in: RoundedRectangle(cornerRadius: KindlingLayout.radius))
        }
        .buttonStyle(.plain)
        .task { analytics.track(.postcardPresented) }
    }

    private func handlePendingAction() {
        guard let action = pendingAction else { return }
        pendingAction = nil
        switch action {
        case .importPhotos:
            analytics.track(.photoPickerOpened)
            showingPicker = true
        case .openSample:
            openSample()
        }
    }

    private func openSample() {
        let sample = SampleTripFactory.create(in: context)
        analytics.track(.sampleTripOpened)
        presentedTrip = sample
    }
}
