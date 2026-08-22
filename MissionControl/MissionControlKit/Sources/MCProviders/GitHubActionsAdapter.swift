import Foundation
import MCDomain

/// GitHub adapter (ADR-0012): fine-grained PAT, `.staticToken`. `externalRef` is
/// "owner/repo" (e.g. "LorenzoEmanuele00/mise_pwa"). Reports the most recent Actions run.
public struct GitHubActionsAdapter: ProviderAdapter {
    public let providerKind = ProviderKind.githubRepository
    private let session: URLSession
    private let apiVersion = "2022-11-28"

    public init(session: URLSession = .shared) {
        self.session = session
    }

    private func token(from credential: Data) throws -> String {
        guard let token = String(data: credential, encoding: .utf8), !token.isEmpty else {
            throw ProviderAdapterError.invalidCredential(reason: "not a UTF-8 token string")
        }
        return token
    }

    private func authorizedRequest(url: URL, token: String, etag: String?) -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue(apiVersion, forHTTPHeaderField: "X-GitHub-Api-Version")
        if let etag {
            request.setValue(etag, forHTTPHeaderField: "If-None-Match")
        }
        return request
    }

    public func validateCredential(_ credential: Data) async throws {
        let token = try token(from: credential)
        let request = authorizedRequest(url: URL(string: "https://api.github.com/user")!, token: token, etag: nil)
        let (_, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw ProviderAdapterError.invalidCredential(reason: "no HTTP response")
        }
        if http.statusCode == 401 || http.statusCode == 403 {
            throw ProviderAdapterError.credentialExpired
        }
        guard (200...299).contains(http.statusCode) else {
            throw ProviderAdapterError.invalidCredential(reason: "HTTP \(http.statusCode)")
        }
    }

    private struct RunsResponse: Decodable {
        struct Run: Decodable {
            let status: String
            let conclusion: String?
            let headSha: String
            let updatedAt: String

            enum CodingKeys: String, CodingKey {
                case status, conclusion
                case headSha = "head_sha"
                case updatedAt = "updated_at"
            }
        }
        let workflowRuns: [Run]
        enum CodingKeys: String, CodingKey {
            case workflowRuns = "workflow_runs"
        }
    }

    public func poll(externalRef: String, credential: Data, etag: String?) async -> PollOutcome {
        guard let token = try? token(from: credential) else {
            return .terminalFailure(reason: "invalid credential encoding")
        }
        guard let url = URL(string: "https://api.github.com/repos/\(externalRef)/actions/runs?per_page=1") else {
            return .terminalFailure(reason: "invalid externalRef '\(externalRef)'")
        }
        let request = authorizedRequest(url: url, token: token, etag: etag)

        let outcome: HTTPOutcome
        do {
            let (data, response) = try await session.data(for: request)
            outcome = HTTPOutcome.classify(response: response, data: data, error: nil)
        } catch {
            outcome = HTTPOutcome.classify(response: nil, data: nil, error: error)
        }

        switch outcome {
        case .notModified:
            providersLog.debug("GitHub poll: 304 not modified for \(externalRef, privacy: .public)")
            return .notModified
        case .terminal(let reason):
            providersLog.error("GitHub poll terminal failure for \(externalRef, privacy: .public): \(reason, privacy: .public)")
            return .terminalFailure(reason: reason)
        case .transient(let reason, let retryAfter):
            providersLog.info("GitHub poll transient failure for \(externalRef, privacy: .public): \(reason, privacy: .public)")
            return .transientFailure(reason: reason, retryAfter: retryAfter)
        case .success(let data, let newETag):
            guard let decoded = try? JSONDecoder().decode(RunsResponse.self, from: data),
                  let run = decoded.workflowRuns.first else {
                let payload = IntegrationPayload(headline: "No Actions runs yet", detail: externalRef)
                return .success(payload: payload, etag: newETag)
            }
            let statusText = run.conclusion ?? run.status
            let needsAttention = run.conclusion == "failure" || run.conclusion == "cancelled" || run.conclusion == "timed_out"
            // ADR-0006 burst-mode signal: no `conclusion` yet and `status` of `queued` or
            // `in_progress` means this run is still in flight.
            let workInFlight = run.conclusion == nil && (run.status == "queued" || run.status == "in_progress")
            let payload = IntegrationPayload(
                headline: "CI \(statusText)",
                detail: "\(run.headSha.prefix(7)) · \(run.updatedAt)",
                isAttentionNeeded: needsAttention,
                isWorkInFlight: workInFlight
            )
            return .success(payload: payload, etag: newETag)
        }
    }
}
