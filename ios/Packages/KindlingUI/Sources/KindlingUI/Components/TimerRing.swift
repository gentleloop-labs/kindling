import SwiftUI

/// A circular ring in the accent color with the Ember centered inside.
///
/// **The color never shifts as time runs low.** There is no amber, no red, no
/// urgency cue — running out of time is not a failure, and the palette says so.
/// There is also no numeric percentage: the ring and the remaining time are
/// enough, and a completion figure invites a score.
public struct TimerRing: View {
    let progress: Double
    let emberState: EmberState
    let diameter: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(progress: Double, emberState: EmberState = .focusing, diameter: CGFloat = 260) {
        self.progress = min(1, max(0, progress))
        self.emberState = emberState
        self.diameter = diameter
    }

    public var body: some View {
        ZStack {
            Circle()
                .stroke(KindlingColor.surfaceStrong, lineWidth: 12)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(KindlingColor.accent, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(KindlingMotion.standard(reduceMotion: reduceMotion), value: progress)

            EmberView(state: emberState, size: diameter * 0.45)
        }
        .frame(width: diameter, height: diameter)
        // The ring is decoration over information the screen states in words.
        .accessibilityHidden(true)
    }
}
