import KindlingCore
import KindlingUI
import SwiftData
import SwiftUI

/// The app shell. Start remains the default destination, while saved tasks and
/// settings are stable places in the tab bar instead of transient sheets. The bar
/// disappears during onboarding and a session so those moments stay single-purpose.
struct RootView: View {
    @Environment(StoreKitEntitlementStore.self) private var entitlements
    @Environment(\.analyticsTracker) private var analytics
    @Query private var tasks: [AvoidedTask]

    @State private var selectedTab: AppTab = .start
    @State private var showingPaywall = false
    @State private var paywallSource: PaywallScreen.Source = .discovery
    @State private var chromeVisible = true
    @State private var requestedTaskID: UUID?
    @State private var releasedTaskID: UUID?
    @State private var newTaskRequest: UUID?
    @State private var aiConfigurationRevision = UUID()

    #if DEBUG
    @State private var showingDebug = false
    #endif

    var body: some View {
        TabView(selection: $selectedTab) {
            startTab
                .toolbar(chromeVisible ? .visible : .hidden, for: .tabBar)
                .toolbarBackground(KindlingColor.background, for: .tabBar)
                .toolbarBackground(chromeVisible ? .visible : .hidden, for: .tabBar)
                .tabItem {
                    Label("Start", systemImage: "flame")
                }
                .tag(AppTab.start)

            TaskShelfScreen(
                onResume: resumeTask,
                onStartNew: attemptStartNewTask,
                onRelease: { releasedTaskID = $0 }
            )
            .tabItem {
                Label("Tasks", systemImage: "square.stack.3d.up")
            }
            .tag(AppTab.tasks)

            SettingsScreen()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(AppTab.settings)
        }
        .tint(KindlingColor.accent)
        .onChange(of: selectedTab) { previous, _ in
            if previous == .settings {
                aiConfigurationRevision = UUID()
            }
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallScreen(source: paywallSource) {
                if paywallSource == .taskShelf {
                    newTaskRequest = UUID()
                    selectedTab = .start
                }
            }
        }
        #if DEBUG
        .task {
            if ProcessInfo.processInfo.environment["KINDLING_OPEN_TASKS"] == "1" {
                selectedTab = .tasks
            }
            if ProcessInfo.processInfo.environment["KINDLING_OPEN_SETTINGS"] == "1" {
                selectedTab = .settings
            }
            if ProcessInfo.processInfo.environment["KINDLING_OPEN_PAYWALL"] == "1" {
                analytics.track(.paywallDisplayed(source: .settings))
                showingPaywall = true
            }
        }
        .sheet(isPresented: $showingDebug) {
            DebugToolsView()
        }
        #endif
    }

    private var startTab: some View {
        RescueFlowView(
            chromeVisible: $chromeVisible,
            requestedTaskID: $requestedTaskID,
            releasedTaskID: $releasedTaskID,
            newTaskRequest: $newTaskRequest,
            aiConfigurationRevision: $aiConfigurationRevision,
            onShowPlus: presentPaywall
        )
            .safeAreaInset(edge: .top, spacing: 0) {
                if chromeVisible {
                    HStack(spacing: Space.s1) {
                        Spacer()

                        #if DEBUG
                        if ProcessInfo.processInfo.environment["KINDLING_SCREEN"] == nil {
                            Button { showingDebug = true } label: {
                                Image(systemName: "hammer")
                                    .kindlingChromeIcon()
                            }
                            .accessibilityLabel("Developer tools")
                        }
                        #endif

                        if entitlements.hasLoadedEntitlements && !entitlements.hasMultiTask {
                            Button { presentPaywall(source: .home) } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "sparkles")
                                    Text("Plus")
                                }
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(KindlingColor.accent)
                                .padding(.horizontal, Space.s1)
                                .frame(height: KindlingLayout.minTapTarget)
                                .contentShape(Rectangle())
                            }
                            .accessibilityLabel("Kindling Plus")
                        }

                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, Space.s3)
                    .frame(height: KindlingLayout.minTapTarget)
                    .background(KindlingColor.background)
                }
            }
    }

    private func resumeTask(_ id: UUID) {
        requestedTaskID = id
        selectedTab = .start
    }

    private func attemptStartNewTask() {
        analytics.track(.secondTaskAttempted)
        let count = ActiveTaskPolicy.currentActiveCount(in: tasks.map(\.status))
        if ActiveTaskPolicy.canStartAnotherTask(
            currentActiveCount: count,
            hasMultiTaskEntitlement: entitlements.hasMultiTask
        ) {
            newTaskRequest = UUID()
            selectedTab = .start
        } else {
            presentPaywall(source: .taskShelf)
        }
    }

    private func presentPaywall(source: AnalyticsPaywallSource) {
        paywallSource = source == .taskShelf ? .taskShelf : .discovery
        analytics.track(.paywallDisplayed(source: source))
        showingPaywall = true
    }
}

private enum AppTab: Hashable {
    case start
    case tasks
    case settings
}

private extension Image {
    /// Normalizes symbols with different intrinsic bounds so the app chrome
    /// reads as one aligned control group instead of two floating glyphs.
    func kindlingChromeIcon() -> some View {
        font(.system(size: 20, weight: .medium))
            .foregroundStyle(KindlingColor.textSecondary)
            .frame(
                width: KindlingLayout.minTapTarget,
                height: KindlingLayout.minTapTarget
            )
            .contentShape(Rectangle())
    }
}

#if DEBUG
/// Kept out of release builds entirely. The design gallery is a living reference for
/// the token system; the store probe is the Phase 1 persistence check.
struct DebugToolsView: View {
    var body: some View {
        TabView {
            DesignGallery()
                .tabItem { Label("Design", systemImage: "paintpalette") }
            PersistenceProbeView()
                .tabItem { Label("Store", systemImage: "internaldrive") }
        }
    }
}
#endif
