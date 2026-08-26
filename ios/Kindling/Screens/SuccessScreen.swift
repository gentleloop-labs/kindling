import KindlingUI
import SwiftUI

/// §14 screen 6. The Ember blooms. No confetti, no numbers, no streak, no score —
/// counting anything here would turn starting into a performance.
struct SuccessScreen: View {
    let onContinue: () -> Void

    var body: some View {
        ScreenScaffold {
            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: Space.s4) {
                    EmberView(state: .celebrating, size: 144)

                    Text("You started. That's the whole game.")
                        .font(.kindlingTitle)
                        .foregroundStyle(KindlingColor.textPrimary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, Space.s6)

                Spacer()
            }
        } actions: {
            Button("Done", action: onContinue)
                .buttonStyle(.kindlingPrimary)
        }
    }
}

#Preview { SuccessScreen {} }
