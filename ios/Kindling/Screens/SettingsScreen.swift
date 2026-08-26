import KindlingCore
import KindlingUI
import StoreKit
import SwiftData
import SwiftUI

/// The §11 and §17 settings, plus purchase restore. There is still no account
/// section, because there is still no account — restore asks Apple, which already
/// knows who bought what.
struct SettingsScreen: View {
    @Environment(\.modelContext) private var context
    @Environment(StoreKitEntitlementStore.self) private var entitlements
    @Environment(\.analyticsTracker) private var analytics

    @State private var isRestoring = false
    @State private var showingPaywall = false
    @State private var showingSubscriptionManagement = false
    @State private var restoreOutcome: StoreKitEntitlementStore.RestoreResult?
    @State private var haptics = true
    @State private var aiStepsEnabled = false
    @State private var hostedAIConsent: HostedAIConsent = .notAsked
    @State private var showingHostedAIConsent = false
    @State private var notificationsOptIn = false
    @State private var excludeFromBackup = false
    @State private var backupToggleError: String?
    @State private var clearedCount: Int?

    var body: some View {
        NavigationStack {
            Form {
                Section("Session") {
                    Toggle("Haptics", isOn: $haptics)
                        .onChange(of: haptics) { _, value in store.set(PreferenceKey.haptics, value) }
                }

                if StepEngineFactory.isAnyAIConfigured {
                    Section {
                        Toggle("Smarter first steps", isOn: $aiStepsEnabled)
                            .onChange(of: aiStepsEnabled) { _, value in
                                if value,
                                   StepEngineFactory.isRemoteConfigured,
                                   hostedAIConsent == .notAsked {
                                    showingHostedAIConsent = true
                                } else {
                                    store.set(PreferenceKey.aiStepsEnabled, value)
                                }
                            }
                        if let status = StepEngineFactory.onDeviceStatus {
                            // An ineligible device says why, rather than looking broken.
                            Text(status)
                                .font(.kindlingCaption)
                                .foregroundStyle(KindlingColor.textSecondary)
                        }
                        if StepEngineFactory.isRemoteConfigured, hostedAIConsent != .notAsked {
                            Text(hostedAIConsent == .allowed
                                 ? "Cloud fallback is allowed."
                                 : "Cloud fallback is off; on-device and template steps still work.")
                                .font(.kindlingCaption)
                                .foregroundStyle(KindlingColor.textSecondary)
                        }
                    } footer: {
                        // Stated plainly, at the moment of choice.
                        Text(aiFooter)
                    }
                }

                Section {
                    if entitlements.hasMultiTask {
                        Label("Kindling Plus: Active", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(KindlingColor.textPrimary)
                        Button("Manage subscription") {
                            showingSubscriptionManagement = true
                        }
                    } else {
                        Button("Upgrade") {
                            analytics.track(.paywallDisplayed(source: .settings))
                            showingPaywall = true
                        }
                    }

                    Button("Restore purchases") { Task { await restore() } }
                        .disabled(isRestoring)

                    if isRestoring {
                        Text("Checking with Apple…")
                            .font(.kindlingCaption)
                            .foregroundStyle(KindlingColor.textSecondary)
                    } else if let restoreOutcome {
                        Text(Self.message(for: restoreOutcome))
                            .font(.kindlingCaption)
                            .foregroundStyle(KindlingColor.textSecondary)
                    }
                } header: {
                    Text("Kindling Plus")
                } footer: {
                    Text(entitlements.hasMultiTask
                         ? "Manage renewals with Apple, or restore a purchase made on another device."
                         : "Keep more than one task warm, or restore a purchase made on another device.")
                }

                Section {
                    Toggle("Nudge me about parked tasks", isOn: $notificationsOptIn)
                        .onChange(of: notificationsOptIn) { _, value in
                            store.set(PreferenceKey.notificationsOptIn, value)
                            if value {
                                Task {
                                    let granted = await NotificationService.requestAuthorization()
                                    analytics.track(.notificationPermission(
                                        granted ? .allowed : .declined
                                    ))
                                }
                            }
                        }
                } footer: {
                    Text("At most one nudge a day, and it never mentions what the task is.")
                }

                Section {
                    Toggle("Exclude my data from device backups", isOn: $excludeFromBackup)
                        .onChange(of: excludeFromBackup) { _, value in setExcludedFromBackup(value) }
                    if let backupToggleError {
                        Text(backupToggleError).font(.kindlingCaption)
                    }
                } footer: {
                    Text("Kindling stores everything on this device. Backups are the only way it leaves, inside your own encrypted backup.")
                }

                Section {
                    Button("Clear finished tasks") { clearFinished() }
                    if let clearedCount {
                        Text(clearedCount == 0 ? "Nothing to clear." : "Cleared \(clearedCount).")
                            .font(.kindlingCaption)
                    }
                } footer: {
                    Text("Removes tasks you marked done or discarded, and everything recorded with them. Nothing is deleted automatically.")
                }
            }
            .navigationTitle("Settings")
        }
        .task { load() }
        .sheet(isPresented: $showingPaywall) {
            PaywallScreen(source: .settings)
        }
        .manageSubscriptionsSheet(isPresented: $showingSubscriptionManagement)
        .alert("Allow cloud fallback?", isPresented: $showingHostedAIConsent) {
            Button("Allow cloud fallback") {
                hostedAIConsent = .allowed
                store.setHostedAIConsent(.allowed)
                store.set(PreferenceKey.aiStepsEnabled, true)
            }
            Button("Keep it on this iPhone") {
                hostedAIConsent = .declined
                store.setHostedAIConsent(.declined)
                store.set(PreferenceKey.aiStepsEnabled, true)
            }
        } message: {
            Text("On this iPhone, smarter steps may send only the task title to Kindling's Cloudflare Worker and OpenAI. Kindling and the Worker do not store it. OpenAI may retain API content for abuse monitoring for up to 30 days. You can use on-device and template steps without this.")
        }
    }

    /// The honest version depends on what this device can actually do: on a
    /// capable phone nothing leaves the device at all, so the copy must not claim
    /// otherwise in either direction.
    private var aiFooter: String {
        let onDeviceWorks = StepEngineFactory.onDeviceStatus == nil
        if onDeviceWorks {
            return "When on, Apple Intelligence writes steps on this iPhone whenever possible. Cloud fallback is used only with your separate permission; templates always work offline."
        }
        return "When on, templates always work offline. Cloud fallback is used only with your separate permission."
    }

    /// Asks Apple what this Apple ID owns. Needs no account and no login — Apple is
    /// already the record of who bought what.
    private func restore() async {
        isRestoring = true
        restoreOutcome = nil
        defer { isRestoring = false }

        restoreOutcome = await entitlements.restore()
    }

    /// §13: no red, no alert boxes. "Nothing to restore" is a plain statement of fact,
    /// not a failure — it is the right answer for anyone who never purchased.
    private static func message(for result: StoreKitEntitlementStore.RestoreResult) -> String {
        switch result {
        case .restored: "Your purchase is back."
        case .nothingToRestore: "Nothing to restore on this Apple ID."
        case .failed: "That didn't work. Let's try that differently."
        }
    }

    private var store: PreferencesStore { PreferencesStore(context: context) }

    private func load() {
        haptics = store.bool(PreferenceKey.haptics, default: true)
        aiStepsEnabled = store.bool(PreferenceKey.aiStepsEnabled, default: false)
        hostedAIConsent = store.hostedAIConsent()
        notificationsOptIn = store.bool(PreferenceKey.notificationsOptIn, default: false)
        excludeFromBackup = (try? KindlingStore.isExcludedFromBackup()) ?? false
    }

    private func setExcludedFromBackup(_ value: Bool) {
        do {
            try KindlingStore.setExcludedFromBackup(value)
            store.set(PreferenceKey.excludeFromBackup, value)
            backupToggleError = nil
        } catch {
            // Framed as something to retry, not an alarm. No red, per §13.
            backupToggleError = "That didn't take. Let's try that differently."
            excludeFromBackup = (try? KindlingStore.isExcludedFromBackup()) ?? false
        }
    }

    /// The only deletion path in the app. Cascade rules take the steps, sessions,
    /// and request logs with each task.
    private func clearFinished() {
        let finished = (try? context.fetch(FetchDescriptor<AvoidedTask>(
            predicate: #Predicate { $0.statusRaw == "done" || $0.statusRaw == "discarded" }
        ))) ?? []
        for task in finished { context.delete(task) }
        try? context.save()
        clearedCount = finished.count
    }
}
