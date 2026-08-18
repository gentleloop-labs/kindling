import Foundation

/// Seam for the network call, so every failure path in `RemoteStepEngine` is
/// testable without a live endpoint or a stubbed URL protocol.
public protocol StepTransport: Sendable {
    func send(_ request: URLRequest) async throws -> (Data, URLResponse)
}

public struct URLSessionStepTransport: StepTransport {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func send(_ request: URLRequest) async throws -> (Data, URLResponse) {
        try await session.data(for: request)
    }
}
