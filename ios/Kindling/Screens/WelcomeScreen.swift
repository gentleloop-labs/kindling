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

                VStack(spacing: Space.s3) {
                    EmberView(state: .ready, size: 128)

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
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, Space.s6)

                Spacer()
            }
        } actions: {
            Button("Show me.", action: onContinue)
                .buttonStyle(.kindlingPrimary)
        }
    }
}

#Preview { WelcomeScreen {} }
