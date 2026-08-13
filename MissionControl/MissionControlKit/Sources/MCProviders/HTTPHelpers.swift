import Foundation
import os

let providersLog = Logger(subsystem: "com.lorenzoemanuele.missioncontrol", category: "providers")

/// Shared HTTP-status → `PollOutcome` classification (ADR-0008):
/// - 304 -> not modified (still fresh)
/// - 401/403/404 -> terminal (credential expired / resource gone)
/// - everything else non-2xx (network errors, 5xx, 429) -> transient, honouring `Retry-After`
///   as a hard floor.
enum HTTPOutcome {
    case success(Data, newETag: String?)
    case notModified
    case transient(reason: String, retryAfter: TimeInterval?)
    case terminal(reason: String)

    static func classify(response: URLResponse?, data: Data?, error: Error?) -> HTTPOutcome {
        if let error {
            return .transient(reason: "network error: \(error.localizedDescription)", retryAfter: nil)
        }
        guard let http = response as? HTTPURLResponse else {
            return .transient(reason: "no HTTP response", retryAfter: nil)
        }
        let retryAfter = http.value(forHTTPHeaderField: "Retry-After").flatMap(TimeInterval.init)
        switch http.statusCode {
        case 200...299:
            let etag = http.value(forHTTPHeaderField: "ETag")
            return .success(data ?? Data(), newETag: etag)
        case 304:
            return .notModified
        case 401, 403, 404:
            return .terminal(reason: "HTTP \(http.statusCode)")
        case 429:
            return .transient(reason: "rate limited (429)", retryAfter: retryAfter ?? 30)
        case 500...599:
            return .transient(reason: "server error (\(http.statusCode))", retryAfter: retryAfter)
        default:
            return .transient(reason: "unexpected HTTP \(http.statusCode)", retryAfter: retryAfter)
        }
    }
}
