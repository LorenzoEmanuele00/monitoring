import Foundation
import GRDB
import MCDomain

// Tier A record conformances (ADR-0005). Declared here, not in MCDomain, because MCDomain has
// no GRDB dependency (it stays usable from the widget extension's transitive graph even
// though nothing there currently imports it). Every MCDomain type below is already Codable,
// so GRDB's Codable-based record support does the column mapping; only the simple RawRepresentable
// enums need an explicit DatabaseValueConvertible conformance to store as TEXT instead of a
// JSON blob.

extension ProviderKind: DatabaseValueConvertible {}
extension CredentialKind: DatabaseValueConvertible {}
extension IntegrationStatus: DatabaseValueConvertible {}

extension Project: FetchableRecord, PersistableRecord {
    public static let databaseTableName = "project"
}

extension ServiceIntegration: FetchableRecord, PersistableRecord {
    public static let databaseTableName = "serviceIntegration"
}
