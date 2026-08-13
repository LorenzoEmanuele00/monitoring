import Testing
@testable import MCProviders
import MCDomain
import Foundation

/// Stubs `URLSession` at the `URLProtocol` layer so adapter tests run fully offline and
/// deterministically — no dependency on GitHub's real API being reachable or mise_pwa's
/// real Actions history.
final class StubURLProtocol: URLProtocol {
    nonisolated(unsafe) static var handler: ((URLRequest) -> (Int, [String: String], Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = StubURLProtocol.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        let (status, headers, data) = handler(request)
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: status,
            httpVersion: "HTTP/1.1",
            headerFields: headers
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

@Suite(.serialized) struct GitHubActionsAdapterTests {
    private func stubbedSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]
        return URLSession(configuration: config)
    }

    @Test func pollSuccessParsesLatestRun() async {
        StubURLProtocol.handler = { _ in
            let json = """
            {"workflow_runs":[{"status":"completed","conclusion":"success","head_sha":"abcdef1234567","updated_at":"2026-08-14T00:00:00Z"}]}
            """
            return (200, ["ETag": "\"run-etag\""], Data(json.utf8))
        }
        let adapter = GitHubActionsAdapter(session: stubbedSession())
        let outcome = await adapter.poll(
            externalRef: "LorenzoEmanuele00/mise_pwa",
            credential: Data("ghp_test".utf8),
            etag: nil
        )
        guard case .success(let payload, let etag) = outcome else {
            Issue.record("expected success, got \(outcome)")
            return
        }
        #expect(payload.headline == "CI success")
        #expect(payload.isAttentionNeeded == false)
        #expect(etag == "\"run-etag\"")
    }

    @Test func pollNotModifiedOn304() async {
        StubURLProtocol.handler = { _ in (304, [:], Data()) }
        let adapter = GitHubActionsAdapter(session: stubbedSession())
        let outcome = await adapter.poll(
            externalRef: "LorenzoEmanuele00/mise_pwa",
            credential: Data("ghp_test".utf8),
            etag: "\"run-etag\""
        )
        guard case .notModified = outcome else {
            Issue.record("expected notModified, got \(outcome)")
            return
        }
    }

    @Test func pollTerminalFailureOn401() async {
        StubURLProtocol.handler = { _ in (401, [:], Data()) }
        let adapter = GitHubActionsAdapter(session: stubbedSession())
        let outcome = await adapter.poll(
            externalRef: "LorenzoEmanuele00/mise_pwa",
            credential: Data("ghp_bad".utf8),
            etag: nil
        )
        guard case .terminalFailure = outcome else {
            Issue.record("expected terminalFailure, got \(outcome)")
            return
        }
    }

    @Test func pollTransientFailureOn503() async {
        StubURLProtocol.handler = { _ in (503, [:], Data()) }
        let adapter = GitHubActionsAdapter(session: stubbedSession())
        let outcome = await adapter.poll(
            externalRef: "LorenzoEmanuele00/mise_pwa",
            credential: Data("ghp_test".utf8),
            etag: nil
        )
        guard case .transientFailure = outcome else {
            Issue.record("expected transientFailure, got \(outcome)")
            return
        }
    }

    @Test func pollTransientFailureCarriesRetryAfter() async {
        // ADR-0008: "Retry-After" must be threaded through to `PollOutcome.transientFailure`,
        // not discarded, so `RetryPolicy` can honour it as a hard floor on the next attempt.
        StubURLProtocol.handler = { _ in (503, ["Retry-After": "7"], Data()) }
        let adapter = GitHubActionsAdapter(session: stubbedSession())
        let outcome = await adapter.poll(
            externalRef: "LorenzoEmanuele00/mise_pwa",
            credential: Data("ghp_test".utf8),
            etag: nil
        )
        guard case .transientFailure(_, let retryAfter) = outcome else {
            Issue.record("expected transientFailure, got \(outcome)")
            return
        }
        #expect(retryAfter == 7)
    }

    @Test func failedRunFlagsAttentionNeeded() async {
        StubURLProtocol.handler = { _ in
            let json = """
            {"workflow_runs":[{"status":"completed","conclusion":"failure","head_sha":"abcdef1234567","updated_at":"2026-08-14T00:00:00Z"}]}
            """
            return (200, [:], Data(json.utf8))
        }
        let adapter = GitHubActionsAdapter(session: stubbedSession())
        let outcome = await adapter.poll(
            externalRef: "LorenzoEmanuele00/mise_pwa",
            credential: Data("ghp_test".utf8),
            etag: nil
        )
        guard case .success(let payload, _) = outcome else {
            Issue.record("expected success, got \(outcome)")
            return
        }
        #expect(payload.isAttentionNeeded == true)
    }
}
