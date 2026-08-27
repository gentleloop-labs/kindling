import KindlingUI
import SwiftUI

/// §14 screen 3. The step is the largest thing on screen — it is the only thing
/// the user has to do.
struct FirstStepScreen: View {
    let echoedTask: String
    let step: String
    let durationSeconds: Int
    let isGenerating: Bool
    let onStart: () -> Void
    let onRegenerate: () -> Void

    var body: some View {
        ScreenScaffold {
            VStack(spacing: 0) {
                Spacer(minLength: 0)

                VStack(spacing: Space.s3) {
                    // Focusing while a step is being generated: the Ember is already
                    // the app's "working" signal, so there is no spinner to add.
                    EmberView(state: isGenerating ? .focusing : .ready, size: 112)

                    Text("For: \(echoedTask)")
                        .font(.kindlingCaption)
                        .foregroundStyle(KindlingColor.textSecondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .padding(.horizontal, Space.s2)
                        .padding(.vertical, Space.s1)
                        .background(
                            KindlingColor.surface,
                            in: RoundedRectangle(
                                cornerRadius: KindlingLayout.radius,
                                style: .continuous
                            )
                        )
                        .accessibilityLabel("For task: \(echoedTask)")

                    if isGenerating && step.isEmpty {
                        Text("Finding the smallest first step…")
                            .font(.kindlingTitle)
                            .foregroundStyle(KindlingColor.textSecondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityLabel("Finding the smallest first step")
                    } else {
                        Text(step)
                            .font(.kindlingDisplay)
                            .foregroundStyle(KindlingColor.textPrimary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity)

                Spacer(minLength: 0)
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
