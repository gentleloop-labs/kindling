import KindlingUI
import SwiftUI

/// §14 screen 1. No account, no personalization survey, no permission prompt —
/// there is no reason for one yet.
struct WelcomeScreen: View {
    let onContinue: () -> Void

    var body: some View {
        ScreenScaffold {
            VStack(spacing: Space.s4) {
                Spacer()

                EmberView(state: .resting, size: 140)

                VStack(spacing: Space.s2) {
                    Text("Kindling doesn't plan your day.")
                        .font(.kindlingTitle)
                        .foregroundStyle(KindlingColor.textPrimary)
                    Text("It just helps you start the one thing you're avoiding.")
                        .font(.kindlingBody)
                        .foregroundStyle(KindlingColor.textSecondary)
                }
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

                Spacer()
            }
        } actions: {
            Button("Show me.", action: onContinue)
                .buttonStyle(.kindlingPrimary)
        }
    }
}

#Preview { WelcomeScreen {} }
