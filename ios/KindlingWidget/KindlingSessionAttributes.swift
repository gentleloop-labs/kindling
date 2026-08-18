import ActivityKit
import Foundation
import KindlingCore

/// The ActivityKit conformance is deliberately thin — all the shape and all the
/// privacy rules live in `LiveActivityPayload` in `KindlingCore`, where they are
/// testable without a simulator.
///
/// This file is compiled into both the app and the widget extension.
struct KindlingSessionAttributes: ActivityAttributes {
    typealias ContentState = LiveActivityPayload

    /// Static attributes only. Note there is no task title here either — not in the
    /// content state and not in the attributes.
    let durationSeconds: Int
}
