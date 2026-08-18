import KindlingUI
import SwiftUI

/// §14 screen 2, and the highest-risk screen in the product: blank-page freeze
/// hitting the exact problem the app exists to solve, before the user has gotten
/// any value. The sample chip is the direct mitigation, and its usage rate is the
/// leading indicator to watch.
struct TaskEntryScreen: View {
    @Binding var title: String
    let canContinue: Bool
    let onUseSample: () -> Void
    let onContinue: () -> Void

    @FocusState private var fieldFocused: Bool

    var body: some View {
        ScreenScaffold {
            VStack(alignment: .leading, spacing: Space.s3) {
                Text("What are you avoiding?")
                    .font(.kindlingTitle)
                    .foregroundStyle(KindlingColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                KindlingField(
                    placeholder: "What are you avoiding?",
                    text: $title,
                    isFocused: fieldFocused
                )
                .focused($fieldFocused)
                .submitLabel(.go)
                .onSubmit { if canContinue { onContinue() } }

                if title.isEmpty {
                    SampleTaskChip(text: "Not sure? Try: \(RescueFlowModel.sampleTask)", action: onUseSample)
                }

                Spacer()
            }
        } actions: {
            Button("Continue", action: onContinue)
                .buttonStyle(.kindlingPrimary)
                .disabled(!canContinue)
                .opacity(canContinue ? 1 : 0.5)
        }
        // Set in `.task`, not `onAppear`: the cursor has to survive the first layout
        // pass, or the keyboard appears without the field actually being focused.
        .task {
            fieldFocused = true
        }
    }
}

#Preview {
    TaskEntryScreen(title: .constant(""), canContinue: false, onUseSample: {}, onContinue: {})
}
