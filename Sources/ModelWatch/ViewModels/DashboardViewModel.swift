import Observation

@Observable
final class DashboardViewModel {
    let analyticsService: any AnalyticsService
    let subscriptionService: any SubscriptionService
    var selectedRange: AnalyticsRange = .day

    init(
        analyticsService: any AnalyticsService,
        subscriptionService: any SubscriptionService
    ) {
        self.analyticsService = analyticsService
        self.subscriptionService = subscriptionService
    }
}
