import KindlingCore
import KindlingUI
import SwiftData
import SwiftUI

struct MemoryTrailView: View {
    @Bindable var trip: MemoryTrip
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.analyticsTracker) private var analytics
    @State private var selectedMomentID: UUID?
    @State private var showingShare = false
    @State private var showingDeleteConfirmation = false

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Space.s3) {
                hero
                if trip.orderedMoments.contains(where: { $0.latitude != nil && $0.longitude != nil }) {
                    VStack(alignment: .leading, spacing: Space.s1) {
                        Text("Memory map")
                            .font(.kindlingButton)
                            .foregroundStyle(KindlingColor.textPrimary)
                        MemoryMapView(
                            moments: trip.orderedMoments,
                            selectedMomentID: selectedMomentID,
                            onSelect: { selectedMomentID = $0.id }
                        )
                        .frame(height: 280)
                        .clipShape(RoundedRectangle(cornerRadius: KindlingLayout.radius))
                    }
                }

                VStack(alignment: .leading, spacing: Space.s2) {
                    Text("Your trail")
                        .font(.kindlingButton)
                        .foregroundStyle(KindlingColor.textPrimary)
                    ForEach(Array(trip.orderedMoments.enumerated()), id: \.element.id) { index, moment in
                        MomentMemoryCard(moment: moment, index: index)
                            .id(moment.id)
                            .overlay {
                                if selectedMomentID == moment.id {
                                    RoundedRectangle(cornerRadius: KindlingLayout.radius)
                                        .stroke(KindlingColor.focus, lineWidth: 2)
                                }
                            }
                    }
                }
            }
            .padding(Space.s3)
        }
        .background(KindlingColor.background)
        .navigationTitle(trip.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    analytics.track(.recapPreviewed(type: .postcard))
                    showingShare = true
                } label: {
                    Label("Create a postcard", systemImage: "square.and.arrow.up")
                }
                Menu {
                    Button(trip.isFavorite ? "Remove favorite" : "Favorite") {
                        trip.isFavorite.toggle(); save()
                    }
                    Button(trip.status == .archived ? "Unarchive" : "Archive") {
                        trip.status = trip.status == .archived ? .complete : .archived
                        save()
                    }
                    Button("Delete trail") { showingDeleteConfirmation = true }
                } label: {
                    Label("More", systemImage: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingShare) {
            SharePreviewScreen(trip: trip)
        }
        .alert("Delete this memory trail?", isPresented: $showingDeleteConfirmation) {
            Button("Keep trail") {}
            Button("Delete") {
                MemoryDeletionService.delete(trip, from: context)
                analytics.track(.tripDeleted)
                dismiss()
            }
        } message: {
            Text("Kindling's copies, notes, recordings, and exports will be removed. Your Photos library is unchanged.")
        }
        .task { analytics.track(.memoryTrailViewed) }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: Space.s2) {
            MemoryMediaView(reference: cover, height: 270, showsPlayback: true)
                .clipShape(RoundedRectangle(cornerRadius: KindlingLayout.radius))
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(trip.title)
                        .font(.kindlingTitle)
                        .foregroundStyle(KindlingColor.textPrimary)
                    Text(summaryLine)
                        .font(.kindlingBody)
                        .foregroundStyle(KindlingColor.textSecondary)
                }
                Spacer()
                EmberView(state: .remembering, size: 54)
            }
        }
    }

    private var cover: MediaReference? {
        let media = trip.orderedMoments.flatMap(\.orderedMedia)
        return media.first(where: { $0.id == trip.coverMediaReferenceID }) ?? media.first
    }

    private var summaryLine: String {
        let dates: String? = trip.startDate.map { start in
            if let end = trip.endDate, !Calendar.current.isDate(start, inSameDayAs: end) {
                return "\(start.formatted(.dateTime.month(.wide).day()))–\(end.formatted(.dateTime.month(.wide).day().year()))"
            }
            return start.formatted(.dateTime.month(.wide).day().year())
        }
        return [dates, trip.summaryPlaceText].compactMap { $0 }.joined(separator: " · ")
    }

    private func save() {
        trip.updatedAt = .now
        try? context.save()
    }
}

private struct MomentMemoryCard: View {
    @Bindable var moment: MemoryMoment
    let index: Int
    @Environment(\.modelContext) private var context
    @Environment(\.analyticsTracker) private var analytics
    @State private var voice = VoiceNoteService()
    @State private var sparkResponse = ""
    @State private var tagText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: Space.s2) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(moment.title?.isEmpty == false ? moment.title! : "Moment \(index + 1)")
                        .font(.kindlingButton)
                        .foregroundStyle(KindlingColor.textPrimary)
                    HStack(spacing: 5) {
                        if let date = moment.capturedAt {
                            Text(date.formatted(.dateTime.month(.abbreviated).day().hour().minute()))
                        }
                        if let place = moment.displayPlace {
                            Text("·")
                            Text(place)
                        }
                    }
                    .font(.kindlingCaption)
                    .foregroundStyle(KindlingColor.textSecondary)
                }
                Spacer()
                Menu {
                    Toggle("Sensitive", isOn: $moment.isSensitive)
                    Toggle("Hide from trail", isOn: $moment.isHidden)
                    Toggle("Do not resurface", isOn: $moment.doNotResurface)
                } label: {
                    Image(systemName: "ellipsis")
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Memory privacy options")
            }

            if !moment.orderedMedia.isEmpty {
                ScrollView(.horizontal) {
                    HStack(spacing: Space.s1) {
                        ForEach(moment.orderedMedia) { media in
                            MemoryMediaView(reference: media, height: 210, showsPlayback: true)
                                .frame(width: 280)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .scrollIndicators(.hidden)
            } else {
                MemoryMediaView(reference: nil, height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("What you remember")
                    .font(.kindlingCaption)
                    .foregroundStyle(KindlingColor.textSecondary)
                TextEditor(text: Binding(
                    get: { moment.noteText ?? "" },
                    set: { moment.noteText = $0.isEmpty ? nil : $0; persist() }
                ))
                .frame(minHeight: 74)
                .padding(6)
                .background(KindlingColor.background, in: RoundedRectangle(cornerRadius: 10))
                .accessibilityLabel("Memory note")
            }

            SparkResponseView(moment: moment)
            voiceNotes
            returnIntent
            tags
        }
        .padding(Space.s2)
        .background(KindlingColor.surface, in: RoundedRectangle(cornerRadius: KindlingLayout.radius))
        .onChange(of: moment.isSensitive) { _, _ in persist() }
        .onChange(of: moment.isHidden) { _, _ in persist() }
        .onChange(of: moment.doNotResurface) { _, _ in persist() }
    }

    private var voiceNotes: some View {
        VStack(alignment: .leading, spacing: Space.s1) {
            ForEach(moment.voiceNotes) { note in
                HStack {
                    Button {
                        if voice.state == .playing { voice.stopPlayback() }
                        else { voice.play(note) }
                    } label: {
                        Label(
                            voice.state == .playing ? "Stop" : "Play voice memory",
                            systemImage: voice.state == .playing ? "stop.fill" : "play.fill"
                        )
                    }
                    Spacer()
                    Text(note.durationSeconds.formatted(.number.precision(.fractionLength(0))) + "s")
                        .font(.kindlingCaption)
                    Button("Delete") { voice.delete(note, from: context) }
                        .font(.kindlingCaption)
                }
            }

            switch voice.state {
            case .recording, .paused:
                HStack {
                    Text(voice.elapsed.formatted(.number.precision(.fractionLength(0))) + "s / 120s")
                        .font(.kindlingCaption)
                    Spacer()
                    Button(voice.state == .paused ? "Resume" : "Pause") { voice.pauseOrResume() }
                    Button("Save") {
                        if let note = voice.finish(for: moment, in: context) {
                            analytics.track(.voiceNoteCreated(
                                duration: AnalyticsVoiceDurationBucket(seconds: note.durationSeconds)
                            ))
                        }
                    }
                    Button("Discard") { voice.discardRecording() }
                }
            default:
                Button {
                    Task { await voice.begin() }
                } label: {
                    Label("Add a voice memory", systemImage: "waveform")
                }
            }

            if voice.state == .permissionDenied {
                Text("Microphone access is off. You can keep using text notes, or enable the microphone in Settings.")
                    .font(.kindlingCaption)
                    .foregroundStyle(KindlingColor.textSecondary)
            }
        }
        .font(.kindlingCaption)
    }

    private var returnIntent: some View {
        Picker("Would you return?", selection: Binding(
            get: { moment.returnIntentRaw ?? "unset" },
            set: { moment.returnIntentRaw = $0 == "unset" ? nil : $0; persist() }
        )) {
            Text("Not answered").tag("unset")
            ForEach(ReturnIntent.allCases, id: \.rawValue) { intent in
                Text(intent.label).tag(intent.rawValue)
            }
        }
        .pickerStyle(.menu)
    }

    private var tags: some View {
        VStack(alignment: .leading, spacing: 5) {
            if !moment.tags.isEmpty {
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(moment.tags) { tag in
                            Text(tag.name)
                                .font(.kindlingCaption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(KindlingColor.surfaceStrong, in: Capsule())
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
            HStack {
                TextField("Private tag", text: $tagText)
                    .textInputAutocapitalization(.words)
                Button("Add") {
                    let name = tagText.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !name.isEmpty else { return }
                    moment.tags.append(PrivateTag(name: name))
                    tagText = ""
                    persist()
                }
                .disabled(tagText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .font(.kindlingCaption)
        }
    }

    private func persist() {
        moment.updatedAt = .now
        moment.trip?.updatedAt = .now
        try? context.save()
    }
}

private struct SparkResponseView: View {
    @Bindable var moment: MemoryMoment
    @Environment(\.modelContext) private var context
    @Environment(\.analyticsTracker) private var analytics
    @State private var response = ""
    @State private var spark: Spark?

    var body: some View {
        if let spark {
            VStack(alignment: .leading, spacing: Space.s1) {
                Label("A small spark", systemImage: "sparkles")
                    .font(.kindlingCaption)
                    .foregroundStyle(KindlingColor.accent)
                Text(spark.text)
                    .font(.kindlingBody)
                    .foregroundStyle(KindlingColor.textPrimary)
                TextField("Add a detail, or skip", text: $response, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                HStack {
                    Button("Skip") { record(state: .skipped, text: nil) }
                    Spacer()
                    Button("Save detail") { record(state: .answered, text: response) }
                        .disabled(response.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .font(.kindlingCaption)
            }
            .padding(Space.s1)
            .background(KindlingColor.surfaceStrong, in: RoundedRectangle(cornerRadius: 10))
        }
        ForEach(moment.promptResponses.filter { $0.state == .answered }) { answer in
            VStack(alignment: .leading, spacing: 3) {
                Text(answer.promptTextSnapshot)
                    .font(.kindlingCaption)
                    .foregroundStyle(KindlingColor.textSecondary)
                if let text = answer.responseText { Text(text).font(.kindlingBody) }
            }
        }
        .task { chooseSpark() }
    }

    private func chooseSpark() {
        let answered = Set(moment.promptResponses.map(\.promptKey))
        let skippedFamilies: Set<SparkFamily> = Set(moment.promptResponses.compactMap { response in
            guard response.state == .skipped else { return nil }
            return SparkSelector.launchLibrary.first(where: { $0.key == response.promptKey })?.family
        })
        spark = SparkSelector().next(
            for: moment.id,
            excludingFamilies: skippedFamilies,
            answeredKeys: answered
        )
        if let spark { analytics.track(.sparkPresented(family: spark.family)) }
    }

    private func record(state: PromptResponseState, text: String?) {
        guard let spark else { return }
        let record = PromptResponse(
            promptKey: spark.key,
            promptVersion: spark.version,
            promptTextSnapshot: spark.text,
            responseText: text?.trimmingCharacters(in: .whitespacesAndNewlines),
            state: state
        )
        moment.promptResponses.append(record)
        moment.updatedAt = .now
        try? context.save()
        if state == .answered { analytics.track(.sparkAnswered(family: spark.family)) }
        else { analytics.track(.sparkSkipped(family: spark.family)) }
        response = ""
        chooseSpark()
    }
}
