import SwiftUI

/// The 8pt grid. Nothing in the app should use a spacing value from outside it.
public enum Space {
    public static let s1: CGFloat = 8
    public static let s2: CGFloat = 16
    public static let s3: CGFloat = 24
    public static let s4: CGFloat = 32
    public static let s5: CGFloat = 40
    public static let s6: CGFloat = 48
}

public enum KindlingLayout {
    /// One radius, on fields, cards, and buttons alike. Mixed radii read as
    /// unintentional design, so there is exactly one value and no second one.
    public static let radius: CGFloat = 18

    /// Enforced on every control. Applied via `.kindlingTapTarget()`.
    public static let minTapTarget: CGFloat = 48
}

public enum KindlingMotion {
    public static let duration: Double = 0.22

    /// Soft ease-in-out, no springy overshoot. The single deliberate exception is
    /// the celebration bloom.
    public static let standard = Animation.easeInOut(duration: duration)

    /// Resolves motion against the user's setting. Under Reduce Motion there is no
    /// shortened animation and no movement — state changes land immediately, and
    /// callers swap movement for an opacity change.
    public static func standard(reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : standard
    }
}

public extension View {
    /// Guarantees the 48×48pt minimum without changing visual weight.
    func kindlingTapTarget() -> some View {
        frame(minWidth: KindlingLayout.minTapTarget, minHeight: KindlingLayout.minTapTarget)
    }
}
