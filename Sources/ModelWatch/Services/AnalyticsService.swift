protocol AnalyticsService {
    func usageSummary(for range: AnalyticsRange) async throws -> UsageSummary
}

struct NoOpAnalyticsService: AnalyticsService {
    func usageSummary(for range: AnalyticsRange) async throws -> UsageSummary {
        .empty(range: range)
    }
}
