import Foundation
import MCDomain
import os

/// Firebase Hosting adapter (ADR-0012): GCP service-account JSON key, `.serviceAccountKey`.
/// Does the JWT-bearer -> OAuth2 access-token exchange itself; the resulting short-lived
/// access token is cached in memory only (never persisted), per ADR-0012.
/// `externalRef` is the Firebase Hosting site ID.
public final class FirebaseHostingAdapter: ProviderAdapter, @unchecked Sendable {
    public let providerKind = ProviderKind.firebaseHosting
    private let session: URLSession
    private let scope = "https://www.googleapis.com/auth/cloud-platform.read-only"

    /// In-memory-only access-token cache (ADR-0012). Never written to Tier A, never
    /// serialised. `OSAllocatedUnfairLock`'s `withLock` is a synchronous closure, so it's
    /// safe to call from an `async` function (unlike `NSLock.lock()`/`unlock()`, which the
    /// Swift 6 concurrency checker rejects directly inside `async` bodies).
    private let cachedToken = OSAllocatedUnfairLock<(value: String, expiresAt: Date)?>(initialState: nil)

    public init(session: URLSession = .shared) {
        self.session = session
    }

    struct ServiceAccountKey: Decodable {
        let type: String
        let clientEmail: String
        let privateKey: String
        let tokenURI: String

        enum CodingKeys: String, CodingKey {
            case type
            case clientEmail = "client_email"
            case privateKey = "private_key"
            case tokenURI = "token_uri"
        }
    }

    private func serviceAccount(from credential: Data) throws -> ServiceAccountKey {
        guard let key = try? JSONDecoder().decode(ServiceAccountKey.self, from: credential) else {
            throw ProviderAdapterError.invalidCredential(reason: "not a valid service-account JSON key")
        }
        guard key.type == "service_account" else {
            throw ProviderAdapterError.invalidCredential(reason: "JSON key is not type 'service_account'")
        }
        return key
    }

    private struct TokenResponse: Decodable {
        let accessToken: String
        let expiresIn: Int
        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case expiresIn = "expires_in"
        }
    }

    private func accessToken(for account: ServiceAccountKey) async throws -> String {
        let cached = cachedToken.withLock { $0 }
        if let cached, cached.expiresAt > Date().addingTimeInterval(60) {
            return cached.value
        }

        let assertion = try JWTBearerSigner.signAssertion(
            clientEmail: account.clientEmail,
            privateKeyPEM: account.privateKey,
            scope: scope,
            audience: account.tokenURI
        )

        var request = URLRequest(url: URL(string: account.tokenURI)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let body = "grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=\(assertion)"
        request.httpBody = Data(body.utf8)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw ProviderAdapterError.credentialExpired
        }
        guard let decoded = try? JSONDecoder().decode(TokenResponse.self, from: data) else {
            throw ProviderAdapterError.malformedResponse(reason: "token exchange response")
        }

        let newValue = (value: decoded.accessToken, expiresAt: Date().addingTimeInterval(TimeInterval(decoded.expiresIn)))
        cachedToken.withLock { $0 = newValue }
        return decoded.accessToken
    }

    public func validateCredential(_ credential: Data) async throws {
        let account = try serviceAccount(from: credential)
        _ = try await accessToken(for: account)
    }

    private struct ReleasesResponse: Decodable {
        struct Release: Decodable {
            let name: String
            let releaseTime: String
            let type: String?
            enum CodingKeys: String, CodingKey {
                case name
                case releaseTime = "releaseTime"
                case type
            }
        }
        let releases: [Release]?
    }

    public func poll(externalRef: String, credential: Data, etag: String?) async -> PollOutcome {
        guard let account = try? serviceAccount(from: credential) else {
            return .terminalFailure(reason: "invalid service-account credential")
        }
        let token: String
        do {
            token = try await accessToken(for: account)
        } catch {
            providersLog.error("Firebase token exchange failed for \(externalRef, privacy: .public)")
            return .terminalFailure(reason: "credential expired or token exchange failed")
        }

        guard let url = URL(string: "https://firebasehosting.googleapis.com/v1beta1/sites/\(externalRef)/releases?pageSize=1") else {
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
            providersLog.error("Firebase Hosting poll terminal failure for \(externalRef, privacy: .public): \(reason, privacy: .public)")
            return .terminalFailure(reason: reason)
        case .transient(let reason, let retryAfter):
            providersLog.info("Firebase Hosting poll transient failure for \(externalRef, privacy: .public): \(reason, privacy: .public)")
            return .transientFailure(reason: reason, retryAfter: retryAfter)
        case .success(let data, let newETag):
            guard let decoded = try? JSONDecoder().decode(ReleasesResponse.self, from: data),
                  let release = decoded.releases?.first else {
                let payload = IntegrationPayload(headline: "No releases yet", detail: externalRef)
                return .success(payload: payload, etag: newETag)
            }
            let payload = IntegrationPayload(
                headline: "Deploy live",
                detail: release.releaseTime
            )
            return .success(payload: payload, etag: newETag)
        }
    }
}
