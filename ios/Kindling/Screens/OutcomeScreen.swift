import KindlingCore
import KindlingUI
import SwiftUI

/// §14 screen 5. Three choices at identical weight, size, and emphasis.
///
/// The equal treatment is the feature. Any hierarchy here — a filled primary, a
/// larger tap area, even ordering that reads as best-to-worst — would imply a right
/// answer, and implying a right answer is exactly the shame this product exists to
/// avoid. There is no fourth, failure option, at any level of the stack.
struct OutcomeScreen: View {
    let onChoose: (SessionOutcome) -> Void

    var body: some View {
        ScreenScaffold {
            VStack(spacing: Space.s3) {
                Spacer()

                Text("How did that go?")
                    .font(.kindlingTitle)
                    .foregroundStyle(KindlingColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()
            }
        } actions: {
            VStack(spacing: Space.s2) {
                Button("Keep going") { onChoose(.keptGoing) }
                Button("That's enough for now") { onChoose(.stoppedEnough) }
                Button("I got distracted") { onChoose(.distracted) }
            }
            // One style for all three, applied once so they cannot drift apart.
            .buttonStyle(.kindlingEqual)
        }
    }
}

#Preview { OutcomeScreen { _ in } }
