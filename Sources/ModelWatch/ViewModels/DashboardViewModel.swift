import Foundation
import Observation

@Observable
@MainActor
final class DashboardViewModel {
    private enum LoadErrorMessage {
        static let analytics = "Unable to load usage data. Please try again."
        static let subscriptions = "Unable to load subscriptions. Please try again."
        static let subscriptionMutation = "Unable to save the subscription. Please try again."
        static let subscriptionDeletion = "Unable to delete the subscription. Please try again."
    }

    private let analyticsService: any AnalyticsService
    private let subscriptionService: any SubscriptionService
    private let activityTrackingService: any ActivityTrackingService

    var selectedRange: AnalyticsRange = .day {
        didSet { scheduleAnalyticsLoad() }
    }

    private(set) var usageSummary: UsageSummary = .empty(range: .day)
    private(set) var usageByApp: [AppUsage] = []
    private(set) var subscriptions: [Subscription] = []
    private(set) var subscriptionTotals: [SubscriptionTotal] = []
    private(set) var analyticsState: DashboardLoadState = .idle
    private(set) var subscriptionsState: DashboardLoadState = .idle
    private(set) var isMutatingSubscription = false
    private(set) var subscriptionMutationError: String?

    var activeSubscriptionCount: Int {
        subscriptions.lazy.filter(\.isActive).count
    }

    var analyticsRevision: Int {
        activityTrackingService.analyticsRevision
    }

    @ObservationIgnored
    private var analyticsLoadTask: Task<Void, Never>?

    @ObservationIgnored
    private var analyticsRequestID = 0

    @ObservationIgnored
    private var subscriptionRequestID = 0

    init(
        analyticsService: any AnalyticsService,
        subscriptionService: any SubscriptionService,
        activityTrackingService: any ActivityTrackingService
    ) {
        self.analyticsService = analyticsService
        self.subscriptionService = subscriptionService
        self.activityTrackingService = activityTrackingService
    }

    convenience init(
        analyticsService: any AnalyticsService,
        subscriptionService: any SubscriptionService
    ) {
        self.init(
            analyticsService: analyticsService,
            subscriptionService: subscriptionService,
            activityTrackingService: NoOpActivityTrackingService()
        )
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

    func addSubscription(_ input: SubscriptionInput) async -> Bool {
        await performSubscriptionMutation {
            let subscription = try await subscriptionService.create(input)
            subscriptions.append(subscription)
            applySubscriptions(subscriptions)
        }
    }

    func updateSubscription(_ subscription: Subscription, with input: SubscriptionInput) async -> Bool {
        await performSubscriptionMutation {
            try await subscriptionService.update(subscription, with: input)
            applySubscriptions(subscriptions)
        }
    }

    func setSubscriptionActive(_ isActive: Bool, subscription: Subscription) async -> Bool {
        await performSubscriptionMutation {
            try await subscriptionService.setActive(isActive, for: subscription)
            applySubscriptions(subscriptions)
        }
    }

    func deleteSubscription(_ subscription: Subscription) async -> Bool {
        await performSubscriptionMutation(fallbackMessage: LoadErrorMessage.subscriptionDeletion) {
            try await subscriptionService.delete(subscription)
            subscriptions.removeAll { $0.id == subscription.id }
            applySubscriptions(subscriptions)
        }
    }

    func clearSubscriptionMutationError() {
        subscriptionMutationError = nil
    }

    func refreshActiveSessionPeriodically() async {
        while !Task.isCancelled {
            do {
                try await Task.sleep(for: .seconds(60))
            } catch {
                return
            }

            guard activityTrackingService.state.activeApplicationName != nil else { continue }
            await reloadAnalytics()
        }
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
            let snapshot = try await analyticsService.analytics(for: range)

            guard shouldApplyAnalyticsResponse(requestID: requestID, range: range) else {
                return
            }

            usageSummary = snapshot.summary
            usageByApp = snapshot.usageByApplication
            analyticsState = snapshot.usageByApplication.isEmpty ? .empty : .loaded
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
            let resolvedSubscriptions = try await subscriptionService.subscriptions()

            guard requestID == subscriptionRequestID, !Task.isCancelled else {
                return
            }

            applySubscriptions(resolvedSubscriptions)
        } catch is CancellationError {
            return
        } catch {
            guard requestID == subscriptionRequestID, !Task.isCancelled else {
                return
            }

            subscriptions = []
            subscriptionTotals = []
            subscriptionsState = .failed(message: LoadErrorMessage.subscriptions)
        }
    }

    private func performSubscriptionMutation(
        fallbackMessage: String = LoadErrorMessage.subscriptionMutation,
        operation: () async throws -> Void
    ) async -> Bool {
        guard !isMutatingSubscription else { return false }

        isMutatingSubscription = true
        subscriptionMutationError = nil
        defer { isMutatingSubscription = false }

        do {
            try await operation()
            return true
        } catch let error as LocalizedError {
            subscriptionMutationError = error.errorDescription ?? fallbackMessage
            return false
        } catch {
            subscriptionMutationError = fallbackMessage
            return false
        }
    }

    private func applySubscriptions(_ resolvedSubscriptions: [Subscription]) {
        subscriptions = resolvedSubscriptions.sorted {
            if $0.isActive != $1.isActive {
                return $0.isActive
            }
            return $0.serviceName.localizedStandardCompare($1.serviceName) == .orderedAscending
        }

        let totalsByCurrency = subscriptions
            .filter(\.isActive)
            .reduce(into: [String: Double]()) { totals, subscription in
                totals[subscription.currencyCode, default: 0] += subscription.monthlyCost
            }

        subscriptionTotals = totalsByCurrency
            .map { SubscriptionTotal(currencyCode: $0.key, monthlyCost: $0.value) }
            .sorted { $0.currencyCode < $1.currencyCode }
        subscriptionsState = subscriptions.isEmpty ? .empty : .loaded
    }

    private func shouldApplyAnalyticsResponse(requestID: Int, range: AnalyticsRange) -> Bool {
        requestID == analyticsRequestID && range == selectedRange && !Task.isCancelled
    }
}
