import SwiftData
import XCTest
@testable import ModelWatch

@MainActor
final class SwiftDataSubscriptionStoreTests: XCTestCase {
    func testStorePersistsFetchesUpdatesAndDeletesSubscriptions() async throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Subscription.self,
            configurations: configuration
        )
        let store = SwiftDataSubscriptionStore(context: ModelContext(container))
        let zeta = Subscription(
            serviceName: "Zeta",
            monthlyCost: 20,
            currencyCode: "USD"
        )
        let alpha = Subscription(
            serviceName: "Alpha",
            monthlyCost: 10,
            currencyCode: "EUR",
            isActive: false
        )

        try await store.save(zeta)
        try await store.save(alpha)

        var fetched = try await store.fetchSubscriptions()
        XCTAssertEqual(fetched.map(\.serviceName), ["Alpha", "Zeta"])

        zeta.monthlyCost = 25
        try await store.update(zeta)
        fetched = try await store.fetchSubscriptions()
        XCTAssertEqual(fetched.first { $0.id == zeta.id }?.monthlyCost, 25)

        try await store.delete(alpha)
        fetched = try await store.fetchSubscriptions()
        XCTAssertEqual(fetched.map(\.id), [zeta.id])

        try await store.deleteAllSubscriptions()
        let remainingSubscriptions = try await store.fetchSubscriptions()
        XCTAssertTrue(remainingSubscriptions.isEmpty)
    }
}
