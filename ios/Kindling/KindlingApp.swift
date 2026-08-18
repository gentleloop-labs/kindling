import KindlingCore
import KindlingUI
import SwiftData
import SwiftUI

@main
struct KindlingApp: App {
    /// Built once, from `KindlingCore`, so the app and the widget extension cannot
    /// disagree about where the store lives. If the App Group is misconfigured this
    /// surfaces as a readable message rather than a launch crash — which is exactly
    /// the failure this phase exists to catch.
    private let container: Result<ModelContainer, Error>

    /// Entitlement state, held for the app's lifetime so the paywall check never
    /// waits on the network mid-flow.
    @State private var entitlements = RevenueCatEntitlementStore()

    init() {
        container = Result { try KindlingStore.makeModelContainer() }
        // Configure before any view can ask about entitlements. A missing key is
        // normal during development and simply means "not entitled" everywhere.
        RevenueCatEntitlementStore.configure(
            apiKey: Bundle.main.object(forInfoDictionaryKey: "KindlingRevenueCatKey") as? String ?? ""
        )
    }

    var body: some Scene {
        WindowGroup {
            switch container {
            case .success(let container):
                RootView()
                    .modelContainer(container)
                    .environment(entitlements)
                    .task { await entitlements.refresh() }
            case .failure(let error):
                StoreFailureView(message: String(describing: error))
            }
        }
    }
}
