import Foundation

public enum Entitlement: String, Sendable, CaseIterable {
    case pro
}

public protocol EntitlementProviding: Sendable {
    func isActive(_ entitlement: Entitlement) async -> Bool
}

public struct NoEntitlements: EntitlementProviding {
    public init() {}
    public func isActive(_ entitlement: Entitlement) async -> Bool { false }
}

public enum ProductID {
    public static let monthly = "dev.aftaab.kindling.pro.monthly"
    public static let annual = "dev.aftaab.kindling.pro.annual"
    public static let lifetime = "dev.aftaab.kindling.pro.lifetime"
    public static let all: Set<String> = [monthly, annual, lifetime]

    public static func entitlement(for productID: String) -> Entitlement? {
        all.contains(productID) ? .pro : nil
    }
}
