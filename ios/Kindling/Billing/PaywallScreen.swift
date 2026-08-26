import KindlingCore
import KindlingUI
import StoreKit
import SwiftUI

struct PaywallScreen: View {
    enum Source {
        case taskShelf
        case settings
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(StoreKitEntitlementStore.self) private var store
    @Environment(\.analyticsTracker) private var analytics

    let source: Source
    var onPurchased: () -> Void = {}

    @State private var selectedProductID = ProductID.annual
    @State private var introEligibility: [String: Bool] = [:]
    @State private var isLoading = true
    @State private var isPurchasing = false
    @State private var isRestoring = false
    @State private var statusMessage: String?

    private var selectedProduct: Product? {
        store.products.first { $0.id == selectedProductID }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Space.s3) {
                    VStack(alignment: .leading, spacing: Space.s1) {
                        Text("Keep more than one task warm.")
                            .font(.kindlingTitle)
                            .foregroundStyle(KindlingColor.textPrimary)
                        Text("Kindling is free for one task at a time. Upgrade to park and return to as many as you need.")
                            .font(.kindlingBody)
                            .foregroundStyle(KindlingColor.textSecondary)
                    }

                    products

                    if let statusMessage {
                        Text(statusMessage)
                            .font(.kindlingCaption)
                            .foregroundStyle(KindlingColor.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }

                    Button(purchaseButtonTitle) {
                        Task { await purchase() }
                    }
                    .buttonStyle(.kindlingPrimary)
                    .disabled(selectedProduct == nil || isPurchasing || isLoading)

                    Button(isRestoring ? "Checking with Apple…" : "Restore purchases") {
                        Task { await restore() }
                    }
                    .buttonStyle(.kindlingSecondary)
                    .disabled(isRestoring || isPurchasing)

                    HStack(spacing: Space.s3) {
                        Link("Terms", destination: URL(string: "https://kindling.maskedsyntax.com/terms/")!)
                        Link("Privacy", destination: URL(string: "https://kindling.maskedsyntax.com/privacy/")!)
                    }
                    .font(.kindlingCaption)
                    .foregroundStyle(KindlingColor.textSecondary)
                    .frame(maxWidth: .infinity)
                }
                .padding(Space.s3)
            }
            .scrollBounceBehavior(.basedOnSize)
            .background(KindlingColor.background)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", systemImage: "xmark") { dismiss() }
                        .labelStyle(.iconOnly)
                        .accessibilityLabel("Close")
                }
            }
        }
        .interactiveDismissDisabled(isPurchasing)
        .task { await loadProducts() }
    }

    @ViewBuilder
    private var products: some View {
        if isLoading {
            HStack(spacing: Space.s1) {
                ProgressView()
                Text("Loading choices…")
            }
            .font(.kindlingBody)
            .foregroundStyle(KindlingColor.textSecondary)
            .frame(maxWidth: .infinity, minHeight: 180)
        } else if store.products.isEmpty {
            VStack(spacing: Space.s2) {
                Text("Purchase choices aren't available right now.")
                    .font(.kindlingBody)
                    .foregroundStyle(KindlingColor.textPrimary)
                    .multilineTextAlignment(.center)
                Button("Try again") { Task { await loadProducts() } }
                    .buttonStyle(.kindlingSecondary)
            }
            .frame(maxWidth: .infinity, minHeight: 180)
        } else {
            VStack(spacing: Space.s1) {
                ForEach(store.products, id: \.id) { product in
                    productChoice(product)
                }
            }
        }
    }

    private func productChoice(_ product: Product) -> some View {
        Button {
            selectedProductID = product.id
            statusMessage = nil
        } label: {
            HStack(spacing: Space.s2) {
                Image(systemName: selectedProductID == product.id ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(KindlingColor.accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text(product.displayName)
                        .font(.kindlingBody)
                        .foregroundStyle(KindlingColor.textPrimary)
                    if introEligibility[product.id] == true {
                        Text("Includes a 7-day free trial")
                            .font(.kindlingCaption)
                            .foregroundStyle(KindlingColor.textSecondary)
                    }
                }
                Spacer(minLength: Space.s1)
                Text(product.displayPrice)
                    .font(.kindlingButton)
                    .foregroundStyle(KindlingColor.textPrimary)
            }
            .padding(Space.s2)
            .frame(maxWidth: .infinity, minHeight: KindlingLayout.minTapTarget)
            .background(
                selectedProductID == product.id ? KindlingColor.surfaceStrong : KindlingColor.surface,
                in: RoundedRectangle(cornerRadius: KindlingLayout.radius, style: .continuous)
            )
            .overlay {
                if selectedProductID == product.id {
                    RoundedRectangle(cornerRadius: KindlingLayout.radius, style: .continuous)
                        .stroke(KindlingColor.focus, lineWidth: 2)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityValue(selectedProductID == product.id ? "Selected" : "Not selected")
    }

    private var purchaseButtonTitle: String {
        if isPurchasing { return "Checking with Apple…" }
        guard let selectedProduct else { return "Continue" }
        if selectedProduct.id == ProductID.lifetime { return "Unlock forever" }
        return introEligibility[selectedProduct.id] == true ? "Start 7-day free trial" : "Continue"
    }

    private func loadProducts() async {
        isLoading = true
        statusMessage = nil
        await store.loadProducts()
        if !store.products.contains(where: { $0.id == selectedProductID }) {
            selectedProductID = store.products.first?.id ?? ProductID.annual
        }

        var eligibility: [String: Bool] = [:]
        for product in store.products {
            eligibility[product.id] = await store.isEligibleForIntroOffer(product)
        }
        introEligibility = eligibility
        isLoading = false
    }

    private func purchase() async {
        guard let selectedProduct else { return }
        isPurchasing = true
        statusMessage = nil
        let outcome = await store.purchase(selectedProduct)
        isPurchasing = false

        switch outcome {
        case .purchased:
            analytics.track(.upgradeCompleted(period: analyticsPeriod(for: selectedProduct.id)))
            dismiss()
            onPurchased()
        case .pending:
            statusMessage = "Waiting for approval. Your tasks will unlock automatically when Apple approves it."
        case .cancelled:
            statusMessage = "No changes made."
        case .failed:
            statusMessage = "That didn't work. Check your connection and try again."
        }
    }

    private func analyticsPeriod(for productID: String) -> AnalyticsProductPeriod {
        switch productID {
        case ProductID.monthly: .monthly
        case ProductID.annual: .annual
        default: .lifetime
        }
    }

    private func restore() async {
        isRestoring = true
        statusMessage = nil
        let result = await store.restore()
        isRestoring = false

        switch result {
        case .restored:
            statusMessage = "Your purchase is back."
            dismiss()
            if source == .taskShelf { onPurchased() }
        case .nothingToRestore:
            statusMessage = "Nothing to restore on this Apple ID."
        case .failed:
            statusMessage = "That didn't work. Check your connection and try again."
        }
    }
}
