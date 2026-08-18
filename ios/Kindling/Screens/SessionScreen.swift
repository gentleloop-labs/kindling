import KindlingCore
import KindlingUI
import SwiftUI

/// §14 screen 4. Full-screen and calm: the ring, the Ember, the step, and Stop.
///
/// Nothing counts down in memory. `TimelineView` simply asks what time it is once a
/// second, and the remaining time is recomputed from the session's persisted start.
/// That is why closing the app, force-quitting it, or rebooting the phone cannot
/// desynchronise this screen.
struct SessionScreen: View {
    let snapshot: SessionSnapshot
    let step: String
    let onStop: () -> Void
    let onElapsed: () -> Void

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let clock = SessionClock.fixed(context.date)
            let phase = SessionRuntime.phase(of: snapshot, clock: clock)
            let remaining = SessionRuntime.remaining(of: snapshot, clock: clock)

            ScreenScaffold {
                VStack(spacing: Space.s4) {
                    Spacer()

                    TimerRing(
                        progress: SessionRuntime.progress(of: snapshot, clock: clock),
                        emberState: .focusing,
                        diameter: 240
                    )
                    .overlay(alignment: .bottom) {
                        Text(Self.format(remaining))
                            .font(.kindlingTitle)
                            .monospacedDigit()
                            .foregroundStyle(KindlingColor.textPrimary)
                            .offset(y: Space.s3)
                    }
                    .accessibilityElement()
                    .accessibilityLabel("\(Self.spoken(remaining)) remaining")

                    // The step stays visible for the whole session — the user should
                    // never have to remember what they were doing.
                    Text(step)
                        .font(.kindlingTitle)
                        .foregroundStyle(KindlingColor.textPrimary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer()
                }
            } actions: {
                // Always available, at every moment. Stopping is not a failure.
                Button("Stop", action: onStop)
                    .buttonStyle(.kindlingSecondary)
            }
            .onChange(of: phase == .elapsed) { _, elapsed in
                if elapsed { onElapsed() }
            }
        }
    }

    static func format(_ remaining: TimeInterval) -> String {
        let total = Int(remaining.rounded(.up))
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    static func spoken(_ remaining: TimeInterval) -> String {
        let total = Int(remaining.rounded(.up))
        let minutes = total / 60
        let seconds = total % 60
        if minutes > 0 && seconds > 0 { return "\(minutes) minutes \(seconds) seconds" }
        if minutes > 0 { return "\(minutes) minutes" }
        return "\(seconds) seconds"
    }
}

#Preview {
    SessionScreen(
        snapshot: SessionSnapshot(durationSeconds: 120, startedAt: .now.addingTimeInterval(-45)),
        step: "Open the conversation and read the last message.",
        onStop: {},
        onElapsed: {}
    )
}
