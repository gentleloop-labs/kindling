import Foundation
import KindlingCore
import Observation
import RevenueCat

/// Entitlement state, backed by RevenueCat.
///
/// Lives in the app target so `KindlingCore` keeps zero dependencies and its rules —
/// including `ActiveTaskPolicy`, the actual §15 boundary — stay testable without a
/// store account or a network.
///
/// **Every failure resolves to "not entitled", and that is safe here specifically
/// because the free tier is complete.** Someone who has paid but cannot be verified
/// right now still gets the whole rescue flow on one task; the worst case is a
/// paywall they shouldn't see, never a person locked out of getting unstuck.
@Observable
@MainActor
final class RevenueCatEntitlementStore: EntitlementProviding {
    /// Cached so the paywall check does not wait on the network mid-flow.
    private(set) var hasMultiTask = false

    /// Read live rather than snapshotted at init.
    ///
    /// SwiftUI runs `@State` property initializers *before* the `App`'s own `init`,
    /// so this type is constructed before `configure(apiKey:)` has run. Caching the
    /// value here meant it was permanently false and the restore section never
    /// appeared, with no error anywhere — caught only by looking at the screen.
    var isConfigured: Bool { Purchases.isConfigured }

    /// Public SDK key. Safe to ship in the binary — it is the key RevenueCat
    /// intends clients to carry, unlike a secret API key.
    static func configure(apiKey: String) {
        guard !apiKey.isEmpty else { return }
        Purchases.configure(withAPIKey: apiKey)
    }

    func refresh() async {
        guard Purchases.isConfigured else {
            hasMultiTask = false
            return
        }
        do {
            let info = try await Purchases.shared.customerInfo()
            hasMultiTask = info.entitlements[Entitlement.multiTask.rawValue]?.isActive == true
        } catch {
            // Offline or a RevenueCat outage. Fall back to not-entitled rather than
            // guessing, and let the next refresh correct it.
            hasMultiTask = false
        }
    }

    nonisolated func isActive(_ entitlement: Entitlement) async -> Bool {
        switch entitlement {
        case .multiTask:
            return await MainActor.run { hasMultiTask }
        }
    }

    // MARK: - Purchasing

    func availablePackages() async -> [Package] {
        guard Purchases.isConfigured else { return [] }
        do {
            return try await Purchases.shared.offerings().current?.availablePackages ?? []
        } catch {
            return []
        }
    }

    /// - Returns: true when the purchase completed and the entitlement is now active.
    ///   A user cancellation returns false and is **not** an error — it is a normal,
    ///   expected answer, and must never be surfaced as a failure.
    func purchase(_ package: Package) async -> Bool {
        guard Purchases.isConfigured else { return false }
        do {
            let result = try await Purchases.shared.purchase(package: package)
            guard !result.userCancelled else { return false }
            hasMultiTask = result.customerInfo.entitlements[Entitlement.multiTask.rawValue]?.isActive == true
            return hasMultiTask
        } catch {
            return false
        }
    }

    /// Outcome of a restore attempt.
    ///
    /// "Nothing to restore" and "the call failed" are genuinely different answers and
    /// must not collapse into one: the first is the *correct* result for anyone who
    /// never purchased — which is most people who tap the button — and showing them
    /// an error would be wrong.
    enum RestoreResult {
        case restored
        case nothingToRestore
        case failed
    }

    func restore() async -> RestoreResult {
        guard Purchases.isConfigured else { return .failed }
        do {
            let info = try await Purchases.shared.restorePurchases()
            hasMultiTask = info.entitlements[Entitlement.multiTask.rawValue]?.isActive == true
            // The round-trip succeeded either way; the entitlement decides which
            // answer it was.
            return hasMultiTask ? .restored : .nothingToRestore
        } catch {
            // Offline, or a RevenueCat/StoreKit failure. Distinct from having
            // nothing to restore.
            return .failed
        }
    }
}
