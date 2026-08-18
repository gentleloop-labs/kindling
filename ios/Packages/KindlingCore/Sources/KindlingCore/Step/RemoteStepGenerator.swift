import Foundation

/// Step generation via the Cloudflare Worker, which holds the OpenAI key.
///
/// The key is deliberately **not** here: anything shipped in the app binary can be
/// extracted from it. This type knows only an endpoint and a rotatable app token.
///
/// It throws on every failure and lets `StepEngineChain` decide what happens next.
public struct RemoteStepGenerator: StepGenerating {
    public struct Configuration: Sendable {
        public var endpoint: URL
        public var appToken: String
        /// Client-side ceiling, deliberately tighter than the Worker's own upstream
        /// timeout so the app gives up first rather than waiting on a proxy that is
        /// itself waiting. Latency is the product risk here: the person is frozen.
        public var timeout: TimeInterval

        /// 6s, from measurement: gpt-5.2 at effort=low returned in 1.4-3.0s across
        /// real tasks, so 3.5s (the first guess) would have discarded good answers
        /// and made AI-vs-template look random to the user. Still below the
        /// Worker's own 7s ceiling so the app is the one that gives up first.
        public init(endpoint: URL, appToken: String, timeout: TimeInterval = 6.0) {
            self.endpoint = endpoint
            self.appToken = appToken
            self.timeout = timeout
        }
    }

    private let configuration: Configuration
    private let transport: any StepTransport

    public let provider: AiProvider = .api

    public init(configuration: Configuration, transport: any StepTransport = URLSessionStepTransport()) {
        self.configuration = configuration
        self.transport = transport
    }

    public func generateStep(for task: String, attempt: Int) async throws -> String {
        guard let body = try? JSONEncoder().encode(RequestBody(task: task, attempt: attempt)) else {
            throw StepGenerationError.badResponse
        }

        var request = URLRequest(url: configuration.endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = configuration.timeout
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(configuration.appToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = body

        // Any transport error — offline, DNS, TLS, timeout, cancellation — propagates.
        let (data, response) = try await transport.send(request)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw StepGenerationError.badResponse
        }
        guard let decoded = try? JSONDecoder().decode(ResponseBody.self, from: data) else {
            throw StepGenerationError.badResponse
        }
        let step = decoded.step.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !step.isEmpty else { throw StepGenerationError.emptyStep }
        return step
    }

    private struct RequestBody: Encodable {
        let task: String
        let attempt: Int
    }

    private struct ResponseBody: Decodable {
        let step: String
    }
}
