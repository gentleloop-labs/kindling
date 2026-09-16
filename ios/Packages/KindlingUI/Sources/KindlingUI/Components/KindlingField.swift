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
