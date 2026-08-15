// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "MissionControlKit",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "MCDomain", targets: ["MCDomain"]),
        .library(name: "MCDesignTokens", targets: ["MCDesignTokens"]),
        .library(name: "MCSnapshot", targets: ["MCSnapshot"]),
        .library(name: "MCSecrets", targets: ["MCSecrets"]),
        .library(name: "MCPersistence", targets: ["MCPersistence"]),
        .library(name: "MCProviders", targets: ["MCProviders"]),
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "7.0.0"),
    ],
    targets: [
        // MCDomain: pure domain model, no external dependencies (ADR-0004/0005/0007/0008/0012).
        .target(name: "MCDomain"),

        // MCDesignTokens: shared colors/typography for app + widget extension. No dependencies.
        .target(name: "MCDesignTokens"),

        // MCSnapshot: Tier B (ADR-0005) — render-ready JSON DTOs + App Group file I/O.
        // This is the ONLY MissionControlKit product the widget extension links.
        .target(name: "MCSnapshot", dependencies: ["MCDomain"]),

        // MCSecrets: SecretStore protocol + Keychain-backed implementation (ADR-0007).
        .target(name: "MCSecrets", dependencies: ["MCDomain"]),

        // MCPersistence: Tier A (ADR-0005) — GRDB/SQLite repositories. Main-app only;
        // never linked by the widget extension target.
        .target(
            name: "MCPersistence",
            dependencies: [
                "MCDomain",
                .product(name: "GRDB", package: "GRDB.swift"),
            ]
        ),

        // MCProviders: provider adapters (GitHub, Firebase Hosting, Supabase) + retry/backoff
        // policy (ADR-0008) + credential model (ADR-0012).
        .target(name: "MCProviders", dependencies: ["MCDomain", "MCSecrets"]),

        .testTarget(name: "MCDomainTests", dependencies: ["MCDomain"]),
        .testTarget(name: "MCDesignTokensTests", dependencies: ["MCDesignTokens"]),
        .testTarget(name: "MCSnapshotTests", dependencies: ["MCSnapshot"]),
        .testTarget(name: "MCSecretsTests", dependencies: ["MCSecrets"]),
        .testTarget(
            name: "MCPersistenceTests",
            dependencies: ["MCPersistence"]
        ),
        .testTarget(name: "MCProvidersTests", dependencies: ["MCProviders"]),
    ]
)
