import SwiftUI

/// Flat fills, no gradient overlays. Gradients are a common tell of templated
/// design and this system does without them entirely.
public enum KindlingButtonEmphasis: Sendable {
    case primary
    case secondary
    /// The outcome screen only. All three choices render identically — any
    /// hierarchy there would imply a right answer, which is the one thing this
    /// product must never do.
    case equal
}

public struct KindlingButtonStyle: ButtonStyle {
    let emphasis: KindlingButtonEmphasis
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(emphasis: KindlingButtonEmphasis) {
        self.emphasis = emphasis
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.kindlingButton)
            .foregroundStyle(foreground)
            // Labels wrap rather than truncate. At accessibility text sizes
            // "Try a different step" does not fit on one line, and a button that
            // reads "Try a different st…" is a broken button.
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Space.s2)
            .padding(.horizontal, Space.s3)
            .frame(minHeight: KindlingLayout.minTapTarget)
            .background(background, in: RoundedRectangle(cornerRadius: KindlingLayout.radius, style: .continuous))
            // Under Reduce Motion the press reads as a fade rather than a scale.
            .opacity(configuration.isPressed ? 0.82 : 1)
            .scaleEffect(reduceMotion ? 1 : (configuration.isPressed ? 0.98 : 1))
            .animation(KindlingMotion.standard(reduceMotion: reduceMotion), value: configuration.isPressed)
    }

    private var foreground: Color {
        switch emphasis {
        case .primary: KindlingColor.accentInk
        case .secondary, .equal: KindlingColor.textPrimary
        }
    }

    private var background: Color {
        switch emphasis {
        case .primary: KindlingColor.accent
        case .secondary, .equal: KindlingColor.surfaceStrong
        }
    }
}

public extension ButtonStyle where Self == KindlingButtonStyle {
    static var kindlingPrimary: KindlingButtonStyle { KindlingButtonStyle(emphasis: .primary) }
    static var kindlingSecondary: KindlingButtonStyle { KindlingButtonStyle(emphasis: .secondary) }
    static var kindlingEqual: KindlingButtonStyle { KindlingButtonStyle(emphasis: .equal) }
}
