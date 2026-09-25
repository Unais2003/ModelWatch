import Foundation

struct AppUsage: Identifiable, Equatable, Sendable {
    let applicationBundleIdentifier: String
    let applicationName: String
    let duration: TimeInterval
    var id: String { applicationBundleIdentifier }
}

struct AnalyticsSnapshot: Equatable, Sendable {
    let summary: UsageSummary
    let usageByApplication: [AppUsage]

    static func empty(range: AnalyticsRange) -> AnalyticsSnapshot {
        AnalyticsSnapshot(summary: .empty(range: range), usageByApplication: [])
    }
}

@MainActor
protocol AnalyticsService {
    func analytics(for range: AnalyticsRange) async throws -> AnalyticsSnapshot
}

struct NoOpAnalyticsService: AnalyticsService {
    func analytics(for range: AnalyticsRange) async throws -> AnalyticsSnapshot {
        .empty(range: range)
    }
}
