import SwiftUI

/// SF Pro Rounded throughout — native, free, and it gets full Dynamic Type support
/// with no extra engineering. Every style below scales with the user's setting;
/// none uses a fixed point size.
public extension Font {
    /// The suggested first step and the timer. The one thing on screen that matters.
    static let kindlingDisplay = Font.system(.largeTitle, design: .rounded).weight(.semibold)
    static let kindlingTitle = Font.system(.title2, design: .rounded).weight(.semibold)
    static let kindlingBody = Font.system(.body, design: .rounded)
    static let kindlingButton = Font.system(.body, design: .rounded).weight(.medium)
    /// The task echoed back, and secondary hints.
    static let kindlingCaption = Font.system(.subheadline, design: .rounded)
}
