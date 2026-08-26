import KindlingCore
import KindlingUI
import SwiftData
import SwiftUI

/// The app shell.
///
/// The rescue flow is the whole app — there is no tab bar, no home screen, and no
/// dashboard, because every one of those would be a screen that does not get someone
/// into a first step faster. Settings sits behind a single unobtrusive control, and
/// that control **disappears during a session**: mid-session the screen offers the
/// step, the timer, and Stop, and nothing else to look at.
struct RootView: View {
    @Environment(StoreKitEntitlementStore.self) private var entitlements
    @Environment(\.analyticsTracker) private var analytics
    @Query private var tasks: [AvoidedTask]

    @State private var showingSettings = false
    @State private var showingTasks = false
    @State private var showingPaywall = false
    @State private var chromeVisible = true
    @State private var requestedTaskID: UUID?
    @State private var releasedTaskID: UUID?
    @State private var newTaskRequest: UUID?
    @State private var aiConfigurationRevision = UUID()

    #if DEBUG
    @State private var showingDebug = false
    #endif

    var body: some View {
        RescueFlowView(
            chromeVisible: $chromeVisible,
            requestedTaskID: $requestedTaskID,
            releasedTaskID: $releasedTaskID,
            newTaskRequest: $newTaskRequest,
            aiConfigurationRevision: $aiConfigurationRevision
        )
            .overlay(alignment: .topTrailing) {
                if chromeVisible {
                    HStack(spacing: Space.s1) {
                        #if DEBUG
                        Button { showingDebug = true } label: {
                            Image(systemName: "hammer")
                                .foregroundStyle(KindlingColor.textSecondary)
                                .kindlingTapTarget()
                        }
                        .accessibilityLabel("Developer tools")
                        #endif

                        Button { showingTasks = true } label: {
                            Image(systemName: "square.stack.3d.up")
                                .foregroundStyle(KindlingColor.textSecondary)
                                .kindlingTapTarget()
                        }
                        .accessibilityLabel("Your tasks")

                        Button { showingSettings = true } label: {
                            Image(systemName: "gearshape")
                                .foregroundStyle(KindlingColor.textSecondary)
                                .kindlingTapTarget()
                        }
                        .accessibilityLabel("Settings")
                    }
                    .padding(.trailing, Space.s2)
                }
            }
            .sheet(isPresented: $showingSettings, onDismiss: {
                aiConfigurationRevision = UUID()
            }) {
                SettingsScreen()
            }
            .sheet(isPresented: $showingTasks) {
                TaskShelfScreen(
                    onResume: { requestedTaskID = $0 },
                    onStartNew: attemptStartNewTask,
                    onRelease: { releasedTaskID = $0 }
                )
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallScreen(source: .taskShelf) {
                    newTaskRequest = UUID()
                }
            }
        #if DEBUG
            // Lets Settings be inspected from the command line, since it is behind a
            // tap. Debug-only; never compiled into a release.
            .task {
                if ProcessInfo.processInfo.environment["KINDLING_OPEN_SETTINGS"] == "1" {
                    showingSettings = true
                }
            }
        #endif
        #if DEBUG
            .sheet(isPresented: $showingDebug) {
                DebugToolsView()
            }
        #endif
    }

    private func attemptStartNewTask() {
        analytics.track(.secondTaskAttempted)
        let count = ActiveTaskPolicy.currentActiveCount(in: tasks.map(\.status))
        if ActiveTaskPolicy.canStartAnotherTask(
            currentActiveCount: count,
            hasMultiTaskEntitlement: entitlements.hasMultiTask
        ) {
            newTaskRequest = UUID()
        } else {
            analytics.track(.paywallDisplayed(source: .taskShelf))
            showingPaywall = true
        }
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
