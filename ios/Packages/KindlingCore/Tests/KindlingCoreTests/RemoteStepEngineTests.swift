import Foundation
import Testing
@testable import KindlingCore

/// A step suggestion has no user-visible failure case. Everything below exists to
/// prove that: however the generators misbehave, the user gets a usable step.
struct StepEngineChainTests {
    // MARK: - Doubles

    struct StubGenerator: StepGenerating {
        let provider: AiProvider
        let available: Bool
        let handler: @Sendable (String, Int) async throws -> String
        var isAvailable: Bool { get async { available } }
        func generateStep(for task: String, attempt: Int) async throws -> String {
            try await handler(task, attempt)
        }
        init(
            provider: AiProvider = .api,
            available: Bool = true,
            handler: @escaping @Sendable (String, Int) async throws -> String
        ) {
            self.provider = provider
            self.available = available
            self.handler = handler
        }
    }

    struct BoomError: Error {}

    static func templateStep(_ task: String, _ attempt: Int = 0) -> String {
        TemplateStepEngine().suggestFirstStep(for: task, attempt: attempt)
    }

    // MARK: - Happy path

    @Test("a valid generated step is used and marked as AI")
    func success() async {
        let chain = StepEngineChain(generators: [StubGenerator { _, _ in "Open the thread and read her last message." }])
        let result = await chain.suggestFirstStep(for: "talking to a friend", attempt: 0)
        #expect(result.text == "Open the thread and read her last message.")
        #expect(result.origin == .ai)
        #expect(result.attemptedRemote)
    }

    @Test("the generator receives the normalized task and clamped attempt")
    func normalization() async {
        let seen = SeenInput()
        let chain = StepEngineChain(generators: [StubGenerator { task, attempt in
            seen.store(task: task, attempt: attempt)
            return "Open it."
        }])
        _ = await chain.suggestFirstStep(for: "  reply   to the  email ", attempt: -3)
        #expect(seen.task == "reply to the email")
        #expect(seen.attempt == 0, "a negative attempt is clamped, never passed through")
    }

    // MARK: - Ordering: this is why the chain exists

    @Test("on-device is preferred, and the hosted call is not made when it succeeds")
    func onDevicePreferred() async {
        let remoteCalled = Flag()
        let chain = StepEngineChain(generators: [
            StubGenerator(provider: .onDevice) { _, _ in "Put your shoes by the door." },
            StubGenerator(provider: .api) { _, _ in remoteCalled.set(); return "unused" },
        ])
        let result = await chain.suggestFirstStep(for: "go for a run", attempt: 0)
        #expect(result.text == "Put your shoes by the door.")
        #expect(!remoteCalled.value, "no task text should leave the device when on-device works")
    }

    @Test("an ineligible device falls through to the hosted call")
    func ineligibleDeviceFallsThrough() async {
        let chain = StepEngineChain(generators: [
            StubGenerator(provider: .onDevice, available: false) { _, _ in
                Issue.record("an unavailable generator must not be called")
                return ""
            },
            StubGenerator(provider: .api) { _, _ in "Open the conversation." },
        ])
        let result = await chain.suggestFirstStep(for: "talking to a friend", attempt: 0)
        #expect(result.text == "Open the conversation.")
        #expect(result.origin == .ai)
    }

    @Test("a throwing on-device model falls through to the hosted call")
    func onDeviceErrorFallsThrough() async {
        let chain = StepEngineChain(generators: [
            StubGenerator(provider: .onDevice) { _, _ in throw BoomError() },
            StubGenerator(provider: .api) { _, _ in "Open the conversation." },
        ])
        #expect(await chain.suggestFirstStep(for: "talking to a friend", attempt: 0).origin == .ai)
    }

    // MARK: - Everything failing still yields a step

    @Test("every generator failing falls back to the template", arguments: [
        "throws", "empty", "whitespace", "overlong",
    ])
    func allFailuresFallBack(kind: String) async {
        let long = String(repeating: "a", count: 400)
        let chain = StepEngineChain(generators: [StubGenerator { _, _ in
            switch kind {
            case "throws": throw BoomError()
            case "empty": return ""
            case "whitespace": return "   \n  "
            default: return long
            }
        }])
        let result = await chain.suggestFirstStep(for: "reply to the email", attempt: 0)
        #expect(result.text == Self.templateStep("reply to the email"))
        #expect(result.origin == .template)
        #expect(result.attemptedRemote, "a fallback still counts as an attempt for AiRequestLog")
        #expect(!result.text.isEmpty, "a failure must never produce an empty step")
    }

    @Test("an implausible step from the first generator lets the second answer")
    func implausibleFallsThrough() async {
        let chain = StepEngineChain(generators: [
            StubGenerator(provider: .onDevice) { _, _ in String(repeating: "b", count: 400) },
            StubGenerator(provider: .api) { _, _ in "Open the bill." },
        ])
        #expect(await chain.suggestFirstStep(for: "pay electricity bill", attempt: 0).text == "Open the bill.")
    }

    @Test("an empty task never reaches a generator")
    func emptyTaskNotSent() async {
        let called = Flag()
        let chain = StepEngineChain(generators: [StubGenerator { _, _ in called.set(); return "x" }])
        let result = await chain.suggestFirstStep(for: "   ", attempt: 0)
        #expect(!called.value)
        #expect(!result.attemptedRemote)
        #expect(result.text.hasPrefix("Type the thing"))
    }

    @Test("no generators at all is just the template engine")
    func noGenerators() async {
        let result = await StepEngineChain(generators: []).suggestFirstStep(for: "clean my desk", attempt: 0)
        #expect(result.origin == .template)
        #expect(!result.attemptedRemote)
        #expect(result.text.hasPrefix("Pick up one visible item"))
    }

    @Test("the local engine needs no generators and no network")
    func localEngine() async {
        let result = await LocalStepEngine().suggestFirstStep(for: "clean my desk", attempt: 0)
        #expect(result.origin == .template)
        #expect(!result.attemptedRemote)
    }
}

/// The hosted generator's own wire handling, separate from chain behaviour.
struct RemoteStepGeneratorTests {
    struct StubTransport: StepTransport {
        let result: @Sendable (URLRequest) throws -> (Data, URLResponse)
        func send(_ request: URLRequest) async throws -> (Data, URLResponse) { try result(request) }
    }

    static let endpoint = URL(string: "https://example.invalid/step")!

    static func generator(
        _ handler: @escaping @Sendable (URLRequest) throws -> (Data, URLResponse)
    ) -> RemoteStepGenerator {
        RemoteStepGenerator(
            configuration: .init(endpoint: endpoint, appToken: "secret-token"),
            transport: StubTransport(result: handler)
        )
    }

    static func http(_ status: Int, _ json: String) -> @Sendable (URLRequest) throws -> (Data, URLResponse) {
        { _ in (Data(json.utf8), HTTPURLResponse(url: endpoint, statusCode: status, httpVersion: nil, headerFields: nil)!) }
    }

    @Test("the request carries the bearer token and a JSON body")
    func requestShape() async throws {
        let captured = Captured()
        let generator = RemoteStepGenerator(
            configuration: .init(endpoint: Self.endpoint, appToken: "secret-token"),
            transport: StubTransport { request in
                captured.store(request)
                return (Data(#"{"step":"Open it."}"#.utf8),
                        HTTPURLResponse(url: Self.endpoint, statusCode: 200, httpVersion: nil, headerFields: nil)!)
            }
        )
        _ = try await generator.generateStep(for: "reply to the email", attempt: 2)

        let request = try #require(captured.value)
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer secret-token")
        let body = try #require(request.httpBody)
        let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(json["task"] as? String == "reply to the email")
        #expect(json["attempt"] as? Int == 2)
    }

    /// These are the exact statuses the Worker returns, verified against it locally.
    @Test("non-200 responses throw", arguments: [400, 401, 405, 429, 500, 502, 504])
    func nonSuccessThrows(status: Int) async {
        let generator = Self.generator(Self.http(status, #"{"error":"nope"}"#))
        await #expect(throws: (any Error).self) {
            try await generator.generateStep(for: "reply to the email", attempt: 0)
        }
    }

    @Test("a malformed body throws")
    func malformedThrows() async {
        let generator = Self.generator(Self.http(200, "not json"))
        await #expect(throws: (any Error).self) {
            try await generator.generateStep(for: "reply to the email", attempt: 0)
        }
    }

    @Test("an empty step throws rather than reaching the user")
    func emptyStepThrows() async {
        let generator = Self.generator(Self.http(200, #"{"step":"   "}"#))
        await #expect(throws: StepGenerationError.emptyStep) {
            try await generator.generateStep(for: "reply to the email", attempt: 0)
        }
    }
}

// MARK: - Small boxes for capturing values out of @Sendable closures

final class Captured: @unchecked Sendable {
    private let lock = NSLock()
    private var stored: URLRequest?
    var value: URLRequest? { lock.lock(); defer { lock.unlock() }; return stored }
    func store(_ request: URLRequest) { lock.lock(); defer { lock.unlock() }; stored = request }
}

final class Flag: @unchecked Sendable {
    private let lock = NSLock()
    private var flag = false
    var value: Bool { lock.lock(); defer { lock.unlock() }; return flag }
    func set() { lock.lock(); defer { lock.unlock() }; flag = true }
}

final class SeenInput: @unchecked Sendable {
    private let lock = NSLock()
    private var storedTask = ""
    private var storedAttempt = -1
    var task: String { lock.lock(); defer { lock.unlock() }; return storedTask }
    var attempt: Int { lock.lock(); defer { lock.unlock() }; return storedAttempt }
    func store(task: String, attempt: Int) {
        lock.lock(); defer { lock.unlock() }
        storedTask = task; storedAttempt = attempt
    }
}

/// The provider recorded on the suggestion decides what `AiRequestLog` says about
/// whether anything left the device — so it has to be right.
struct StepProviderAttributionTests {
    @Test("an on-device success is attributed to on_device, not api")
    func onDeviceAttribution() async {
        let chain = StepEngineChain(generators: [
            StepEngineChainTests.StubGenerator(provider: .onDevice) { _, _ in "Put your shoes by the door." },
            StepEngineChainTests.StubGenerator(provider: .api) { _, _ in "unused" },
        ])
        let result = await chain.suggestFirstStep(for: "go for a run", attempt: 0)
        #expect(result.provider == .onDevice)
    }

    @Test("a hosted success after an on-device failure is attributed to api")
    func hostedAttribution() async {
        let chain = StepEngineChain(generators: [
            StepEngineChainTests.StubGenerator(provider: .onDevice) { _, _ in throw StepGenerationError.unavailable },
            StepEngineChainTests.StubGenerator(provider: .api) { _, _ in "Open the conversation." },
        ])
        let result = await chain.suggestFirstStep(for: "talking to a friend", attempt: 0)
        #expect(result.provider == .api)
        #expect(result.origin == .ai)
    }
}

/// Prewarming is a hint, never a requirement — it must be safe to call on any
/// chain, including one with no generators at all.
struct PrewarmTests {
    struct CountingGenerator: StepGenerating {
        let provider: AiProvider = .onDevice
        let counter: Flag
        func generateStep(for task: String, attempt: Int) async throws -> String { "x" }
        func prewarm() { counter.set() }
    }

    @Test("prewarm reaches every generator")
    func reachesGenerators() {
        let flag = Flag()
        StepEngineChain(generators: [CountingGenerator(counter: flag)]).prewarm()
        #expect(flag.value)
    }

    @Test("prewarm is safe with no generators and on the local engine")
    func safeWhenEmpty() {
        StepEngineChain(generators: []).prewarm()
        LocalStepEngine().prewarm()
    }
}
