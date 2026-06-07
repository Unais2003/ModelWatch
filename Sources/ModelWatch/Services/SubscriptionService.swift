protocol SubscriptionService {
    func activeSubscriptions() async throws -> [Subscription]
}

struct NoOpSubscriptionService: SubscriptionService {
    func activeSubscriptions() async throws -> [Subscription] {
        []
    }
}
