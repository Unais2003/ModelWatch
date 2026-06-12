import Foundation

struct AppUsage: Identifiable, Equatable {
    let applicationName: String
    let duration: TimeInterval
    var id: String { applicationName }
}

protocol AnalyticsService {
    func usageSummary(for range: AnalyticsRange) async throws -> UsageSummary
    func usageByApplication(for range: AnalyticsRange) async throws -> [AppUsage]
}

struct NoOpAnalyticsService: AnalyticsService {
    func usageSummary(for range: AnalyticsRange) async throws -> UsageSummary {
        .empty(range: range)
    }

    func usageByApplication(for range: AnalyticsRange) async throws -> [AppUsage] {
        []
    }
}
