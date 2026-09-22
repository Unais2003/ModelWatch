import Foundation
import Observation

@Observable
@MainActor
final class DashboardViewModel {
    private enum LoadErrorMessage {
        static let analytics = "Unable to load usage data. Please try again."
        static let subscriptions = "Unable to load subscriptions. Please try again."
    }

    private let analyticsService: any AnalyticsService
    private let subscriptionService: any SubscriptionService

    var selectedRange: AnalyticsRange = .day {
        didSet { scheduleAnalyticsLoad() }
    }

    private(set) var usageSummary: UsageSummary = .empty(range: .day)
    private(set) var usageByApp: [AppUsage] = []
    private(set) var subscriptions: [Subscription] = []
    private(set) var totalMonthlyCost: Double = 0
    private(set) var analyticsState: DashboardLoadState = .idle
    private(set) var subscriptionsState: DashboardLoadState = .idle

    @ObservationIgnored
    private var analyticsLoadTask: Task<Void, Never>?

    @ObservationIgnored
    private var analyticsRequestID = 0

    @ObservationIgnored
    private var subscriptionRequestID = 0

    init(
        analyticsService: any AnalyticsService,
        subscriptionService: any SubscriptionService
    ) {
        self.analyticsService = analyticsService
        self.subscriptionService = subscriptionService
    }

    func loadData() async {
        let range = selectedRange

        async let analyticsLoad: Void = loadAnalytics(for: range)
        async let subscriptionsLoad: Void = loadSubscriptions()
        _ = await (analyticsLoad, subscriptionsLoad)
    }

    func reloadAnalytics() async {
        await loadAnalytics(for: selectedRange)
    }

    func reloadSubscriptions() async {
        await loadSubscriptions()
    }

    private func scheduleAnalyticsLoad() {
        analyticsLoadTask?.cancel()
        let range = selectedRange
        analyticsLoadTask = Task { [weak self] in
            await self?.loadAnalytics(for: range)
        }
    }

    private func loadAnalytics(for range: AnalyticsRange) async {
        analyticsRequestID += 1
        let requestID = analyticsRequestID
        analyticsState = .loading

        do {
            async let summary = analyticsService.usageSummary(for: range)
            async let breakdown = analyticsService.usageByApplication(for: range)
            let (resolvedSummary, resolvedBreakdown) = try await (summary, breakdown)

            guard shouldApplyAnalyticsResponse(requestID: requestID, range: range) else {
                return
            }

            usageSummary = resolvedSummary
            usageByApp = resolvedBreakdown
            analyticsState = resolvedBreakdown.isEmpty ? .empty : .loaded
        } catch is CancellationError {
            return
        } catch {
            guard shouldApplyAnalyticsResponse(requestID: requestID, range: range) else {
                return
            }

            usageSummary = .empty(range: range)
            usageByApp = []
            analyticsState = .failed(message: LoadErrorMessage.analytics)
        }
    }

    private func loadSubscriptions() async {
        subscriptionRequestID += 1
        let requestID = subscriptionRequestID
        subscriptionsState = .loading

        do {
            let resolvedSubscriptions = try await subscriptionService.activeSubscriptions()

            guard requestID == subscriptionRequestID, !Task.isCancelled else {
                return
            }

            subscriptions = resolvedSubscriptions
            totalMonthlyCost = resolvedSubscriptions.reduce(0) { $0 + $1.monthlyCost }
            subscriptionsState = resolvedSubscriptions.isEmpty ? .empty : .loaded
        } catch is CancellationError {
            return
        } catch {
            guard requestID == subscriptionRequestID, !Task.isCancelled else {
                return
            }

            subscriptions = []
            totalMonthlyCost = 0
            subscriptionsState = .failed(message: LoadErrorMessage.subscriptions)
        }
    }

    private func shouldApplyAnalyticsResponse(requestID: Int, range: AnalyticsRange) -> Bool {
        requestID == analyticsRequestID && range == selectedRange && !Task.isCancelled
    }
}
