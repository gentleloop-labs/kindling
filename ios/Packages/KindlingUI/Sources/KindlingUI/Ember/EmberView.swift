import SwiftUI

/// A small, round, glowing coal — not a flame.
///
/// The shape is deliberately the simplest thing that works at every size it has to
/// survive: app icon, widget, Live Activity, and later a watch face. State is
/// carried by glow intensity and expression, never by adding detail, which is what
/// lets it stay legible when it is 24pt across.
///
/// It lives in `KindlingUI` rather than the app target because the widget
/// extension needs it too.
public struct EmberView: View {
    let state: EmberState
    let size: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animating = false

    public init(state: EmberState, size: CGFloat = 120) {
        self.state = state
        self.size = size
    }

    public var body: some View {
        ZStack {
            glow
            body_
            eyes
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(state.accessibilityLabel)
        .onAppear { animating = true }
        .onChange(of: state) { _, _ in animating = true }
    }

    // MARK: - Layers

    /// Decorative only. It may disappear entirely without changing what the screen
    /// means — every state also has its label, and nearby copy uses text tokens.
    private var glow: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [glowColor.opacity(glowOpacity), .clear],
                    center: .center,
                    startRadius: size * 0.2,
                    endRadius: size * glowRadius
                )
            )
            .scaleEffect(pulseScale)
            .opacity(flickerOpacity)
            .animation(pulseAnimation, value: animating)
            .animation(KindlingMotion.standard(reduceMotion: reduceMotion), value: state)
    }

    private var body_: some View {
        Circle()
            .fill(state == .resting ? KindlingColor.textSecondary.opacity(0.45) : KindlingColor.ember)
            .frame(width: size * 0.52, height: size * 0.52)
            .animation(KindlingMotion.standard(reduceMotion: reduceMotion), value: state)
    }

    /// Two dots. Expression comes from their spacing and size, nothing more.
    private var eyes: some View {
        HStack(spacing: size * 0.11) {
            eye
            eye
        }
        .offset(y: -size * 0.03)
    }

    private var eye: some View {
        Circle()
            .fill(KindlingColor.accentInk.opacity(state == .resting ? 0.5 : 0.85))
            .frame(width: max(2, size * 0.05), height: max(2, size * 0.05))
    }

    // MARK: - State → appearance

    /// Celebration has its own token — a warm gold rather than the ember orange,
    /// deliberately not the generic "success green".
    private var glowColor: Color {
        state == .celebrating ? KindlingColor.celebration : KindlingColor.glow
    }

    private var glowOpacity: Double {
        switch state {
        case .resting: 0
        case .ready: 0.55
        case .focusing: 0.8
        case .distracted: 0.5
        case .celebrating: 0.9
        }
    }

    private var glowRadius: CGFloat {
        switch state {
        case .resting: 0.3
        case .ready: 0.45
        case .focusing: 0.55
        case .distracted: 0.42
        case .celebrating: 0.72
        }
    }

    /// Under Reduce Motion nothing scales or pulses; the state still reads through
    /// glow opacity and radius, which change immediately.
    private var pulseScale: CGFloat {
        guard !reduceMotion else { return 1 }
        return switch state {
        case .focusing: animating ? 1.08 : 0.96
        case .celebrating: animating ? 1.12 : 1
        default: 1
        }
    }

    private var flickerOpacity: Double {
        guard !reduceMotion, state == .distracted else { return 1 }
        return animating ? 0.65 : 1
    }

    private var pulseAnimation: Animation? {
        guard !reduceMotion else { return nil }
        switch state {
        case .focusing:
            return .easeInOut(duration: 2.2).repeatForever(autoreverses: true)
        case .distracted:
            return .easeInOut(duration: 0.45).repeatForever(autoreverses: true)
        case .celebrating:
            // The one deliberate spring in the system, and only here.
            return .spring(response: 0.6, dampingFraction: 0.6)
        default:
            return KindlingMotion.standard
        }
    }
}

#Preview("All states") {
    VStack(spacing: Space.s3) {
        ForEach(EmberState.allCases, id: \.self) { state in
            HStack(spacing: Space.s3) {
                EmberView(state: state, size: 24)
                EmberView(state: state, size: 48)
                EmberView(state: state, size: 96)
                Text(state.rawValue).font(.kindlingCaption)
            }
        }
    }
    .padding(Space.s3)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(KindlingColor.background)
}
