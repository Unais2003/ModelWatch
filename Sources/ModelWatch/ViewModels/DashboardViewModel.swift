import Foundation
import Observation

@Observable
@MainActor
final class DashboardViewModel {
    private let analyticsService: any AnalyticsService
    private let subscriptionService: any SubscriptionService

    var selectedRange: AnalyticsRange = .day {
        didSet { Task { await loadData() } }
    }

    private(set) var usageSummary: UsageSummary = .empty(range: .day)
    private(set) var usageByApp: [AppUsage] = []
    private(set) var subscriptions: [Subscription] = []
    private(set) var totalMonthlyCost: Double = 0
    private(set) var isLoading = false

    init(
        analyticsService: any AnalyticsService,
        subscriptionService: any SubscriptionService
    ) {
        self.analyticsService = analyticsService
        self.subscriptionService = subscriptionService
    }

    func loadData() async {
        isLoading = true
        defer { isLoading = false }

        let range = selectedRange

        do {
            async let summary = analyticsService.usageSummary(for: range)
            async let breakdown = analyticsService.usageByApplication(for: range)
            async let subs = subscriptionService.activeSubscriptions()

            let (resolvedSummary, resolvedBreakdown, resolvedSubs) = try await (summary, breakdown, subs)

            usageSummary = resolvedSummary
            usageByApp = resolvedBreakdown
            subscriptions = resolvedSubs
            totalMonthlyCost = resolvedSubs.reduce(0) { $0 + $1.monthlyCost }
        } catch {
            usageSummary = .empty(range: range)
            usageByApp = []
            subscriptions = []
            totalMonthlyCost = 0
        }
    }
}
