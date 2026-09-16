import SwiftUI

/// Kindling's Ember mascot, shared across the memory experience.
///
/// State is carried by glow, warmth, and motion so the same character remains
/// recognizable everywhere it appears.
///
/// It lives in `KindlingUI` so every feature uses the same states and motion.
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
        mascot
            .scaleEffect(pulseScale)
            .opacity(flickerOpacity)
            .animation(pulseAnimation, value: animating)
            .animation(KindlingMotion.standard(reduceMotion: reduceMotion), value: state)
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(state.accessibilityLabel)
        .onAppear { animating = true }
        .onChange(of: state) { _, _ in animating = true }
    }

    // MARK: - Mascot

    private var mascot: some View {
        Image("EmberMascot", bundle: .module)
            .resizable()
            .scaledToFit()
            .saturation(state == .resting ? 0.45 : 1)
            .brightness(state == .resting ? -0.12 : 0)
            .shadow(
                color: glowColor.opacity(glowOpacity),
                radius: size * glowRadius
            )
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
        case .welcoming: 0.18
        case .gathering: 0.28
        case .arranging: 0.24
        case .remembering: 0.20
        case .celebrating: 0.38
        }
    }

    private var glowRadius: CGFloat {
        switch state {
        case .resting: 0
        case .welcoming: 0.06
        case .gathering: 0.09
        case .arranging: 0.08
        case .remembering: 0.07
        case .celebrating: 0.12
        }
    }

    /// Under Reduce Motion nothing scales or pulses; the state still reads through
    /// glow opacity and radius, which change immediately.
    private var pulseScale: CGFloat {
        guard !reduceMotion else { return 1 }
        return switch state {
        case .gathering, .arranging: animating ? 1.08 : 0.96
        case .celebrating: animating ? 1.12 : 1
        default: 1
        }
    }

    private var flickerOpacity: Double {
        1
    }

    private var pulseAnimation: Animation? {
        guard !reduceMotion else { return nil }
        switch state {
        case .gathering, .arranging:
            return .easeInOut(duration: 2.2).repeatForever(autoreverses: true)
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
