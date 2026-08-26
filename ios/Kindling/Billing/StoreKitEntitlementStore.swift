import Foundation
import KindlingCore
import Observation
import StoreKit

/// The four StoreKit answers the UI needs to distinguish. Cancellation and
/// Ask-to-Buy are expected states, not errors.
enum PurchaseOutcome: Equatable {
    case purchased
    case pending
    case cancelled
    case failed
}

/// Entitlement state, backed by StoreKit 2.
///
/// Lives in the app target so `KindlingCore` keeps zero dependencies and its rules —
/// including `ActiveTaskPolicy`, the actual §15 boundary — stay testable without a
/// store account or a network.
///
/// **Every failure resolves to "not entitled", and that is safe here specifically
/// because the free tier is complete.** Someone who has paid but cannot be verified
/// right now still gets the whole rescue flow on one task; the worst case is a
/// paywall they shouldn't see, never a person locked out of getting unstuck.
///
/// Replaced RevenueCat on 2026-08-18. RevenueCat's justification was cross-platform
/// entitlement state; with Android permanently dropped there is no second platform
/// for entitlements to be shared with. See `IMPLEMENTATION.md` Phase 5.
@Observable
@MainActor
final class StoreKitEntitlementStore: EntitlementProviding {
    /// Cached so the paywall check does not wait on the network mid-flow.
    private(set) var hasMultiTask = false

    /// Products, loaded once and reused by the paywall.
    private(set) var products: [Product] = []

    /// Watches for transactions that arrive outside a purchase we initiated:
    /// Ask-to-Buy approvals, purchases made on another device, subscription
    /// renewals, and refunds. **Without this the app can silently miss a purchase
    /// the user has genuinely made**, which is the failure StoreKit 2 makes easiest
    /// to introduce — nothing in the purchase path itself looks wrong.
    private var updatesTask: Task<Void, Never>?

    /// Start the transaction listener and take a first reading.
    ///
    /// Called from `KindlingApp` at launch. The listener must outlive any one view,
    /// which is why it is owned here rather than by a `.task` modifier.
    func start() {
        guard updatesTask == nil else { return }
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                guard let self else { return }
                // Finish the transaction so StoreKit stops replaying it. Do this
                // even for products we do not recognise — an unfinished transaction
                // is redelivered forever.
                if case .verified(let transaction) = update {
                    await transaction.finish()
                }
                await self.refresh()
            }
        }
        Task { await refresh() }
    }

    // No `deinit` cancelling `updatesTask`: under Swift 6 `deinit` is nonisolated
    // and cannot touch main-actor state. It would be dead code regardless — this
    // store is held by the `App` for the process's whole lifetime, so the listener
    // is meant to outlive every view and stop only when the process does.

    /// Re-read entitlement state from StoreKit's own record of current entitlements.
    ///
    /// `Transaction.currentEntitlements` is the source of truth and survives
    /// reinstalls against the same Apple ID, which is why iOS needs no account for
    /// any of this (§7).
    func refresh() async {
        var entitled = false
        for await result in Transaction.currentEntitlements {
            // An unverified transaction is not a purchase we can stand behind, so it
            // grants nothing. Failing closed is safe because the free tier is whole.
            guard case .verified(let transaction) = result else { continue }
            guard transaction.revocationDate == nil else { continue }
            if ProductID.entitlement(for: transaction.productID) == .multiTask {
                entitled = true
            }
        }
        hasMultiTask = entitled
    }

    nonisolated func isActive(_ entitlement: Entitlement) async -> Bool {
        switch entitlement {
        case .multiTask:
            return await MainActor.run { hasMultiTask }
        }
    }

    // MARK: - Purchasing

    /// Load the three §15 products, sorted so the paywall's order is deterministic
    /// rather than whatever order StoreKit happened to return.
    func loadProducts() async {
        do {
            let loaded = try await Product.products(for: ProductID.all)
            let order = [ProductID.monthly, ProductID.annual, ProductID.lifetime]
            products = loaded.sorted {
                (order.firstIndex(of: $0.id) ?? .max) < (order.firstIndex(of: $1.id) ?? .max)
            }
        } catch {
            // Offline, or the products are not yet configured in App Store Connect.
            // An empty list means the paywall shows nothing to buy rather than
            // showing something broken.
            products = []
        }
    }

    func purchase(_ product: Product) async -> PurchaseOutcome {
        do {
            switch try await product.purchase() {
            case .success(let verification):
                guard case .verified(let transaction) = verification else { return .failed }
                await transaction.finish()
                await refresh()
                return hasMultiTask ? .purchased : .failed
            case .userCancelled:
                return .cancelled
            case .pending:
                // Ask-to-Buy, awaiting a parent's approval. Not a failure and not a
                // success — the `Transaction.updates` listener picks it up if and
                // when it is approved.
                return .pending
            @unknown default:
                return .failed
            }
        } catch {
            return .failed
        }
    }

    /// StoreKit decides eligibility from the customer's subscription history.
    /// Lifetime is not a subscription and therefore never has a trial.
    func isEligibleForIntroOffer(_ product: Product) async -> Bool {
        guard let subscription = product.subscription else { return false }
        return await subscription.isEligibleForIntroOffer
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

    /// StoreKit 2 restores entitlements on its own, so this button exists mostly
    /// because App Review expects it and because it gives someone a way to *act*
    /// when the app disagrees with what they believe they bought.
    func restore() async -> RestoreResult {
        do {
            try await AppStore.sync()
            await refresh()
            // The round-trip succeeded either way; the entitlement decides which
            // answer it was.
            return hasMultiTask ? .restored : .nothingToRestore
        } catch {
            // Offline, or the user dismissed the App Store sign-in sheet. Distinct
            // from having nothing to restore.
            return .failed
        }
    }
}
