import KindlingCore
import KindlingUI
import SwiftData
import SwiftUI

struct DraftReviewScreen: View {
    @Bindable var trip: MemoryTrip
    let onSaved: () -> Void
    let onCancel: () -> Void

    @Environment(\.modelContext) private var context
    @Environment(\.analyticsTracker) private var analytics
    @Environment(StoreKitEntitlementStore.self) private var entitlements
    @Query private var allTrips: [MemoryTrip]
    @State private var showingPaywall = false
    @State private var showingCancelConfirmation = false
    @State private var validationMessage: String?

    var body: some View {
        List {
            Section {
                HStack(spacing: Space.s2) {
                    EmberView(state: .arranging, size: 58)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your trail is ready to shape")
                            .font(.kindlingButton)
                            .foregroundStyle(KindlingColor.textPrimary)
                        Text("\(allMedia.count) photos · \(trip.moments.count) editable moments")
                            .font(.kindlingCaption)
                            .foregroundStyle(KindlingColor.textSecondary)
                    }
                }
                .padding(.vertical, 4)
            } footer: {
                Text("Kindling groups nearby photos by time and place. Everything below stays editable.")
            }

            Section {
                TextField("Trip title", text: $trip.title)
                    .font(.kindlingTitle)
                DatePicker("Started", selection: startDate, displayedComponents: .date)
                DatePicker("Ended", selection: endDate, displayedComponents: .date)
            } header: {
                Text("About this trip")
            }

            if !allMedia.isEmpty {
                Section("Choose a cover") {
                    ScrollView(.horizontal) {
                        HStack(spacing: Space.s1) {
                            ForEach(allMedia) { media in
                                Button {
                                    trip.coverMediaReferenceID = media.id
                                    autosave()
                                } label: {
                                    MemoryMediaView(reference: media, height: 90)
                                        .frame(width: 110)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .overlay {
                                            if trip.coverMediaReferenceID == media.id {
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(KindlingColor.focus, lineWidth: 3)
                                            }
                                        }
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Use as trip cover")
                                .accessibilityValue(trip.coverMediaReferenceID == media.id ? "Selected" : "Not selected")
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                }
            }

            Section {
                MemoryMapView(moments: trip.orderedMoments, interactive: false)
                    .frame(height: 210)
                    .listRowInsets(EdgeInsets())
            } header: {
                Text("Map preview")
            }

            Section {
                ForEach(Array(trip.orderedMoments.enumerated()), id: \.element.id) { index, moment in
                    MomentDraftRow(
                        moment: moment,
                        index: index,
                        canMerge: index > 0,
                        canSplit: moment.mediaReferences.count > 1,
                        onMerge: { mergeMoment(at: index) },
                        onSplit: { splitMoment(at: index) },
                        onRemove: { removeMoment(moment) }
                    )
                }
                .onMove(perform: moveMoments)
            } header: {
                HStack {
                    Text("Moments")
                    Spacer()
                    EditButton()
                }
            } footer: {
                Text("Everything is editable. Reorder, combine, split, or remove suggestions before saving.")
            }

            if let validationMessage {
                Text(validationMessage)
                    .font(.kindlingCaption)
                    .foregroundStyle(KindlingColor.textPrimary)
            }

            Section {
                Button("Save memory trail") { attemptSave() }
                    .buttonStyle(.kindlingPrimary)
                    .listRowInsets(EdgeInsets())
                Button("Cancel import") { showingCancelConfirmation = true }
                    .buttonStyle(.kindlingSecondary)
                    .listRowInsets(EdgeInsets(top: Space.s1, leading: 0, bottom: 0, trailing: 0))
            }
        }
        .scrollContentBackground(.hidden)
        .background(KindlingColor.background)
        .navigationTitle("Review your trail")
        .navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled()
        .onChange(of: trip.title) { _, _ in autosave() }
        .sheet(isPresented: $showingPaywall) {
            PaywallScreen(source: .thirdTrip) { completeSave() }
        }
        .alert("Cancel this import?", isPresented: $showingCancelConfirmation) {
            Button("Keep reviewing") {}
            Button("Cancel import") { onCancel() }
        } message: {
            Text("The draft and Kindling's optimized copies will be removed. Your Photos library is never changed.")
        }
    }

    private var allMedia: [MediaReference] { trip.orderedMoments.flatMap(\.orderedMedia) }

    private var completedUserTripCount: Int {
        allTrips.filter { $0.status == .complete && $0.source != .sample && $0.id != trip.id }.count
    }

    private var startDate: Binding<Date> {
        Binding(
            get: { trip.startDate ?? Date() },
            set: { trip.startDate = $0; autosave() }
        )
    }

    private var endDate: Binding<Date> {
        Binding(
            get: { trip.endDate ?? trip.startDate ?? Date() },
            set: { trip.endDate = $0; autosave() }
        )
    }

    private func attemptSave() {
        let title = trip.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else {
            validationMessage = "Give this trail a short title before saving."
            return
        }
        guard !trip.moments.isEmpty else {
            validationMessage = "Keep at least one moment in the trail."
            return
        }
        analytics.track(.thirdTripSaveAttempted)
        if TripLimitPolicy.canSaveTrip(
            completedTripCount: completedUserTripCount,
            hasPro: entitlements.hasPro
        ) {
            completeSave()
        } else {
            analytics.track(.paywallDisplayed(source: .thirdTrip))
            showingPaywall = true
        }
    }

    private func completeSave() {
        trip.title = trip.title.trimmingCharacters(in: .whitespacesAndNewlines)
        trip.status = .complete
        trip.updatedAt = .now
        ImportRecoveryService.markDraft(trip.id, as: .saved, in: context)
        try? context.save()
        analytics.track(.draftSaved)
        onSaved()
    }

    private func autosave() {
        trip.updatedAt = .now
        try? context.save()
    }

    private func moveMoments(from offsets: IndexSet, to destination: Int) {
        var ordered = trip.orderedMoments
        ordered.move(fromOffsets: offsets, toOffset: destination)
        for (index, moment) in ordered.enumerated() { moment.sortIndex = index }
        autosave()
    }

    private func mergeMoment(at index: Int) {
        let ordered = trip.orderedMoments
        guard index > 0, index < ordered.count else { return }
        let previous = ordered[index - 1]
        let current = ordered[index]
        let start = previous.mediaReferences.count
        for (offset, media) in current.orderedMedia.enumerated() {
            media.sortIndex = start + offset
            media.moment = previous
            previous.mediaReferences.append(media)
        }
        if let note = current.noteText, !note.isEmpty {
            previous.noteText = [previous.noteText, note].compactMap { $0 }.joined(separator: "\n\n")
        }
        context.delete(current)
        normalizeSortIndexes()
        autosave()
    }

    private func splitMoment(at index: Int) {
        let ordered = trip.orderedMoments
        guard index < ordered.count else { return }
        let original = ordered[index]
        let media = original.orderedMedia
        guard media.count > 1 else { return }
        let splitIndex = media.count / 2
        let newMoment = MemoryMoment(
            title: original.title,
            capturedAt: media[splitIndex].creationDate,
            latitude: media[splitIndex].latitude,
            longitude: media[splitIndex].longitude,
            placeName: original.placeName,
            sortIndex: index + 1
        )
        trip.moments.append(newMoment)
        for (offset, reference) in media[splitIndex...].enumerated() {
            reference.sortIndex = offset
            reference.moment = newMoment
            newMoment.mediaReferences.append(reference)
        }
        for (offset, reference) in media[..<splitIndex].enumerated() { reference.sortIndex = offset }
        normalizeSortIndexes(inserting: newMoment, after: original)
        autosave()
    }

    private func removeMoment(_ moment: MemoryMoment) {
        for media in moment.mediaReferences {
            MemoryFileStore.remove(relativePath: media.importedFileRelativePath, from: .media)
            MemoryFileStore.remove(relativePath: media.posterFileRelativePath, from: .thumbnails)
        }
        context.delete(moment)
        normalizeSortIndexes()
        autosave()
    }

    private func normalizeSortIndexes(inserting inserted: MemoryMoment? = nil, after anchor: MemoryMoment? = nil) {
        var ordered = trip.orderedMoments.filter { $0.id != inserted?.id }
        if let inserted, let anchor, let anchorIndex = ordered.firstIndex(where: { $0.id == anchor.id }) {
            ordered.insert(inserted, at: anchorIndex + 1)
        }
        for (index, moment) in ordered.enumerated() { moment.sortIndex = index }
    }
}

private struct MomentDraftRow: View {
    @Bindable var moment: MemoryMoment
    let index: Int
    let canMerge: Bool
    let canSplit: Bool
    let onMerge: () -> Void
    let onSplit: () -> Void
    let onRemove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Space.s1) {
            HStack {
                Text("Moment \(index + 1)")
                    .font(.kindlingCaption)
                    .foregroundStyle(KindlingColor.textSecondary)
                Spacer()
                Text("\(moment.mediaReferences.count) item(s)")
                    .font(.kindlingCaption)
                    .foregroundStyle(KindlingColor.textSecondary)
            }
            MemoryMediaView(reference: moment.orderedMedia.first, height: 132)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            TextField("Moment title", text: Binding(
                get: { moment.title ?? "" },
                set: { moment.title = $0.isEmpty ? nil : $0; moment.updatedAt = .now }
            ))
            TextField("Place", text: Binding(
                get: { moment.placeName ?? moment.locality ?? "" },
                set: {
                    moment.placeName = $0.isEmpty ? nil : $0
                    moment.placeSource = .user
                    moment.updatedAt = .now
                }
            ))
            .font(.kindlingCaption)
            HStack {
                if canMerge { Button("Merge above", action: onMerge) }
                if canSplit { Button("Split", action: onSplit) }
                Spacer()
                Button("Remove", action: onRemove)
            }
            .font(.kindlingCaption)
            .foregroundStyle(KindlingColor.accent)
        }
        .padding(.vertical, 4)
    }
}
