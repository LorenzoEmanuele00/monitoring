import SwiftUI

/// Name, subtitle, health pill, updated-time, and a row of per-integration status dots — the
/// unit of a project list, matching the `Project` x `Service Integration` shape from
/// `project-registry`/`service-integrations` (`references/mc-design-system-v1-draft.md` §08).
/// Deliberately dependency-free like every other component here: call sites map their own
/// `Project`/`ServiceIntegration` aggregates into this shape (see the dependency note in
/// `DesignTokens.swift`).
public struct MCProjectCard: View {
    /// One integration's status dot + name, as shown in the card's integration row.
    public struct Integration: Sendable, Equatable {
        public let name: String
        public let tone: MCStatusTone

        public init(name: String, tone: MCStatusTone) {
            self.name = name
            self.tone = tone
        }
    }

    private let name: String
    private let subtitle: String
    private let healthLabel: String
    private let healthTone: MCStatusTone
    private let updatedAt: Date
    private let integrations: [Integration]
    private let now: Date

    public init(
        name: String,
        subtitle: String,
        healthLabel: String,
        healthTone: MCStatusTone,
        updatedAt: Date,
        integrations: [Integration],
        now: Date = Date()
    ) {
        self.name = name
        self.subtitle = subtitle
        self.healthLabel = healthLabel
        self.healthTone = healthTone
        self.updatedAt = updatedAt
        self.integrations = integrations
        self.now = now
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: MCSpacing.s4) {
            HStack(alignment: .top, spacing: MCSpacing.s3) {
                VStack(alignment: .leading, spacing: MCSpacing.s1) {
                    Text(name)
                        .font(MCFont.headline)
                        .foregroundStyle(MCColor.label)
                    Text(subtitle)
                        .font(MCFont.subheadline)
                        .foregroundStyle(MCColor.secondaryLabel)
                }
                Spacer(minLength: MCSpacing.s2)
                MCStatusPill(healthLabel, tone: healthTone)
            }
            HStack(spacing: MCSpacing.s3) {
                ForEach(integrations, id: \.name) { integration in
                    HStack(spacing: MCSpacing.s2) {
                        Circle()
                            .fill(integration.tone.color)
                            .frame(width: 5, height: 5)
                        Text(integration.name)
                            .font(MCFont.caption)
                            .foregroundStyle(MCColor.secondaryLabel)
                    }
                    .padding(.horizontal, MCSpacing.s3)
                    .padding(.vertical, MCSpacing.s2)
                    .background(MCColor.separator.opacity(0.3), in: Capsule())
                }
                Spacer(minLength: MCSpacing.s2)
                Text(updatedAt, style: .relative)
                    .font(MCFont.monoData)
                    .foregroundStyle(MCColor.tertiaryLabel)
            }
        }
        .padding(MCSpacing.s4)
        .background(MCColor.raisedBackground, in: RoundedRectangle(cornerRadius: MCRadius.card))
    }
}

#Preview("Project card — light") {
    MCProjectCardPreviewStack()
        .preferredColorScheme(.light)
}

#Preview("Project card — dark") {
    MCProjectCardPreviewStack()
        .preferredColorScheme(.dark)
}

private struct MCProjectCardPreviewStack: View {
    private let now = Date()

    var body: some View {
        VStack(spacing: MCSpacing.s4) {
            MCProjectCard(
                name: "mise_pwa",
                subtitle: "Gestione Mezzi",
                healthLabel: "Tutto ok",
                healthTone: .positive,
                updatedAt: now.addingTimeInterval(-2 * 60),
                integrations: [
                    .init(name: "GitHub", tone: .positive),
                    .init(name: "Firebase Hosting", tone: .positive),
                    .init(name: "Supabase", tone: .positive),
                ],
                now: now
            )
            MCProjectCard(
                name: "obsidian_sync",
                subtitle: "Vault personale",
                healthLabel: "1 degradato",
                healthTone: .warning,
                updatedAt: now.addingTimeInterval(-28 * 60),
                integrations: [
                    .init(name: "GitHub", tone: .positive),
                    .init(name: "Vercel", tone: .warning),
                ],
                now: now
            )
            MCProjectCard(
                name: "listino_api",
                subtitle: "Servizio interno",
                healthLabel: "1 errore",
                healthTone: .negative,
                updatedAt: now.addingTimeInterval(-3 * 3600),
                integrations: [
                    .init(name: "GitHub", tone: .positive),
                    .init(name: "Supabase", tone: .negative),
                    .init(name: "Vercel", tone: .neutral),
                ],
                now: now
            )
        }
        .padding()
        .frame(width: 340)
        .background(MCColor.windowBackground)
    }
}
