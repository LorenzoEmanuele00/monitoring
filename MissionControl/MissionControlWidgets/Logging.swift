import Foundation
import os
import MCDomain

/// `os.Logger` is the ONLY observability path inside the extension (ADR-0010) — PostHog is
/// never linked here. Same subsystem as the app, its own category.
enum WidgetLog {
    static let timeline = Logger(subsystem: AppGroupConfig.loggingSubsystem, category: "widget-timeline")
}
