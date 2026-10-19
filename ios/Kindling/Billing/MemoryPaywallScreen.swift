import KindlingCore
import KindlingUI
import StoreKit
import SwiftUI

struct PaywallScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(StoreKitEntitlementStore.self) private var store
    @Environment(\.analyticsTracker) private var analytics

    let source: AnalyticsPaywallSource
    var onPurchased: () -> Void = {}

    @State private var selectedProductID = ProductID.annual
    @State private var isLoading = true
    @State private var isPurchasing = false
    @State private var isRestoring = false
    @State private var statusMessage: String?

    private var selectedProduct: Product? { store.products.first { $0.id == selectedProductID } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Space.s3) {
                    HStack(alignment: .top, spacing: Space.s2) {
                        EmberView(state: .celebrating, size: 76)
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Keep your whole atlas.")
                                .font(.kindlingTitle)
                                .foregroundStyle(KindlingColor.textPrimary)
                            Text("Your first two trips are free. Kindling Pro keeps every trail and gives you richer ways to share and resurface them.")
                                .font(.kindlingBody)
                                .foregroundStyle(KindlingColor.textSecondary)
                        }
                    }

                    VStack(alignment: .leading, spacing: Space.s1) {
                        Label("Unlimited memory trails", systemImage: "infinity")
                        Label("Premium postcard and map styles", systemImage: "paintpalette")
                        Label("Branding and resurfacing controls", systemImage: "slider.horizontal.3")
                    }
                    .font(.kindlingBody)
                    .foregroundStyle(KindlingColor.textPrimary)

                    products

                    if let statusMessage {
                        Text(statusMessage)
                            .font(.kindlingCaption)
                            .foregroundStyle(KindlingColor.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }

                    Button(purchaseButtonTitle) { Task { await purchase() } }
                        .buttonStyle(.kindlingPrimary)
                        .disabled((selectedProduct == nil && !isScreenshotRoute) || isPurchasing || isLoading)

                    Button(isRestoring ? "Checking with Apple…" : "Restore purchases") {
                        Task { await restore() }
                    }
                    .buttonStyle(.kindlingSecondary)
                    .disabled(isRestoring || isPurchasing)

                    HStack(spacing: Space.s3) {
                        Link("Terms", destination: URL(string: "https://kindling.gentlelooplabs.com/terms/")!)
                        Link("Privacy", destination: URL(string: "https://kindling.gentlelooplabs.com/privacy/")!)
                    }
                    .font(.kindlingCaption)
                    .foregroundStyle(KindlingColor.textSecondary)
                    .frame(maxWidth: .infinity)
                    Text("Subscriptions renew automatically unless cancelled at least 24 hours before the end of the current period. Manage or cancel in your Apple ID settings.")
                        .font(.kindlingCaption)
                        .foregroundStyle(KindlingColor.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(Space.s3)
            }
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
            ProgressView("Loading choices…")
                .frame(maxWidth: .infinity, minHeight: 150)
        } else if store.products.isEmpty && isScreenshotRoute {
            VStack(spacing: Space.s1) {
                previewProduct("Monthly", price: "$4.99", selected: false)
                previewProduct("Annual", price: "$29.99", selected: true)
                previewProduct("Early lifetime", price: "$59.99", selected: false)
            }
        } else if store.products.isEmpty {
            VStack(spacing: Space.s2) {
                Text("Purchase choices aren't available right now.")
                    .font(.kindlingBody)
                Button("Try again") { Task { await loadProducts() } }
                    .buttonStyle(.kindlingSecondary)
            }
            .frame(maxWidth: .infinity, minHeight: 150)
        } else {
            VStack(spacing: Space.s1) {
                ForEach(store.products, id: \.id) { product in productChoice(product) }
            }
        }
    }

    private func previewProduct(_ name: String, price: String, selected: Bool) -> some View {
        HStack(spacing: Space.s2) {
            Image(systemName: selected ? "largecircle.fill.circle" : "circle")
                .foregroundStyle(KindlingColor.accent)
            VStack(alignment: .leading, spacing: 2) {
                Text(name).font(.kindlingBody)
            }
            Spacer()
            Text(price).font(.kindlingButton)
        }
        .foregroundStyle(KindlingColor.textPrimary)
        .padding(Space.s2)
        .frame(minHeight: KindlingLayout.minTapTarget)
        .background(selected ? KindlingColor.surfaceStrong : KindlingColor.surface,
                    in: RoundedRectangle(cornerRadius: KindlingLayout.radius))
        .overlay {
            if selected {
                RoundedRectangle(cornerRadius: KindlingLayout.radius)
                    .stroke(KindlingColor.focus, lineWidth: 2)
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
                    Text(product.displayName).font(.kindlingBody)
                }
                Spacer()
                Text(product.displayPrice).font(.kindlingButton)
            }
            .foregroundStyle(KindlingColor.textPrimary)
            .padding(Space.s2)
            .frame(minHeight: KindlingLayout.minTapTarget)
            .background(
                selectedProductID == product.id ? KindlingColor.surfaceStrong : KindlingColor.surface,
                in: RoundedRectangle(cornerRadius: KindlingLayout.radius)
            )
            .overlay {
                if selectedProductID == product.id {
                    RoundedRectangle(cornerRadius: KindlingLayout.radius)
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
        return "Continue"
    }

    private var isScreenshotRoute: Bool {
        #if DEBUG
        ProcessInfo.processInfo.environment["KINDLING_SCREEN"] == "paywall"
        #else
        false
        #endif
    }

    private func loadProducts() async {
        isLoading = true
        await store.loadProducts()
        if !store.products.contains(where: { $0.id == selectedProductID }) {
            selectedProductID = store.products.first?.id ?? ProductID.annual
        }
        isLoading = false
    }

    private func purchase() async {
        guard let selectedProduct else { return }
        let period = analyticsPeriod(for: selectedProduct.id)
        analytics.track(.purchaseStarted(period: period))
        isPurchasing = true
        statusMessage = nil
        let outcome = await store.purchase(selectedProduct)
        isPurchasing = false
        switch outcome {
        case .purchased:
            analytics.track(.purchaseCompleted(period: period))
            dismiss(); onPurchased()
        case .pending:
            statusMessage = "Waiting for approval. Pro will unlock automatically when Apple approves it."
        case .cancelled:
            analytics.track(.purchaseCancelled(period: period))
            statusMessage = "No changes made."
        case .failed:
            analytics.track(.purchaseFailed(period: period))
            statusMessage = "That didn't work. Check your connection and try again."
        }
    }

    private func restore() async {
        analytics.track(.restoreStarted)
        isRestoring = true
        let result = await store.restore()
        isRestoring = false
        switch result {
        case .restored:
            analytics.track(.restoreCompleted)
            dismiss(); onPurchased()
        case .nothingToRestore: statusMessage = "Nothing to restore on this Apple ID."
        case .failed: statusMessage = "That didn't work. Check your connection and try again."
        }
    }

    private func analyticsPeriod(for productID: String) -> AnalyticsProductPeriod {
        switch productID {
        case ProductID.monthly: .monthly
        case ProductID.annual: .annual
        default: .lifetime
        }
    }
}
