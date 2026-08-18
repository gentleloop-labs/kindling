import KindlingUI
import SwiftUI

/// §14 screen 7. The only permission ask in onboarding, and it appears only here —
/// after the user has gotten something out of the app, never before.
///
/// Declining carries no guilt copy and no second ask in the same session. "Not now"
/// is a complete answer.
struct NotificationAskScreen: View {
    let onAllow: () -> Void
    let onDecline: () -> Void

    var body: some View {
        ScreenScaffold {
            VStack(spacing: Space.s4) {
                Spacer()

                EmberView(state: .ready, size: 120)

                Text("Want a nudge if this is still hanging around tomorrow?")
                    .font(.kindlingTitle)
                    .foregroundStyle(KindlingColor.textPrimary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()
            }
        } actions: {
            VStack(spacing: Space.s2) {
                Button("Yes", action: onAllow)
                    .buttonStyle(.kindlingPrimary)
                Button("Not now", action: onDecline)
                    .buttonStyle(.kindlingSecondary)
            }
        }
    }
}

#Preview { NotificationAskScreen(onAllow: {}, onDecline: {}) }
