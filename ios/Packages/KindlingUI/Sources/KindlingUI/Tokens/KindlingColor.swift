import SwiftUI

/// The §13 palette, backed by an asset catalog with light and dark variants.
///
/// Values are ported once from `design/tokens.css` and the names deliberately
/// mirror the CSS custom properties, so the landing page, the browser prototype,
/// and the app cannot drift apart. **Do not re-derive a color here** — the WCAG
/// pass recorded in `docs/design-tokens.md` was run against these exact values.
public enum KindlingColor {
    // MARK: Structural

    public static let background = color("background")
    public static let surface = color("surface")
    public static let surfaceStrong = color("surfaceStrong")

    // MARK: Text and interaction
    //
    // The light accent is `#A9471C`, not the Ember's `#E8703A`. The bright orange
    // reaches only 2.87:1 on warm paper, which fails both body text and UI
    // boundaries; it survives as decoration only.

    public static let textPrimary = color("textPrimary")
    public static let textSecondary = color("textSecondary")
    public static let accent = color("accent")
    public static let accentInk = color("accentInk")

    /// Focus is drawn with the interactive accent, never with glow alone.
    public static let focus = accent

    // MARK: Decorative only
    //
    // These three must never carry information: no text, no focus indicator, no
    // essential boundary. Light glow on light background is 1.88:1 and light
    // celebration gold is 1.71:1 — invisible as meaning. Any label placed near
    // them uses a passing text token instead.

    public static let ember = color("ember")
    public static let glow = color("glow")
    public static let celebration = color("celebration")

    /// There is deliberately no error or destructive color.
    ///
    /// No red appears anywhere in this system, including the timer's final
    /// seconds. Errors are primary text plus an icon or a plain sentence; the
    /// no-failure-state principle applies to color, not only to copy.

    private static func color(_ name: String) -> Color {
        Color(name, bundle: .module)
    }
}
