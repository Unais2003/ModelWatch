import Foundation
import XCTest
@testable import ModelWatch

@MainActor
final class DashboardSubscriptionManagementTests: XCTestCase {
    func testTotalsRemainSeparatedByCurrencyAndExcludeInactiveSubscriptions() async {
        let service = MutableSubscriptionServiceStub(subscriptions: [
            Subscription(serviceName: "USD Active", monthlyCost: 20, currencyCode: "USD"),
            Subscription(serviceName: "EUR Active", monthlyCost: 15, currencyCode: "EUR"),
            Subscription(serviceName: "USD Inactive", monthlyCost: 100, currencyCode: "USD", isActive: false),
        ])
        let viewModel = makeViewModel(subscriptionService: service)

        await viewModel.reloadSubscriptions()

        XCTAssertEqual(
            viewModel.subscriptionTotals,
            [
                SubscriptionTotal(currencyCode: "EUR", monthlyCost: 15),
                SubscriptionTotal(currencyCode: "USD", monthlyCost: 20),
            ]
        )
        XCTAssertEqual(viewModel.activeSubscriptionCount, 2)
        XCTAssertEqual(viewModel.subscriptionsState, .loaded)
    }

    func testCrudOperationsUpdateVisibleSubscriptionState() async {
        let service = MutableSubscriptionServiceStub()
        let viewModel = makeViewModel(subscriptionService: service)
        await viewModel.reloadSubscriptions()

        let added = await viewModel.addSubscription(input(
            serviceName: "ChatGPT",
            monthlyCost: 20,
            currencyCode: "USD"
        ))

        XCTAssertTrue(added)
        XCTAssertEqual(viewModel.subscriptions.map(\.serviceName), ["ChatGPT"])
        XCTAssertEqual(viewModel.subscriptionsState, .loaded)

        let subscription = try! XCTUnwrap(viewModel.subscriptions.first)
        let updated = await viewModel.updateSubscription(subscription, with: input(
            serviceName: "ChatGPT Plus",
            monthlyCost: 25,
            currencyCode: "EUR"
        ))

        XCTAssertTrue(updated)
        XCTAssertEqual(subscription.serviceName, "ChatGPT Plus")
        XCTAssertEqual(
            viewModel.subscriptionTotals,
            [SubscriptionTotal(currencyCode: "EUR", monthlyCost: 25)]
        )

        let deactivated = await viewModel.setSubscriptionActive(false, subscription: subscription)
        XCTAssertTrue(deactivated)
        XCTAssertEqual(viewModel.activeSubscriptionCount, 0)
        XCTAssertTrue(viewModel.subscriptionTotals.isEmpty)
        XCTAssertEqual(viewModel.subscriptionsState, .loaded)

        let deleted = await viewModel.deleteSubscription(subscription)
        XCTAssertTrue(deleted)
        XCTAssertTrue(viewModel.subscriptions.isEmpty)
        XCTAssertEqual(viewModel.subscriptionsState, .empty)
    }

    func testDeleteFailureKeepsVisibleSubscriptionAndReportsError() async {
        let subscription = Subscription(
            serviceName: "ChatGPT",
            monthlyCost: 20,
            currencyCode: "USD"
        )
        let service = MutableSubscriptionServiceStub(subscriptions: [subscription])
        let viewModel = makeViewModel(subscriptionService: service)
        await viewModel.reloadSubscriptions()
        service.shouldFailDeletion = true

        let deleted = await viewModel.deleteSubscription(subscription)

        XCTAssertFalse(deleted)
        XCTAssertEqual(viewModel.subscriptions.map(\.id), [subscription.id])
        XCTAssertNotNil(viewModel.subscriptionMutationError)
        XCTAssertEqual(viewModel.subscriptionsState, .loaded)
    }

    private func makeViewModel(
        subscriptionService: any SubscriptionService
    ) -> DashboardViewModel {
        DashboardViewModel(
            analyticsService: NoOpAnalyticsService(),
            subscriptionService: subscriptionService
        )
    }

    private func input(
        serviceName: String,
        monthlyCost: Double,
        currencyCode: String
    ) -> SubscriptionInput {
        SubscriptionInput(
            serviceName: serviceName,
            monthlyCost: monthlyCost,
            currencyCode: currencyCode,
            renewalDate: nil,
            isActive: true
        )
    }
}

@MainActor
private final class MutableSubscriptionServiceStub: SubscriptionService {
    private(set) var storedSubscriptions: [Subscription]
    var shouldFailDeletion = false

    init(subscriptions: [Subscription] = []) {
        storedSubscriptions = subscriptions
    }

    func subscriptions() async throws -> [Subscription] {
        storedSubscriptions
    }

    func create(_ input: SubscriptionInput) async throws -> Subscription {
        let subscription = Subscription(
            serviceName: input.serviceName,
            monthlyCost: input.monthlyCost,
            currencyCode: input.currencyCode,
            renewalDate: input.renewalDate,
            isActive: input.isActive
        )
        storedSubscriptions.append(subscription)
        return subscription
    }

    func update(_ subscription: Subscription, with input: SubscriptionInput) async throws {
        subscription.serviceName = input.serviceName
        subscription.monthlyCost = input.monthlyCost
        subscription.currencyCode = input.currencyCode
        subscription.renewalDate = input.renewalDate
        subscription.isActive = input.isActive
    }

    func setActive(_ isActive: Bool, for subscription: Subscription) async throws {
        subscription.isActive = isActive
    }

    func delete(_ subscription: Subscription) async throws {
        if shouldFailDeletion {
            throw DashboardSubscriptionTestError.expected
        }
        storedSubscriptions.removeAll { $0.id == subscription.id }
    }
}

private enum DashboardSubscriptionTestError: Error {
    case expected
}
