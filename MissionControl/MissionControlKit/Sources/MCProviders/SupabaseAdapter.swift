import Foundation
import MCDomain

/// Supabase adapter (ADR-0012): Management API personal access token, `.staticToken`.
/// `service_role` key explicitly out of scope. `externalRef` is the Supabase project ref.
public struct SupabaseAdapter: ProviderAdapter {
    public let providerKind = ProviderKind.supabaseProject
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    private func token(from credential: Data) throws -> String {
        guard let token = String(data: credential, encoding: .utf8), !token.isEmpty else {
            throw ProviderAdapterError.invalidCredential(reason: "not a UTF-8 token string")
        }
        return token
    }

    public func validateCredential(_ credential: Data) async throws {
        let token = try token(from: credential)
        var request = URLRequest(url: URL(string: "https://api.supabase.com/v1/organizations")!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
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

    private struct ProjectResponse: Decodable {
        let status: String
        let name: String
    }

    public func poll(externalRef: String, credential: Data, etag: String?) async -> PollOutcome {
        guard let token = try? token(from: credential) else {
            return .terminalFailure(reason: "invalid credential encoding")
        }
        guard let url = URL(string: "https://api.supabase.com/v1/projects/\(externalRef)") else {
            return .terminalFailure(reason: "invalid externalRef '\(externalRef)'")
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        if let etag {
            request.setValue(etag, forHTTPHeaderField: "If-None-Match")
        }

        let outcome: HTTPOutcome
        do {
            let (data, response) = try await session.data(for: request)
            outcome = HTTPOutcome.classify(response: response, data: data, error: nil)
        } catch {
            outcome = HTTPOutcome.classify(response: nil, data: nil, error: error)
        }

        switch outcome {
        case .notModified:
            return .notModified
        case .terminal(let reason):
            providersLog.error("Supabase poll terminal failure for \(externalRef, privacy: .public): \(reason, privacy: .public)")
            return .terminalFailure(reason: reason)
        case .transient(let reason, let retryAfter):
            providersLog.info("Supabase poll transient failure for \(externalRef, privacy: .public): \(reason, privacy: .public)")
            return .transientFailure(reason: reason, retryAfter: retryAfter)
        case .success(let data, let newETag):
            guard let decoded = try? JSONDecoder().decode(ProjectResponse.self, from: data) else {
                let payload = IntegrationPayload(headline: "Unknown status", detail: externalRef)
                return .success(payload: payload, etag: newETag)
            }
            let needsAttention = decoded.status != "ACTIVE_HEALTHY"
            let payload = IntegrationPayload(
                headline: decoded.status,
                detail: decoded.name,
                isAttentionNeeded: needsAttention
            )
            return .success(payload: payload, etag: newETag)
        }
    }
}
