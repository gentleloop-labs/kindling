import KindlingUI
import SwiftUI

/// The app shell.
///
/// The rescue flow is the whole app — there is no tab bar, no home screen, and no
/// dashboard, because every one of those would be a screen that does not get someone
/// into a first step faster. Settings sits behind a single unobtrusive control, and
/// that control **disappears during a session**: mid-session the screen offers the
/// step, the timer, and Stop, and nothing else to look at.
struct RootView: View {
    @State private var showingSettings = false
    @State private var chromeVisible = true

    #if DEBUG
    @State private var showingDebug = false
    #endif

    var body: some View {
        RescueFlowView(chromeVisible: $chromeVisible)
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
            .sheet(isPresented: $showingSettings) {
                SettingsScreen()
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
