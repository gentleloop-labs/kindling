import KindlingUI
import SwiftUI

/// §14 screen 1. No account, no personalization survey, no permission prompt —
/// there is no reason for one yet.
struct WelcomeScreen: View {
    let onContinue: () -> Void

    var body: some View {
        ScreenScaffold {
            VStack(spacing: 0) {
                Spacer()

                purposePage
                .frame(maxWidth: .infinity)
                .padding(.bottom, Space.s6)

                Spacer()
            }
        } actions: {
            Button("Start with one thing", action: onContinue)
                .buttonStyle(.kindlingPrimary)
        }
    }

    private var purposePage: some View {
        VStack(spacing: Space.s3) {
            EmberView(state: .ready, size: 128)

            VStack(spacing: Space.s2) {
                Text("Kindling doesn't plan your day.")
                    .font(.kindlingTitle)
                    .foregroundStyle(KindlingColor.textPrimary)
                Text("It turns the thing you're avoiding into one tiny step and a short focus session.")
                    .font(.kindlingBody)
                    .foregroundStyle(KindlingColor.textSecondary)

                Text("Free for one active task. If you need more room later, Plus keeps unlimited tasks ready for you.")
                    .font(.kindlingCaption)
                    .foregroundStyle(KindlingColor.textSecondary)
                    .padding(.top, Space.s1)
            }
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview { WelcomeScreen(onContinue: {}) }
