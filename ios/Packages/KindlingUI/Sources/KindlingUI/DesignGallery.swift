import SwiftUI

/// A living reference for the design system. Not shipped in the flow — it exists
/// so the tokens, type scale, components, and Ember states can all be checked at
/// once, in both themes and at the largest Dynamic Type size.
public struct DesignGallery: View {
    @State private var sampleText = ""

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Space.s4) {
                section("Type") {
                    Text("Open the conversation and read the last message.")
                        .font(.kindlingDisplay)
                        .foregroundStyle(KindlingColor.textPrimary)
                    Text("Screen headline").font(.kindlingTitle).foregroundStyle(KindlingColor.textPrimary)
                    Text("Body copy sits at this size.").font(.kindlingBody).foregroundStyle(KindlingColor.textPrimary)
                    Text("The task, echoed back").font(.kindlingCaption).foregroundStyle(KindlingColor.textSecondary)
                }

                section("Color") {
                    swatch("background", KindlingColor.background)
                    swatch("surface", KindlingColor.surface)
                    swatch("surfaceStrong", KindlingColor.surfaceStrong)
                    swatch("accent", KindlingColor.accent)
                    swatch("ember (decorative)", KindlingColor.ember)
                    swatch("glow (decorative)", KindlingColor.glow)
                    swatch("celebration (decorative)", KindlingColor.celebration)
                }

                section("Buttons") {
                    Button("Start (2 min)") {}.buttonStyle(.kindlingPrimary)
                    Button("Try a different step") {}.buttonStyle(.kindlingSecondary)
                    Text("The three outcomes, at equal weight:")
                        .font(.kindlingCaption).foregroundStyle(KindlingColor.textSecondary)
                    Button("Keep going") {}.buttonStyle(.kindlingEqual)
                    Button("That's enough for now") {}.buttonStyle(.kindlingEqual)
                    Button("I got distracted") {}.buttonStyle(.kindlingEqual)
                }

                section("Input") {
                    KindlingField(placeholder: "What are you avoiding?", text: $sampleText)
                    KindlingField(placeholder: "Focused state", text: $sampleText, isFocused: true)
                    SampleTaskChip(text: "Not sure? Try: reply to that one message you've been putting off") {}
                }

                section("Ember") {
                    ForEach(EmberState.allCases, id: \.self) { state in
                        HStack(spacing: Space.s3) {
                            EmberView(state: state, size: 24)
                            EmberView(state: state, size: 48)
                            EmberView(state: state, size: 72)
                            Text(state.accessibilityLabel)
                                .font(.kindlingCaption)
                                .foregroundStyle(KindlingColor.textSecondary)
                        }
                    }
                }

                section("Timer ring") {
                    HStack(spacing: Space.s3) {
                        TimerRing(progress: 0.15, diameter: 120)
                        TimerRing(progress: 0.75, diameter: 120)
                    }
                }
            }
            .padding(Space.s3)
        }
        .background(KindlingColor.background)
    }

    @ViewBuilder
    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: Space.s2) {
            Text(title)
                .font(.kindlingTitle)
                .foregroundStyle(KindlingColor.textPrimary)
            content()
        }
    }

    private func swatch(_ name: String, _ color: Color) -> some View {
        HStack(spacing: Space.s2) {
            RoundedRectangle(cornerRadius: KindlingLayout.radius, style: .continuous)
                .fill(color)
                .frame(width: 56, height: 40)
                .overlay(
                    RoundedRectangle(cornerRadius: KindlingLayout.radius, style: .continuous)
                        .strokeBorder(KindlingColor.textSecondary.opacity(0.25))
                )
            Text(name).font(.kindlingCaption).foregroundStyle(KindlingColor.textPrimary)
        }
    }
}

#Preview { DesignGallery() }
