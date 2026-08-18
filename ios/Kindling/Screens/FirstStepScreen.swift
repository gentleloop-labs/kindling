import KindlingUI
import SwiftUI

/// §14 screen 3. The task comes back in the user's own words, and the step is the
/// largest thing on screen — it is the only thing they have to do.
struct FirstStepScreen: View {
    let echoedTask: String
    let step: String
    let durationSeconds: Int
    let isGenerating: Bool
    let onStart: () -> Void
    let onRegenerate: () -> Void

    var body: some View {
        ScreenScaffold {
            VStack(alignment: .leading, spacing: Space.s3) {
                VStack(alignment: .leading, spacing: Space.s1) {
                    Text("You said")
                        .font(.kindlingCaption)
                        .foregroundStyle(KindlingColor.textSecondary)
                    Text(echoedTask)
                        .font(.kindlingBody)
                        .foregroundStyle(KindlingColor.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // Focusing while a step is being generated: the Ember is already
                // the app's "working" signal, so there is no spinner to add.
                EmberView(state: isGenerating ? .focusing : .ready, size: 96)
                    .frame(maxWidth: .infinity, alignment: .center)

                if isGenerating && step.isEmpty {
                    Text("Finding the smallest first step…")
                        .font(.kindlingTitle)
                        .foregroundStyle(KindlingColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityLabel("Finding the smallest first step")
                } else {
                    Text(step)
                        .font(.kindlingDisplay)
                        .foregroundStyle(KindlingColor.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }
        } actions: {
            VStack(spacing: Space.s2) {
                Button("Start (\(durationSeconds / 60) min)", action: onStart)
                    .buttonStyle(.kindlingPrimary)
                    .disabled(step.isEmpty)
                    .opacity(step.isEmpty ? 0.5 : 1)
                Button("Try a different step", action: onRegenerate)
                    .buttonStyle(.kindlingSecondary)
                    .disabled(isGenerating)
                    .opacity(isGenerating ? 0.5 : 1)
            }
        }
    }
}

#Preview {
    FirstStepScreen(
        echoedTask: "reply to the email",
        step: "Open the conversation and read the last message.",
        durationSeconds: 120,
        isGenerating: false,
        onStart: {},
        onRegenerate: {}
    )
}
