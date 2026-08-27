import KindlingUI
import SwiftUI

/// The shared page frame, and the one layout decision in the app that carries a
/// product argument.
///
/// Content scrolls; **actions are pinned to the bottom and never scroll away.** At
/// the largest Dynamic Type sizes a naive centred layout pushes the primary button
/// off-screen — and burying "Start" behind a scroll, in an app whose entire purpose
/// is helping someone start, would be a real failure rather than a cosmetic one.
/// So the reading content gives way and the action never does.
///
/// At normal sizes nothing scrolls and the `minHeight` lets `Spacer` distribute
/// space exactly as a plain `VStack` would, so the calm, centred feel is unchanged.
struct ScreenScaffold<Content: View, Actions: View>: View {
    @ViewBuilder var content: Content
    @ViewBuilder var actions: Actions

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { proxy in
                ScrollView {
                    content
                        .padding(.horizontal, Space.s3)
                        .padding(.top, Space.s4)
                        // A vertical ScrollView sizes its child to the child's
                        // intrinsic width unless we claim the viewport. Centered
                        // screens would otherwise be centered inside their
                        // longest line of text instead of the device.
                        .frame(
                            maxWidth: .infinity,
                            minHeight: proxy.size.height,
                            alignment: .top
                        )
                }
                .scrollBounceBehavior(.basedOnSize)
            }

            actions
                .padding(.horizontal, Space.s3)
                .padding(.top, Space.s2)
                .padding(.bottom, Space.s3)
        }
        .background(KindlingColor.background)
    }
}

extension ScreenScaffold where Actions == EmptyView {
    init(@ViewBuilder content: () -> Content) {
        self.init(content: content, actions: { EmptyView() })
    }
}
