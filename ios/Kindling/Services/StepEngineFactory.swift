import Foundation
import KindlingCore

/// Builds the step engine for this device, this build, and this user's choice.
///
/// Preference order, and why:
/// 1. **On-device** (Apple Intelligence) — the task text never leaves the phone,
///    works offline, costs nothing. Always preferred when the hardware allows.
/// 2. **Hosted** (Cloudflare Worker → OpenAI) — only when the user has opted in
///    *and* the build has an endpoint. This is the only path where task text
///    leaves the device.
/// 3. **Template** — the floor, inside `StepEngineChain`. Never skipped.
enum StepEngineFactory {
    static func make(aiEnabled: Bool) -> any AsyncStepSuggesting {
        guard aiEnabled else {
            // Opted out: local template only. No generators, so no chance of a call.
            return LocalStepEngine()
        }

        var generators: [any StepGenerating] = []

        if #available(iOS 26.0, *) {
            // Cheap to construct; the chain skips it at request time when the
            // device is ineligible or Apple Intelligence is switched off.
            generators.append(OnDeviceStepGenerator())
        }

        if let configuration = remoteConfiguration() {
            generators.append(RemoteStepGenerator(configuration: configuration))
        }

        return StepEngineChain(generators: generators)
    }

    /// True when *some* AI path could work on this device and build — used to
    /// decide whether the settings toggle is worth showing at all.
    static var isAnyAIConfigured: Bool {
        if #available(iOS 26.0, *), OnDeviceStepGenerator.unavailableReason == nil { return true }
        return remoteConfiguration() != nil
    }

    /// Shown under the settings toggle so an ineligible device explains itself
    /// instead of appearing broken.
    static var onDeviceStatus: String? {
        guard #available(iOS 26.0, *) else {
            return "On-device steps need iOS 26 or later."
        }
        return OnDeviceStepGenerator.unavailableReason
    }

    static var isRemoteConfigured: Bool { remoteConfiguration() != nil }

    private static func remoteConfiguration() -> RemoteStepGenerator.Configuration? {
        let bundle = Bundle.main
        guard
            let host = bundle.object(forInfoDictionaryKey: "KindlingStepHost") as? String,
            let token = bundle.object(forInfoDictionaryKey: "KindlingAppToken") as? String,
            !host.isEmpty, !token.isEmpty,
            host != "kindling-step.example.workers.dev",
            // The scheme is added here because xcconfig reads "//" as a comment, so
            // the host is stored bare and can never accidentally be plain http.
            let endpoint = URL(string: "https://\(host)/")
        else { return nil }

        return RemoteStepGenerator.Configuration(endpoint: endpoint, appToken: token)
    }
}
