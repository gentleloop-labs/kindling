import KindlingUI
import SwiftUI

/// §14 screen 6. The Ember blooms. No confetti, no numbers, no streak, no score —
/// counting anything here would turn starting into a performance.
struct SuccessScreen: View {
    let showsPlusNudge: Bool
    let onContinue: () -> Void
    let onShowPlus: () -> Void

    var body: some View {
        ScreenScaffold {
            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: Space.s3) {
                    EmberView(state: .celebrating, size: 144)

                    Text("You started. That's the whole game.")
                        .font(.kindlingTitle)
                        .foregroundStyle(KindlingColor.textPrimary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    if showsPlusNudge {
                        VStack(spacing: Space.s1) {
                            Label("More than one thing on your mind?", systemImage: "sparkles")
                                .font(.kindlingButton)
                                .foregroundStyle(KindlingColor.textPrimary)
                            Text("Kindling Plus keeps every task warm until you're ready for it.")
                                .font(.kindlingCaption)
                                .foregroundStyle(KindlingColor.textSecondary)
                        }
                        .multilineTextAlignment(.center)
                        .padding(Space.s2)
                        .frame(maxWidth: .infinity)
                        .background(
                            KindlingColor.surface,
                            in: RoundedRectangle(cornerRadius: KindlingLayout.radius, style: .continuous)
                        )
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, Space.s6)

                Spacer()
            }
        } actions: {
            VStack(spacing: Space.s1) {
                Button("Done", action: onContinue)
                    .buttonStyle(.kindlingPrimary)
                if showsPlusNudge {
                    Button("See Kindling Plus", action: onShowPlus)
                        .buttonStyle(.kindlingSecondary)
                }
            }
        }
    }
}

#Preview { SuccessScreen(showsPlusNudge: true, onContinue: {}, onShowPlus: {}) }
