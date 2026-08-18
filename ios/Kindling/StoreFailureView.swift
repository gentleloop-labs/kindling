import SwiftUI

/// Shown only when the shared store cannot be opened. Framed as something to fix,
/// not as an alert — no red, per the design system.
struct StoreFailureView: View {
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Text("Let's try that differently")
                .font(.system(.title2, design: .rounded).weight(.semibold))
            Text(message)
                .font(.system(.footnote, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
    }
}
