import Foundation

@MainActor
struct StoreBasedSubscriptionService: SubscriptionService {
    let subscriptionStore: any SubscriptionStore

    func activeSubscriptions() async throws -> [Subscription] {
        try await subscriptionStore.fetchActiveSubscriptions()
    }
}
