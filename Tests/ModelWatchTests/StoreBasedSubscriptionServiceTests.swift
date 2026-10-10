import Foundation
import XCTest
@testable import ModelWatch

@MainActor
final class StoreBasedSubscriptionServiceTests: XCTestCase {
    func testCreateTrimsNameAndNormalizesCurrencyCode() async throws {
        let store = SubscriptionStoreSpy()
        let service = StoreBasedSubscriptionService(subscriptionStore: store)

        let created = try await service.create(SubscriptionInput(
            serviceName: "  ChatGPT Plus  ",
            monthlyCost: 20,
            currencyCode: " usd ",
            renewalDate: Date(timeIntervalSince1970: 1_000),
            isActive: true
        ))

        XCTAssertEqual(created.serviceName, "ChatGPT Plus")
        XCTAssertEqual(created.monthlyCost, 20)
        XCTAssertEqual(created.currencyCode, "USD")
        XCTAssertEqual(store.storedSubscriptions.map(\.id), [created.id])
    }

    func testCreateRejectsInvalidFieldsBeforeWriting() async {
        let store = SubscriptionStoreSpy()
        let service = StoreBasedSubscriptionService(subscriptionStore: store)

        await assertCreateFails(
            service: service,
            input: input(serviceName: "   "),
            expectedError: .emptyServiceName
        )
        await assertCreateFails(
            service: service,
            input: input(monthlyCost: -0.01),
            expectedError: .invalidMonthlyCost
        )
        await assertCreateFails(
            service: service,
            input: input(monthlyCost: .infinity),
            expectedError: .invalidMonthlyCost
        )
        await assertCreateFails(
            service: service,
            input: input(currencyCode: "ZZZ"),
            expectedError: .unsupportedCurrencyCode
        )

        XCTAssertTrue(store.storedSubscriptions.isEmpty)
    }

    func testFetchSortsActiveSubscriptionsBeforeInactiveSubscriptions() async throws {
        let inactive = Subscription(
            serviceName: "Alpha",
            monthlyCost: 10,
            currencyCode: "EUR",
            isActive: false
        )
        let activeZeta = Subscription(
            serviceName: "Zeta",
            monthlyCost: 20,
            currencyCode: "EUR"
        )
        let activeAlpha = Subscription(
            serviceName: "Alpha",
            monthlyCost: 15,
            currencyCode: "EUR"
        )
        let store = SubscriptionStoreSpy(
            storedSubscriptions: [inactive, activeZeta, activeAlpha]
        )
        let service = StoreBasedSubscriptionService(subscriptionStore: store)

        let subscriptions = try await service.subscriptions()

        XCTAssertEqual(subscriptions.map(\.id), [activeAlpha.id, activeZeta.id, inactive.id])
    }

    func testFailedUpdateRestoresPersistedValues() async {
        let subscription = Subscription(
            serviceName: "Original",
            monthlyCost: 10,
            currencyCode: "EUR"
        )
        let store = SubscriptionStoreSpy(storedSubscriptions: [subscription])
        store.failure = .update
        let service = StoreBasedSubscriptionService(subscriptionStore: store)

        do {
            try await service.update(subscription, with: input(
                serviceName: "Changed",
                monthlyCost: 50,
                currencyCode: "USD"
            ))
            XCTFail("Expected the update to fail")
        } catch {
            XCTAssertEqual(subscription.serviceName, "Original")
            XCTAssertEqual(subscription.monthlyCost, 10)
            XCTAssertEqual(subscription.currencyCode, "EUR")
            XCTAssertTrue(subscription.isActive)
        }
    }

    func testFailedStatusChangeRestoresActiveValue() async {
        let subscription = Subscription(
            serviceName: "ChatGPT",
            monthlyCost: 20,
            currencyCode: "USD"
        )
        let store = SubscriptionStoreSpy(storedSubscriptions: [subscription])
        store.failure = .update
        let service = StoreBasedSubscriptionService(subscriptionStore: store)

        do {
            try await service.setActive(false, for: subscription)
            XCTFail("Expected the update to fail")
        } catch {
            XCTAssertTrue(subscription.isActive)
        }
    }

    private func assertCreateFails(
        service: StoreBasedSubscriptionService,
        input: SubscriptionInput,
        expectedError: SubscriptionValidationError
    ) async {
        do {
            _ = try await service.create(input)
            XCTFail("Expected validation to fail")
        } catch let error as SubscriptionValidationError {
            XCTAssertEqual(error, expectedError)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    private func input(
        serviceName: String = "ChatGPT",
        monthlyCost: Double = 20,
        currencyCode: String = "USD"
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
private final class SubscriptionStoreSpy: SubscriptionStore {
    enum Operation {
        case fetch
        case save
        case update
        case delete
        case deleteAll
    }

    var storedSubscriptions: [Subscription]
    var failure: Operation?

    init(storedSubscriptions: [Subscription] = []) {
        self.storedSubscriptions = storedSubscriptions
    }

    func fetchSubscriptions() async throws -> [Subscription] {
        try failIfNeeded(.fetch)
        return storedSubscriptions
    }

    func save(_ subscription: Subscription) async throws {
        try failIfNeeded(.save)
        storedSubscriptions.append(subscription)
    }

    func update(_ subscription: Subscription) async throws {
        try failIfNeeded(.update)
    }

    func delete(_ subscription: Subscription) async throws {
        try failIfNeeded(.delete)
        storedSubscriptions.removeAll { $0.id == subscription.id }
    }

    func deleteAllSubscriptions() async throws {
        try failIfNeeded(.deleteAll)
        storedSubscriptions.removeAll()
    }

    private func failIfNeeded(_ operation: Operation) throws {
        if failure == operation {
            throw SubscriptionStoreTestError.expected
        }
    }
}

private enum SubscriptionStoreTestError: Error {
    case expected
}
