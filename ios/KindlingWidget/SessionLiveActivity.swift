import ActivityKit
import KindlingCore
import KindlingUI
import SwiftUI
import WidgetKit

/// The lock-screen and Dynamic Island presentation.
///
/// Every countdown here is `Text(timerInterval:)` over the payload's date range, so
/// the OS does the ticking. Nothing in this file interpolates user content — the
/// only text shown is the fixed headline from `KindlingCore`.
struct SessionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: KindlingSessionAttributes.self) { context in
            // Lock screen / banner.
            HStack(spacing: Space.s2) {
                EmberView(state: .focusing, size: 44)

                VStack(alignment: .leading, spacing: 2) {
                    Text(context.state.headline)
                        .font(.kindlingCaption)
                        .foregroundStyle(KindlingColor.textSecondary)
                    Text(timerInterval: context.state.window, countsDown: true)
                        .font(.kindlingTitle)
                        .monospacedDigit()
                        .foregroundStyle(KindlingColor.textPrimary)
                }

                Spacer()
            }
            .padding(Space.s2)
            .activityBackgroundTint(KindlingColor.surface)
            .activitySystemActionForegroundColor(KindlingColor.accent)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    EmberView(state: .focusing, size: 36)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerInterval: context.state.window, countsDown: true)
                        .font(.kindlingTitle)
                        .monospacedDigit()
                        .foregroundStyle(KindlingColor.textPrimary)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.headline)
                        .font(.kindlingCaption)
                        .foregroundStyle(KindlingColor.textSecondary)
                }
            } compactLeading: {
                EmberView(state: .focusing, size: 18)
            } compactTrailing: {
                Text(timerInterval: context.state.window, countsDown: true)
                    .monospacedDigit()
                    .frame(maxWidth: 44)
                    .foregroundStyle(KindlingColor.textPrimary)
            } minimal: {
                EmberView(state: .focusing, size: 18)
            }
            .keylineTint(KindlingColor.accent)
        }
    }
}
