import KindlingCore
import KindlingUI
import SwiftUI

struct MemoryOnboardingScreen: View {
    @Environment(\.analyticsTracker) private var analytics
    let onContinue: (AtlasAction) -> Void

    var body: some View {
        ZStack {
            KindlingColor.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: Space.s4) {
                    Spacer(minLength: Space.s4)
                    EmberView(state: .welcoming, size: 132)

                    VStack(spacing: Space.s2) {
                        Text("Remember where life happened.")
                            .font(.kindlingTitle)
                            .foregroundStyle(KindlingColor.textPrimary)
                            .multilineTextAlignment(.center)
                        Text("Choose photos from a past trip. Kindling arranges them into places and moments, then gives you a private trail to revisit.")
                            .font(.kindlingBody)
                            .foregroundStyle(KindlingColor.textSecondary)
                            .multilineTextAlignment(.center)
                    }

                    VStack(alignment: .leading, spacing: Space.s2) {
                        Label("No account", systemImage: "person.crop.circle.badge.checkmark")
                        Label("Only the photos you choose", systemImage: "hand.tap")
                        Label("Your memories stay on this iPhone", systemImage: "lock.shield")
                    }
                    .font(.kindlingBody)
                    .foregroundStyle(KindlingColor.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Space.s3)
                    .background(KindlingColor.surface, in: RoundedRectangle(cornerRadius: KindlingLayout.radius))

                    Button("Choose a trip") { onContinue(.importPhotos) }
                        .buttonStyle(.kindlingPrimary)
                    Button("Explore a sample first") { onContinue(.openSample) }
                        .buttonStyle(.kindlingSecondary)
                }
                .padding(Space.s3)
            }
        }
        .task { analytics.track(.onboardingStarted) }
    }
}
