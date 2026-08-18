import Foundation

/// What the paid tier unlocks. One entitlement, granted by any of the three §15
/// products (monthly, annual, lifetime) — the app never asks *which* was bought.
public enum Entitlement: String, Sendable, CaseIterable {
    /// Multiple concurrent parked tasks: the §15 boundary, and the primary lever.
    case multiTask = "multi_task"
}

/// Resolves entitlement state. Implemented against RevenueCat in the app target so
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
