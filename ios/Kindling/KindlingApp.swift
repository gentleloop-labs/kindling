import KindlingCore
import KindlingUI
import SwiftData
import SwiftUI

@main
struct KindlingApp: App {
    @UIApplicationDelegateAdaptor(KindlingAppDelegate.self) private var appDelegate
    /// Built once, from `KindlingCore`, so the app and the widget extension cannot
    /// disagree about where the store lives. If the App Group is misconfigured this
    /// surfaces as a readable message rather than a launch crash — which is exactly
    /// the failure this phase exists to catch.
    private let container: Result<ModelContainer, Error>

    /// Entitlement state, held for the app's lifetime so the paywall check never
    /// waits on the network mid-flow.
    @State private var entitlements = StoreKitEntitlementStore()
    private let analytics: any AnalyticsTracking

    init() {
        container = Result { try KindlingStore.makeModelContainer() }
        let tracker = AnalyticsBootstrap.make()
        analytics = tracker
        AnalyticsRuntime.shared.configure(tracker)
    }

    var body: some Scene {
        WindowGroup {
            switch container {
            case .success(let container):
                RootView()
                    .modelContainer(container)
                    .environment(entitlements)
                    .environment(\.analyticsTracker, analytics)
                    // `start()` also takes the first reading, so this covers both
                    // the launch refresh and the long-lived transaction listener.
                    .task { entitlements.start() }
            case .failure(let error):
                StoreFailureView(message: String(describing: error))
            }
        }
    }
}
