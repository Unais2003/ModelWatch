import Foundation
import XCTest
@testable import ModelWatch

@MainActor
final class DashboardViewModelTests: XCTestCase {
    func testEmptyServicesProduceExplicitEmptyStates() async {
        let viewModel = DashboardViewModel(
            analyticsService: NoOpAnalyticsService(),
            subscriptionService: NoOpSubscriptionService()
        )

        await viewModel.loadData()

        XCTAssertEqual(viewModel.analyticsState, .empty)
        XCTAssertEqual(viewModel.subscriptionsState, .empty)
    }

    func testAnalyticsFailureDoesNotHideLoadedSubscriptions() async {
        let subscription = Subscription(
            serviceName: "Example Plan",
            monthlyCost: 20,
            currencyCode: "USD"
        )
        let viewModel = DashboardViewModel(
            analyticsService: FailingAnalyticsService(),
            subscriptionService: SubscriptionServiceStub(subscriptions: [subscription])
        )

        await viewModel.loadData()

        guard case let .failed(message) = viewModel.analyticsState else {
            return XCTFail("Expected analytics to expose a failed state")
        }

        XCTAssertFalse(message.isEmpty)
        XCTAssertEqual(viewModel.subscriptionsState, .loaded)
        XCTAssertEqual(viewModel.subscriptions.map(\.serviceName), ["Example Plan"])
        XCTAssertEqual(viewModel.totalMonthlyCost, 20, accuracy: 0.001)
    }

    func testLatestRangeWinsWhenEarlierRequestFinishesLast() async {
        let viewModel = DashboardViewModel(
            analyticsService: DelayedAnalyticsService(),
            subscriptionService: NoOpSubscriptionService()
        )

        let initialLoad = Task { await viewModel.loadData() }
        try? await Task<Never, Never>.sleep(for: .milliseconds(20))

        viewModel.selectedRange = .week

        try? await Task<Never, Never>.sleep(for: .milliseconds(300))
        await initialLoad.value

        XCTAssertEqual(viewModel.analyticsState, .loaded)
        XCTAssertEqual(viewModel.usageSummary.range, .week)
        XCTAssertEqual(viewModel.usageSummary.totalDuration, 120, accuracy: 0.001)
        XCTAssertEqual(
            viewModel.usageByApp,
            [
                AppUsage(
                    applicationBundleIdentifier: "test.week",
                    applicationName: "Week",
                    duration: 120
                )
            ]
        )
    }
}

private enum DashboardTestError: Error {
    case expected
}

@MainActor
private struct FailingAnalyticsService: AnalyticsService {
    func analytics(for range: AnalyticsRange) async throws -> AnalyticsSnapshot {
        throw DashboardTestError.expected
    }
}

@MainActor
private struct SubscriptionServiceStub: SubscriptionService {
    let subscriptions: [Subscription]

    func activeSubscriptions() async throws -> [Subscription] {
        subscriptions
    }
}

@MainActor
private struct DelayedAnalyticsService: AnalyticsService {
    func analytics(for range: AnalyticsRange) async throws -> AnalyticsSnapshot {
        try await wait(for: range)
        let name = range == .day ? "Day" : "Week"
        let duration: TimeInterval = range == .day ? 60 : 120
        return AnalyticsSnapshot(
            summary: UsageSummary(
                range: range,
                totalDuration: duration,
                trackedApplicationCount: 1
            ),
            usageByApplication: [
                AppUsage(
                    applicationBundleIdentifier: "test.\(name.lowercased())",
                    applicationName: name,
                    duration: duration
                )
            ]
        )
    }

    private func wait(for range: AnalyticsRange) async throws {
        let delay: Duration = range == .day ? .milliseconds(200) : .milliseconds(10)
        try await Task<Never, Never>.sleep(for: delay)
    }
}
