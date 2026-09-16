import KindlingCore
import KindlingUI
import SwiftData
import SwiftUI

struct RootView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.analyticsTracker) private var analytics
    @AppStorage("kindling.memory.onboarding.completed") private var completedOnboarding = false
    @State private var selectedTab: AppTab = .atlas
    @State private var pendingAction: AtlasAction?
    #if DEBUG
    @State private var debugDraft: MemoryTrip?
    @State private var debugTrail: MemoryTrip?
    @State private var debugMoment: MemoryTrip?
    @State private var debugShare: MemoryTrip?
    @State private var debugPaywall = false
    #endif

    var body: some View {
        TabView(selection: $selectedTab) {
            AtlasScreen(pendingAction: $pendingAction)
                .tabItem { Label("Atlas", systemImage: "map.fill") }
                .tag(AppTab.atlas)

            MemoriesScreen()
                .tabItem { Label("Memories", systemImage: "photo.stack") }
                .tag(AppTab.memories)

            SettingsScreen()
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(AppTab.settings)
        }
        .tint(KindlingColor.accent)
        .fullScreenCover(isPresented: Binding(
            get: { !completedOnboarding },
            set: { if !$0 { completedOnboarding = true } }
        )) {
            MemoryOnboardingScreen { action in
                completedOnboarding = true
                selectedTab = .atlas
                pendingAction = action
                analytics.track(.onboardingCompleted)
            }
        }
        .task {
            ImportRecoveryService.recoverInterruptedImports(in: context)
            analytics.track(.appOpened)
        }
        #if DEBUG
        .task { routeDebugScreenshotIfNeeded() }
        .sheet(item: $debugDraft) { trip in
            NavigationStack {
                DraftReviewScreen(trip: trip, onSaved: {}, onCancel: {})
            }
        }
        .sheet(item: $debugTrail) { trip in
            NavigationStack { MemoryTrailView(trip: trip) }
        }
        .sheet(item: $debugMoment) { trip in
            NavigationStack {
                MemoryTrailView(
                    trip: trip,
                    initialFocusMomentID: trip.orderedMoments.first?.id
                )
            }
        }
        .sheet(item: $debugShare) { trip in
            SharePreviewScreen(trip: trip, initialFocus: .privacy)
        }
        .sheet(isPresented: $debugPaywall) {
            PaywallScreen(source: .settings)
        }
        #endif
    }
}

#if DEBUG
private extension RootView {
    func routeDebugScreenshotIfNeeded() {
        guard let screen = ProcessInfo.processInfo.environment["KINDLING_SCREEN"] else { return }
        switch screen {
        case "onboarding":
            completedOnboarding = false
        case "draft":
            completedOnboarding = true
            let trip = SampleTripFactory.create(in: context)
            trip.status = .draft
            try? context.save()
            debugDraft = trip
        case "atlas":
            completedOnboarding = true
            SampleTripFactory.createScreenshotLibrary(in: context)
            selectedTab = .atlas
        case "trail":
            completedOnboarding = true
            debugTrail = SampleTripFactory.create(in: context)
        case "moment":
            completedOnboarding = true
            debugMoment = SampleTripFactory.create(in: context)
        case "memories":
            completedOnboarding = true
            _ = SampleTripFactory.create(in: context)
            selectedTab = .memories
        case "share":
            completedOnboarding = true
            let trip = SampleTripFactory.create(in: context)
            trip.title = "Lisbon Weekend"
            try? context.save()
            debugShare = trip
        case "paywall":
            completedOnboarding = true
            debugPaywall = true
        default:
            break
        }
    }
}
#endif

enum AtlasAction: String, Identifiable {
    case importPhotos
    case openSample
    var id: String { rawValue }
}

private enum AppTab: Hashable {
    case atlas
    case memories
    case settings
}
