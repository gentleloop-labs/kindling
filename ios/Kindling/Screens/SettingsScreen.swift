import KindlingCore
import KindlingUI
import StoreKit
import SwiftData
import SwiftUI

struct SettingsScreen: View {
    @Environment(\.modelContext) private var context
    @Environment(StoreKitEntitlementStore.self) private var entitlements
    @Environment(\.analyticsTracker) private var analytics
    @Query private var trips: [MemoryTrip]

    @State private var notificationsEnabled = false
    @State private var notificationHour = 18
    @State private var showingPaywall = false
    @State private var showingSubscriptionManagement = false
    @State private var isRestoring = false
    @State private var restoreMessage: String?
    @State private var storageText = "Calculating…"
    @State private var legacyDataExists = false
    @State private var showingLegacyDelete = false
    @State private var showingDeleteAll = false
    @State private var exportURL: URL?
    @State private var statusMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if entitlements.hasPro {
                        Label("Kindling Pro is active", systemImage: "checkmark.circle.fill")
                        Button("Manage subscription") { showingSubscriptionManagement = true }
                    } else {
                        Button("Explore Kindling Pro") {
                            analytics.track(.paywallDisplayed(source: .settings))
                            showingPaywall = true
                        }
                    }
                    Button(isRestoring ? "Checking with Apple…" : "Restore purchases") {
                        Task { await restore() }
                    }
                    .disabled(isRestoring)
                    if let restoreMessage { Text(restoreMessage).font(.kindlingCaption) }
                } header: {
                    Text("Kindling Pro")
                } footer: {
                    Text("Your first two saved trips remain free. Existing memories never disappear when a subscription ends.")
                }

                Section {
                    Toggle("Postcards from your past", isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) { _, enabled in
                            Task { await updateNotifications(enabled) }
                        }
                    if notificationsEnabled {
                        Picker("Delivery time", selection: $notificationHour) {
                            ForEach(8..<22) { hour in
                                Text(DateComponents(calendar: .current, hour: hour)
                                    .date?.formatted(date: .omitted, time: .shortened) ?? "\(hour):00")
                                    .tag(hour)
                            }
                        }
                        .onChange(of: notificationHour) { _, value in
                            PreferencesStore(context: context).set(PreferenceKey.quietHoursEnd, "\(value)")
                            Task { try? await MemoryNotificationService.scheduleNextPostcard(hour: value) }
                        }
                    }
                } header: {
                    Text("Resurfacing")
                } footer: {
                    Text("Lock-screen text stays generic. Sensitive, hidden, archived, and excluded memories are never chosen.")
                }

                Section {
                    LabeledContent("Kindling storage", value: storageText)
                    Button("Clear temporary previews and exports") { clearCaches() }
                    if let exportURL {
                        ShareLink(item: exportURL) {
                            Label("Share data export", systemImage: "square.and.arrow.up")
                        }
                    } else {
                        Button("Prepare data export") { prepareExport() }
                    }
                } header: {
                    Text("Storage and export")
                } footer: {
                    Text("Clearing temporary files keeps every trail, note, recording, and imported display copy.")
                }

                if legacyDataExists {
                    Section {
                        Text("A previous development or TestFlight version left retired data on this device. It is not shown or used by this app.")
                            .font(.kindlingCaption)
                        Button("Keep it for now") {
                            PreferencesStore(context: context).set(PreferenceKey.legacyDataDecision, "keep")
                            statusMessage = "Previous data remains stored locally."
                        }
                        Button("Permanently delete previous data") { showingLegacyDelete = true }
                    } header: {
                        Text("Previous Kindling Data")
                    }
                }

                Section {
                    Link("Privacy policy", destination: URL(string: "https://kindling.gentlelooplabs.com/privacy/")!)
                    Link("Terms of use", destination: URL(string: "https://kindling.gentlelooplabs.com/terms/")!)
                    Link("Support", destination: URL(string: "https://kindling.gentlelooplabs.com/support/")!)
                    Button("Delete all Kindling data") { showingDeleteAll = true }
                } header: {
                    Text("Privacy")
                } footer: {
                    Text("No account. No advertising profile. Your selected media and memory text are not sent to analytics.")
                }

                if let statusMessage {
                    Section { Text(statusMessage).font(.kindlingCaption) }
                }

                Section("About") {
                    LabeledContent("Version", value: versionText)
                    Text("Made for memories that deserve more than a camera roll.")
                        .font(.kindlingCaption)
                }
            }
            .navigationTitle("Settings")
        }
        .task { load() }
        .sheet(isPresented: $showingPaywall) { PaywallScreen(source: .settings) }
        .manageSubscriptionsSheet(isPresented: $showingSubscriptionManagement)
        .alert("Delete previous Kindling data?", isPresented: $showingLegacyDelete) {
            Button("Keep it") {}
            Button("Delete") { deleteLegacyData() }
        } message: {
            Text("This cannot be undone. It does not affect memory trails or your Photos library.")
        }
        .alert("Delete all Kindling data?", isPresented: $showingDeleteAll) {
            Button("Keep everything") {}
            Button("Delete everything") { deleteAllData() }
        } message: {
            Text("Every trail, imported display copy, recording, tag, and generated card will be permanently removed. Your Photos library is unchanged.")
        }
    }

    private var versionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
        return "\(version) (\(build))"
    }

    private func load() {
        let preferences = PreferencesStore(context: context)
        notificationsEnabled = preferences.bool(PreferenceKey.notificationsOptIn, default: false)
        notificationHour = Int(preferences.value(PreferenceKey.quietHoursEnd) ?? "18") ?? 18
        legacyDataExists = LegacyDataService().hasLegacyData()
        refreshStorage()
    }

    private func updateNotifications(_ enabled: Bool) async {
        let preferences = PreferencesStore(context: context)
        if enabled {
            let granted = await MemoryNotificationService.requestAuthorization()
            analytics.track(.notificationPermission(granted ? .allowed : .declined))
            notificationsEnabled = granted
            preferences.set(PreferenceKey.notificationsOptIn, granted)
            if granted {
                try? await MemoryNotificationService.scheduleNextPostcard(hour: notificationHour)
                analytics.track(.resurfacingEnabled)
            }
        } else {
            preferences.set(PreferenceKey.notificationsOptIn, false)
            MemoryNotificationService.cancelPostcards()
        }
    }

    private func restore() async {
        analytics.track(.restoreStarted)
        isRestoring = true
        let result = await entitlements.restore()
        isRestoring = false
        switch result {
        case .restored:
            analytics.track(.restoreCompleted)
            restoreMessage = "Your purchase is back."
        case .nothingToRestore: restoreMessage = "Nothing to restore on this Apple ID."
        case .failed: restoreMessage = "That didn't work. Check your connection and try again."
        }
    }

    private func clearCaches() {
        for directory in [MemoryFileStore.Directory.thumbnails, .exports] {
            guard let root = try? MemoryFileStore.baseURL(for: directory),
                  let contents = try? FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)
            else { continue }
            for url in contents { try? FileManager.default.removeItem(at: url) }
        }
        for trip in trips { trip.artifacts.removeAll() }
        try? context.save()
        statusMessage = "Temporary previews and exports were cleared."
        refreshStorage()
    }

    private func refreshStorage() {
        let bytes = [
            MemoryFileStore.directorySize(.media),
            MemoryFileStore.directorySize(.voice),
            MemoryFileStore.directorySize(.thumbnails),
            MemoryFileStore.directorySize(.exports)
        ].reduce(0, +)
        storageText = ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    private func prepareExport() {
        let snapshot = MemoryExportSnapshot(
            exportedAt: .now,
            trips: trips.filter { $0.source != .sample }.map(MemoryExportTrip.init)
        )
        do {
            let data = try JSONEncoder.pretty.encode(snapshot)
            let url = FileManager.default.temporaryDirectory.appending(path: "Kindling-memory-export.json")
            try data.write(to: url, options: .atomic)
            exportURL = url
            statusMessage = "Your private JSON export is ready to share or save."
        } catch {
            statusMessage = "The export could not be prepared. Try again after checking available storage."
        }
    }

    private func deleteLegacyData() {
        do {
            try LegacyDataService().deleteLegacyData()
            legacyDataExists = false
            PreferencesStore(context: context).set(PreferenceKey.legacyDataDecision, "deleted")
            statusMessage = "Previous Kindling data was permanently deleted."
        } catch {
            statusMessage = "Previous data could not be deleted. Try again after restarting the app."
        }
    }

    private func deleteAllData() {
        for trip in trips { MemoryDeletionService.delete(trip, from: context) }
        for directory in MemoryFileStore.Directory.allCases {
            guard let root = try? MemoryFileStore.baseURL(for: directory),
                  let contents = try? FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)
            else { continue }
            for url in contents { try? FileManager.default.removeItem(at: url) }
        }
        analytics.track(.allDataDeleted)
        statusMessage = "All Kindling memory data was deleted."
        refreshStorage()
    }
}

private struct MemoryExportSnapshot: Codable {
    let exportedAt: Date
    let trips: [MemoryExportTrip]
}

private struct MemoryExportTrip: Codable {
    let id: UUID
    let title: String
    let startDate: Date?
    let endDate: Date?
    let summaryPlace: String?
    let isFavorite: Bool
    let moments: [MemoryExportMoment]

    init(_ trip: MemoryTrip) {
        id = trip.id
        title = trip.title
        startDate = trip.startDate
        endDate = trip.endDate
        summaryPlace = trip.summaryPlaceText
        isFavorite = trip.isFavorite
        moments = trip.orderedMoments.map(MemoryExportMoment.init)
    }
}

private struct MemoryExportMoment: Codable {
    let id: UUID
    let title: String?
    let capturedAt: Date?
    let place: String?
    let note: String?
    let returnIntent: String?
    let tags: [String]
    let prompts: [String: String]

    init(_ moment: MemoryMoment) {
        id = moment.id
        title = moment.title
        capturedAt = moment.capturedAt
        place = moment.displayPlace
        note = moment.noteText
        returnIntent = moment.returnIntentRaw
        tags = moment.tags.map(\.name)
        prompts = Dictionary(uniqueKeysWithValues: moment.promptResponses.compactMap {
            guard let response = $0.responseText else { return nil }
            return ($0.promptTextSnapshot, response)
        })
    }
}

private extension JSONEncoder {
    static var pretty: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

private extension MemoryFileStore.Directory {
    static var allCases: [Self] { [.media, .voice, .thumbnails, .exports] }
}
