import Foundation

/// What the paid tier unlocks. One entitlement, granted by any of the three §15
/// products (monthly, annual, lifetime) — the app never asks *which* was bought.
public enum Entitlement: String, Sendable, CaseIterable {
    /// Multiple concurrent parked tasks: the §15 boundary, and the primary lever.
    case multiTask = "multi_task"
}

/// Resolves entitlement state. Implemented against StoreKit 2 in the app target so
/// `KindlingCore` stays dependency-free and its rules stay testable without a
/// network, a store account, or a purchase.
public protocol EntitlementProviding: Sendable {
    func isActive(_ entitlement: Entitlement) async -> Bool
}

/// Used when billing is not configured, offline, or still loading.
///
/// **Not entitled is always the safe default**, and it is safe *because* the free
/// tier is fully usable: someone who has paid but cannot be verified right now
/// still gets the entire rescue flow on one task. The failure mode is a paid user
/// briefly seeing a paywall, never a user locked out of getting unstuck.
public struct NoEntitlements: EntitlementProviding {
    public init() {}
    public func isActive(_ entitlement: Entitlement) async -> Bool { false }
}

/// The three §15 products, any one of which grants `multiTask`.
///
/// These live here rather than in the app target because the product → entitlement
/// mapping is a *rule*, and rules in this codebase are unit-tested. They are plain
/// strings, so `KindlingCore` still imports nothing.
///
/// The values must match App Store Connect exactly. A typo here is invisible at
/// build time and shows up only as "no products found" on a real device, so
/// `ProductID.all` is asserted against in tests rather than trusted by eye.
public enum ProductID {
    public static let monthly = "dev.aftaab.kindling.multitask.monthly"
    public static let annual = "dev.aftaab.kindling.multitask.annual"
    public static let lifetime = "dev.aftaab.kindling.multitask.lifetime"

    /// Every product Kindling sells. Used to load products and to decide whether a
    /// transaction grants anything.
    public static let all: Set<String> = [monthly, annual, lifetime]

    /// What a given product unlocks, or nil if it is not one of ours.
    ///
    /// Returning nil for an unknown identifier matters: StoreKit can hand back a
    /// transaction for a product that no longer exists in this build, and the safe
    /// reading of "I don't recognise this" is *grants nothing*, never *grants
    /// everything*.
    public static func entitlement(for productID: String) -> Entitlement? {
        all.contains(productID) ? .multiTask : nil
    }
}
