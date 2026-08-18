import SwiftUI

/// A soft-filled input. Focus is a two-layer treatment — an accent outline plus
/// background separation — because glow alone is invisible to anyone who cannot
/// see it, and would fail as the only focus indicator.
public struct KindlingField: View {
    let placeholder: String
    @Binding var text: String
    var isFocused: Bool

    public init(placeholder: String, text: Binding<String>, isFocused: Bool = false) {
        self.placeholder = placeholder
        self._text = text
        self.isFocused = isFocused
    }

    public var body: some View {
        TextField(placeholder, text: $text, axis: .vertical)
            .font(.kindlingBody)
            .foregroundStyle(KindlingColor.textPrimary)
            .textFieldStyle(.plain)
            .padding(Space.s2)
            .frame(minHeight: KindlingLayout.minTapTarget)
            .background(
                RoundedRectangle(cornerRadius: KindlingLayout.radius, style: .continuous)
                    .fill(isFocused ? KindlingColor.surfaceStrong : KindlingColor.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: KindlingLayout.radius, style: .continuous)
                    .strokeBorder(KindlingColor.focus, lineWidth: isFocused ? 2 : 0)
            )
    }
}

/// The blank-page mitigation from §14, and the single most-watched element in the
/// whole flow: a tappable suggestion for people who freeze on an empty field.
public struct SampleTaskChip: View {
    let text: String
    let action: () -> Void

    public init(text: String, action: @escaping () -> Void) {
        self.text = text
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(text)
                .font(.kindlingCaption)
                .foregroundStyle(KindlingColor.textPrimary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Space.s2)
                .frame(minHeight: KindlingLayout.minTapTarget)
                .background(
                    RoundedRectangle(cornerRadius: KindlingLayout.radius, style: .continuous)
                        .fill(KindlingColor.surface)
                )
        }
        .buttonStyle(.plain)
    }
}
